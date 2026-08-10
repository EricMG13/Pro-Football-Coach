#!/usr/bin/env bash
# Coordinate descent over the dominant calibration constants. Every candidate is measured by the
# checked-in scorer against tuning seeds only; holdout seeds remain untouched until handoff.
set -euo pipefail

die() {
  printf 'tune-calibration: %s\n' "$*" >&2
  exit 1
}

advisory_lock_fd=""
inner_lock_path=""

close_advisory_lock_for_child() {
  [[ -n "$advisory_lock_fd" ]] || return 0
  [[ "$advisory_lock_fd" =~ ^[0-9]+$ ]] \
    || die "invalid advisory-lock descriptor for child"
  # The descriptor is numeric and verified before use, so this evaluates exactly `exec N>&-`.
  eval "exec ${advisory_lock_fd}>&-"
}

verify_inherited_advisory_lock() {
  local descriptor=$1
  local lock_path=$2
  python3 - "$descriptor" "$lock_path" <<'PY'
import fcntl
import os
import stat
import sys

lock_fd = int(sys.argv[1])
lock_path = sys.argv[2]
parent_path, lock_name = os.path.split(lock_path)
directory_flags = os.O_RDONLY | os.O_DIRECTORY
if hasattr(os, "O_NOFOLLOW"):
    directory_flags |= os.O_NOFOLLOW

parent_fd = None
try:
    parent_path_stat = os.lstat(parent_path)
    parent_fd = os.open(parent_path, directory_flags)
    parent_fd_stat = os.fstat(parent_fd)
    if (not stat.S_ISDIR(parent_fd_stat.st_mode) or stat.S_ISLNK(parent_path_stat.st_mode)
            or (parent_fd_stat.st_dev, parent_fd_stat.st_ino)
            != (parent_path_stat.st_dev, parent_path_stat.st_ino)):
        raise OSError("lock parent is not the opened real directory")

    lock_fd_stat = os.fstat(lock_fd)
    lock_path_stat = os.stat(lock_name, dir_fd=parent_fd, follow_symlinks=False)
    if (not stat.S_ISREG(lock_fd_stat.st_mode) or stat.S_ISLNK(lock_path_stat.st_mode)
            or (lock_fd_stat.st_dev, lock_fd_stat.st_ino)
            != (lock_path_stat.st_dev, lock_path_stat.st_ino)):
        raise OSError("inherited descriptor does not match the anchored regular lock file")
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)

    parent_recheck = os.lstat(parent_path)
    if (parent_fd_stat.st_dev, parent_fd_stat.st_ino) \
            != (parent_recheck.st_dev, parent_recheck.st_ino):
        raise OSError("lock parent identity changed before search")
except (OSError, ValueError) as error:
    print(f"tune-calibration: inherited advisory lock is invalid: {error}", file=sys.stderr)
    raise SystemExit(1)
finally:
    if parent_fd is not None:
        os.close(parent_fd)
PY
}

# The re-executed Bash must contain the inherited descriptor before its first child. The verifier
# below is the sole intentional descendant that receives it; marker and descriptor are no longer
# exported by the time that verifier starts.
if [[ ${TUNE_CALIBRATION_INHERITED_LOCK:-} == 1 ]]; then
  [[ ${TUNE_CALIBRATION_LOCK_FD:-} =~ ^[0-9]+$ ]] \
    || die "invalid inherited advisory-lock descriptor"
  [[ $# -eq 2 && $1 == __tune_calibration_locked_inner ]] \
    || die "invalid advisory-lock re-entry arguments"
  advisory_lock_fd=$TUNE_CALIBRATION_LOCK_FD
  inner_lock_path=$2
  unset TUNE_CALIBRATION_INHERITED_LOCK TUNE_CALIBRATION_LOCK_FD
  verify_inherited_advisory_lock "$advisory_lock_fd" "$inner_lock_path"
  shift 2
fi

resolve_physical_directory() {
  local directory=$1
  local probe_descriptor=${2:-}
  close_advisory_lock_for_child
  if [[ -n "$probe_descriptor" ]]; then
    python3 - "$probe_descriptor" <<'PY'
import errno
import os
import sys

try:
    os.fstat(int(sys.argv[1]))
except OSError as error:
    if error.errno == errno.EBADF:
        print("re-entry validation descendant closed advisory lock descriptor (EBADF)",
              file=sys.stderr)
        raise SystemExit(0)
    raise
raise SystemExit("re-entry validation descendant inherited advisory lock descriptor")
PY
  fi
  cd -P -- "$directory" && pwd
}

script_source=${BASH_SOURCE[0]}
script_parent=${script_source%/*}
[[ "$script_parent" != "$script_source" ]] || script_parent=.
reentry_probe=""
if [[ -n "$advisory_lock_fd" && ${TUNE_CALIBRATION_TEST_REENTRY_FD:-} == 1 ]]; then
  reentry_probe=$advisory_lock_fd
fi
script_dir=$(resolve_physical_directory "$script_parent" "$reentry_probe") \
  || die "cannot resolve tuner script directory"
repo_root=$(resolve_physical_directory "$script_dir/..") \
  || die "cannot resolve script-derived repository"
expected_rules_dir=$(resolve_physical_directory "$repo_root/Sources/FootballSimCore/Rules") \
  || die "cannot resolve Rules directory under script-derived repository"
matchup_rules="$expected_rules_dir/MatchupRules.swift"
worktree_rules_dir=$expected_rules_dir
worktree_matchup_rules=$matchup_rules
lock_parent="$repo_root/.build"
lock_file="$lock_parent/tune-calibration.lock"

if [[ -n "$inner_lock_path" && "$inner_lock_path" != "$lock_file" ]]; then
  die "inherited advisory lock path does not match the script-derived repository"
fi

validate_matchup_rules() {
  [[ "$matchup_rules" == "$expected_rules_dir/MatchupRules.swift" ]] \
    || die "unexpected MatchupRules path"
  [[ "$expected_rules_dir" == "$repo_root/"* ]] \
    || die "Rules directory escapes script-derived repository"
  [[ -f "$matchup_rules" && ! -L "$matchup_rules" ]] \
    || die "expected a regular, non-symlink MatchupRules.swift"
  local resolved_rules_dir
  resolved_rules_dir=$(resolve_physical_directory "${matchup_rules%/*}") \
    || die "cannot resolve MatchupRules.swift parent"
  [[ "$resolved_rules_dir" == "$expected_rules_dir" ]] \
    || die "MatchupRules.swift is outside its expected repository path"
}

activate_contract_rules_override() {
  [[ ${TUNE_CALIBRATION_TEST_CONTRACT_MODE:-} == 1 ]] \
    || die "rules override requires explicit calibration contract mode"
  [[ ${TUNE_CALIBRATION_TEST_FAIL_FIRST_CANDIDATE:-} == 1 \
      && ${TUNE_CALIBRATION_TEST_ROLLBACK_HOLD:-} == 1 ]] \
    || die "contract rules override is limited to the held failing-candidate rollback fixture"
  [[ ${TUNE_CALIBRATION_TEST_SCORE_OUTPUT+x} != x ]] \
    || die "contract rules override cannot be combined with a score-output hook"
  [[ -n ${TUNE_CALIBRATION_TEST_CONTRACT_RULES_DIR:-} ]] \
    || die "contract rules override requires an isolated Rules directory"

  local temporary_base=${TMPDIR:-/tmp}
  temporary_base=${temporary_base%/}
  local resolved_temporary_base resolved_override_dir fixture_root fixture_name
  resolved_temporary_base=$(resolve_physical_directory "$temporary_base") \
    || die "cannot resolve temporary base for contract rules override"
  resolved_override_dir=$(resolve_physical_directory \
    "$TUNE_CALIBRATION_TEST_CONTRACT_RULES_DIR") \
    || die "cannot resolve contract rules override directory"
  fixture_root=${resolved_override_dir%/*}
  fixture_name=${fixture_root##*/}
  [[ "${resolved_override_dir##*/}" == rollback-rules \
      && "$fixture_name" == pfc-calibration-tools.* \
      && "${fixture_root%/*}" == "$resolved_temporary_base" \
      && "$resolved_override_dir" != "$worktree_rules_dir" ]] \
    || die "contract rules override must be the gate's isolated rollback-rules directory"

  local override_target="$resolved_override_dir/MatchupRules.swift"
  [[ -f "$override_target" && ! -L "$override_target" ]] \
    || die "contract rules override target must be a copied regular non-symlink MatchupRules.swift"
  (
    close_advisory_lock_for_child
    cmp -s "$worktree_matchup_rules" "$override_target"
  ) || die "contract rules override must begin byte-identical to tracked MatchupRules.swift"

  expected_rules_dir=$resolved_override_dir
  matchup_rules=$override_target
  printf 'tune-calibration: contract rules target %s\n' "$matchup_rules" >&2
}

validate_lock_parent() {
  [[ "$lock_parent" == "$repo_root/.build" && "$lock_file" == "$lock_parent/tune-calibration.lock" ]] \
    || die "unexpected calibration lock path"
  [[ "$lock_parent" == "$repo_root/"* && "$lock_parent" != "$repo_root" ]] \
    || die "calibration lock parent escapes script-derived repository"
  [[ -d "$lock_parent" && ! -L "$lock_parent" ]] \
    || die "calibration lock parent must be a real directory, not a symlink"
  local resolved_lock_parent
  resolved_lock_parent=$(resolve_physical_directory "$lock_parent") \
    || die "cannot resolve calibration lock parent"
  [[ "$resolved_lock_parent" == "$repo_root/.build" ]] \
    || die "calibration lock parent escapes script-derived repository"
  (
    close_advisory_lock_for_child
    git -C "$repo_root" check-ignore -q -- .build/tune-calibration.lock
  ) || die "calibration lock location must be an ignored build or scratch path"
}

prepare_lock_parent() {
  if [[ ! -e "$lock_parent" ]]; then
    mkdir "$lock_parent" || die "cannot create calibration lock parent"
  fi
  validate_lock_parent
}

launch_with_advisory_lock() {
  exec python3 - "$script_dir/tune-calibration.sh" "$lock_file" <<'PY'
import errno
import fcntl
import os
import stat
import sys

script, lock_path = sys.argv[1:]
parent_path, lock_name = os.path.split(lock_path)
directory_flags = os.O_RDONLY | os.O_DIRECTORY
if hasattr(os, "O_NOFOLLOW"):
    directory_flags |= os.O_NOFOLLOW
lock_flags = os.O_RDWR | os.O_CREAT
if hasattr(os, "O_NOFOLLOW"):
    lock_flags |= os.O_NOFOLLOW

parent_fd = None
try:
    parent_path_stat = os.lstat(parent_path)
    parent_fd = os.open(parent_path, directory_flags)
    parent_fd_stat = os.fstat(parent_fd)
    if (not stat.S_ISDIR(parent_fd_stat.st_mode) or stat.S_ISLNK(parent_path_stat.st_mode)
            or (parent_fd_stat.st_dev, parent_fd_stat.st_ino)
            != (parent_path_stat.st_dev, parent_path_stat.st_ino)):
        raise OSError(errno.EPERM, "lock parent is not the opened real directory")

    lock_fd = os.open(lock_name, lock_flags, 0o600, dir_fd=parent_fd)
    lock_fd_stat = os.fstat(lock_fd)
    lock_path_stat = os.stat(lock_name, dir_fd=parent_fd, follow_symlinks=False)
    if (not stat.S_ISREG(lock_fd_stat.st_mode) or stat.S_ISLNK(lock_path_stat.st_mode)
            or (lock_fd_stat.st_dev, lock_fd_stat.st_ino)
            != (lock_path_stat.st_dev, lock_path_stat.st_ino)):
        raise OSError(errno.EPERM, "lock path is not the anchored regular file")
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)

    parent_recheck = os.lstat(parent_path)
    if (parent_fd_stat.st_dev, parent_fd_stat.st_ino) \
            != (parent_recheck.st_dev, parent_recheck.st_ino):
        raise OSError(errno.EPERM, "lock parent identity changed before exec")
except BlockingIOError:
    print("tune-calibration: another tuner holds the advisory lock; wait for it to exit",
          file=sys.stderr)
    raise SystemExit(1)
except OSError as error:
    print(f"tune-calibration: cannot safely acquire advisory lock: {error}", file=sys.stderr)
    raise SystemExit(1)
finally:
    if parent_fd is not None:
        os.close(parent_fd)

os.set_inheritable(lock_fd, True)
environment = os.environ.copy()
environment["TUNE_CALIBRATION_INHERITED_LOCK"] = "1"
environment["TUNE_CALIBRATION_LOCK_FD"] = str(lock_fd)
os.execve("/bin/bash", ["/bin/bash", script, "__tune_calibration_locked_inner", lock_path],
          environment)
PY
}

setval_at() {
  local rules_directory=$1
  local target_name=$2
  local name=$3
  local value=$4
  (
    close_advisory_lock_for_child
    python3 - "$rules_directory" "$target_name" "$name" "$value" <<'PY'
import errno
import os
import re
import secrets
import stat
import sys

rules_directory, target_name, name, value = sys.argv[1:]
display_path = os.path.join(rules_directory, target_name)
if not os.path.isabs(rules_directory):
    raise SystemExit(f"Rules directory must be absolute: {rules_directory}")
if os.path.basename(target_name) != target_name or target_name in ("", ".", ".."):
    raise SystemExit(f"target must be a basename: {target_name}")

directory_flags = os.O_RDONLY | os.O_DIRECTORY
if hasattr(os, "O_NOFOLLOW"):
    directory_flags |= os.O_NOFOLLOW
target_flags = os.O_RDONLY
if hasattr(os, "O_NOFOLLOW"):
    target_flags |= os.O_NOFOLLOW

directory_fd = None
temporary_name = None
try:
    directory_path_stat = os.lstat(rules_directory)
    directory_fd = os.open(rules_directory, directory_flags)
    directory_fd_stat = os.fstat(directory_fd)
    if (not stat.S_ISDIR(directory_fd_stat.st_mode)
            or stat.S_ISLNK(directory_path_stat.st_mode)
            or (directory_fd_stat.st_dev, directory_fd_stat.st_ino)
            != (directory_path_stat.st_dev, directory_path_stat.st_ino)):
        raise OSError(errno.EPERM, "Rules path is not the opened real directory")

    target_path_stat = os.stat(target_name, dir_fd=directory_fd, follow_symlinks=False)
    if stat.S_ISLNK(target_path_stat.st_mode) or not stat.S_ISREG(target_path_stat.st_mode):
        raise OSError(errno.EPERM, f"refusing to replace non-regular target: {display_path}")
    target_fd = os.open(target_name, target_flags, dir_fd=directory_fd)
    with os.fdopen(target_fd, "r", encoding="utf-8") as target:
        target_fd_stat = os.fstat(target.fileno())
        if (target_fd_stat.st_dev, target_fd_stat.st_ino) \
                != (target_path_stat.st_dev, target_path_stat.st_ino):
            raise OSError(errno.EPERM, f"target identity changed while opening: {display_path}")
        text = target.read()

    pattern = re.compile(
        rf"^(?P<prefix>\s*public static let {re.escape(name)}\s*=\s*)"
        rf"[-0-9._]+(?P<suffix>\s*(?://.*)?)$",
        re.MULTILINE,
    )
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        raise OSError(f"expected exactly one {name} constant in {display_path}, "
                      f"found {len(matches)}")
    updated = pattern.sub(lambda match: match["prefix"] + value + match["suffix"], text)

    temporary_flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        temporary_flags |= os.O_NOFOLLOW
    for _ in range(32):
        candidate = f".{target_name}.{os.getpid()}.{secrets.token_hex(8)}"
        try:
            temporary_fd = os.open(candidate, temporary_flags, 0o600, dir_fd=directory_fd)
            temporary_name = candidate
            break
        except FileExistsError:
            continue
    else:
        raise OSError(errno.EEXIST, "could not create an exclusive anchored temporary file")

    with os.fdopen(temporary_fd, "w", encoding="utf-8") as temporary:
        temporary.write(updated)
        temporary.flush()
        os.fchmod(temporary.fileno(), stat.S_IMODE(target_path_stat.st_mode))
        os.fsync(temporary.fileno())

    if os.environ.get("TUNE_CALIBRATION_TEST_REPLACE_TARGET") == "1":
        replacement_name = f".{target_name}.replacement.{os.getpid()}.{secrets.token_hex(8)}"
        replacement_fd = os.open(replacement_name, temporary_flags, 0o600, dir_fd=directory_fd)
        try:
            replacement_content = os.environ.get(
                "TUNE_CALIBRATION_TEST_REPLACEMENT_CONTENT", "replacement fixture\n")
            with os.fdopen(replacement_fd, "w", encoding="utf-8") as replacement:
                replacement.write(replacement_content)
                replacement.flush()
                os.fsync(replacement.fileno())
            os.replace(replacement_name, target_name,
                       src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
        except BaseException:
            try:
                os.unlink(replacement_name, dir_fd=directory_fd)
            except FileNotFoundError:
                pass
            raise

    target_recheck = os.stat(target_name, dir_fd=directory_fd, follow_symlinks=False)
    if (stat.S_ISLNK(target_recheck.st_mode) or not stat.S_ISREG(target_recheck.st_mode)
            or (target_recheck.st_dev, target_recheck.st_ino)
            != (target_path_stat.st_dev, target_path_stat.st_ino)):
        raise OSError(errno.EPERM, f"refusing to replace changed target: {display_path}")
    directory_recheck = os.lstat(rules_directory)
    if (stat.S_ISLNK(directory_recheck.st_mode)
            or (directory_fd_stat.st_dev, directory_fd_stat.st_ino)
            != (directory_recheck.st_dev, directory_recheck.st_ino)):
        raise OSError(errno.EPERM, "Rules directory identity changed before replacement")

    os.replace(temporary_name, target_name,
               src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
    temporary_name = None
    os.fsync(directory_fd)
except (OSError, UnicodeError) as error:
    raise SystemExit(f"refusing unsafe calibration replacement: {error}")
finally:
    if temporary_name is not None and directory_fd is not None:
        try:
            os.unlink(temporary_name, dir_fd=directory_fd)
        except FileNotFoundError:
            pass
    if directory_fd is not None:
        os.close(directory_fd)
PY
  )
}

setval() {
  setval_at "$expected_rules_dir" "MatchupRules.swift" "$1" "$2"
}

# This isolated, inert-by-default entry point exercises the same descriptor-relative replacement
# helper without touching the repository Rules directory or acquiring its .build lock.
if [[ ${TUNE_CALIBRATION_TEST_SETVAL:-} == 1 ]]; then
  [[ $# -eq 0 ]] || die "test setval mode takes no arguments"
  [[ -n ${TUNE_CALIBRATION_TEST_RULES_DIR:-} \
      && -n ${TUNE_CALIBRATION_TEST_RULES_TARGET:-} \
      && -n ${TUNE_CALIBRATION_TEST_RULES_NAME:-} \
      && -n ${TUNE_CALIBRATION_TEST_RULES_VALUE:-} ]] \
    || die "test setval mode requires an isolated directory, target, name, and value"
  setval_at "$TUNE_CALIBRATION_TEST_RULES_DIR" "$TUNE_CALIBRATION_TEST_RULES_TARGET" \
    "$TUNE_CALIBRATION_TEST_RULES_NAME" "$TUNE_CALIBRATION_TEST_RULES_VALUE"
  exit 0
fi

# Validate the exact mutation target before parsing public modes or starting the search.
validate_matchup_rules

if [[ ${1:-} == "--validate" && $# -eq 1 ]]; then
  printf 'validated %s\n' "$matchup_rules"
  exit 0
fi
[[ $# -eq 0 ]] || die "usage: tune-calibration.sh [--validate]"

if [[ ${TUNE_CALIBRATION_TEST_CONTRACT_MODE:-} == 1 \
    || ${TUNE_CALIBRATION_TEST_CONTRACT_RULES_DIR+x} == x ]]; then
  activate_contract_rules_override
fi

if [[ -z "$advisory_lock_fd" ]]; then
  prepare_lock_parent
  launch_with_advisory_lock
fi
validate_lock_parent

names=(leverageNoise laneYardScale breakTackleThreshold sackPressureThreshold completionThreshold homeAdvantage brokenTackleYards maximumBrokenTackles)
grids=("0.22 0.30 0.38 0.46" "3.0 5.0 7.0 9.0" "0.35 0.45 0.55 0.65" "0.45 0.60 0.75 0.90" "-0.30 -0.16 -0.02 0.10" "0.02 0.04 0.07 0.10" "2 3 4 5" "2 3 4 5")
accepted_values=()
rollback_armed=0
candidate_active=0

restore_accepted_values() {
  local index name rollback_helper_pid
  local restore_failed=0
  printf 'tune-calibration: restoring last accepted calibration constants\n' >&2
  if [[ ${TUNE_CALIBRATION_TEST_ROLLBACK_HOLD:-} == 1 ]]; then
    (
      close_advisory_lock_for_child
      sleep 2
    ) &
    rollback_helper_pid=$!
    printf 'tune-calibration: test rollback lockless helper pid=%s\n' \
      "$rollback_helper_pid" >&2
    wait "$rollback_helper_pid" || restore_failed=1
  fi
  for index in "${!names[@]}"; do
    name=${names[$index]}
    if ! setval "$name" "${accepted_values[$index]}"; then
      printf 'tune-calibration: failed to restore %s\n' "$name" >&2
      restore_failed=1
    fi
  done
  return "$restore_failed"
}

rollback_on_exit() {
  local status=$?
  local restore_status=0
  trap - EXIT HUP INT TERM
  if (( status != 0 && rollback_armed == 1 )); then
    set +e
    restore_accepted_values
    restore_status=$?
    set -e
    if (( restore_status != 0 )); then
      printf 'tune-calibration: rollback was incomplete; inspect MatchupRules.swift before retrying\n' >&2
    fi
  fi
  exit "$status"
}

trap rollback_on_exit EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Test-only modes are inert normally and run after descriptor verification, before score/mutation.
if [[ ${TUNE_CALIBRATION_TEST_HOLD_LOCK:-} == 1 ]]; then
  hold_seconds=${TUNE_CALIBRATION_TEST_HOLD_SECONDS:-2}
  [[ "$hold_seconds" =~ ^[1-9][0-9]*$ ]] || die "invalid test hold duration"
  (
    close_advisory_lock_for_child
    sleep "$hold_seconds"
  ) &
  helper_pid=$!
  printf 'tune-calibration: test lockless helper pid=%s\n' "$helper_pid"
  wait "$helper_pid"
  exit 0
fi
if [[ ${TUNE_CALIBRATION_TEST_LOCK_ONLY:-} == 1 ]]; then
  exit 0
fi
if [[ ${TUNE_CALIBRATION_TEST_CHILD_FD:-} == 1 ]]; then
  (
    close_advisory_lock_for_child
    python3 - "$advisory_lock_fd" <<'PY'
import errno
import os
import sys

try:
    os.fstat(int(sys.argv[1]))
except OSError as error:
    if error.errno == errno.EBADF:
        print("advisory lock descriptor closed for child (EBADF)")
        raise SystemExit(0)
    raise
raise SystemExit("advisory lock descriptor leaked to child")
PY
  )
  exit 0
fi
if [[ ${TUNE_CALIBRATION_TEST_RECURSIVE_CHILD:-} == 1 ]]; then
  recursive_status=0
  (
    close_advisory_lock_for_child
    TUNE_CALIBRATION_TEST_RECURSIVE_CHILD='' TUNE_CALIBRATION_TEST_LOCK_ONLY=1 \
      "$script_dir/tune-calibration.sh"
  ) || recursive_status=$?
  if (( recursive_status == 0 )); then
    die "recursive child unexpectedly acquired advisory lock"
  fi
  exit 0
fi

score() {
  # score is always called through command substitution; close this subshell's inherited FD first.
  close_advisory_lock_for_child
  local output line score_counts passed total
  local score_prefixed_lines=0
  local -a score_lines=()
  if [[ ${TUNE_CALIBRATION_TEST_FAIL_FIRST_CANDIDATE:-} == 1 ]]; then
    if (( candidate_active == 1 )); then
      output="SCORE candidate-failure"
    else
      output="SCORE 0/24"
    fi
  elif [[ ${TUNE_CALIBRATION_TEST_SCORE_OUTPUT+x} == x ]]; then
    output=$TUNE_CALIBRATION_TEST_SCORE_OUTPUT
  elif ! output=$(cd "$repo_root" && swift run -c release CalibrationScore tuning); then
    die "CalibrationScore failed"
  fi
  printf '%s\n' "$output" >&2
  while IFS= read -r line; do
    [[ $line == SCORE* ]] && ((score_prefixed_lines += 1))
    if [[ $line =~ ^SCORE\ [0-9]+/[0-9]+$ ]]; then
      score_lines+=("$line")
    fi
  done <<< "$output"
  [[ ${#score_lines[@]} -eq 1 && $score_prefixed_lines -eq 1 ]] \
    || die "expected exactly one well-formed SCORE passed/total line"
  score_counts=${score_lines[0]#SCORE }
  passed=${score_counts%/*}
  total=${score_counts#*/}
  [[ $passed =~ ^[0-9]+$ && $total =~ ^[0-9]+$ ]] \
    || die "SCORE counts are not numeric"
  (( 10#$passed <= 10#$total )) || die "SCORE passed count exceeds total"
  (( 10#$total > 0 )) || die "SCORE total must be greater than zero"
  (( 10#$total == 24 )) || die "SCORE total must equal the 24 implemented bands"
  printf '%s\n' "$passed"
}

read_constant() {
  close_advisory_lock_for_child
  local searched_name=$1
  local line value="" count=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line =~ ^[[:space:]]*public[[:space:]]static[[:space:]]let[[:space:]]${searched_name}[[:space:]]*=[[:space:]]*([-0-9._]+) ]]; then
      value=${BASH_REMATCH[1]}
      ((count += 1))
    fi
  done < "$matchup_rules"
  [[ $count -eq 1 ]] || die "expected exactly one readable ${searched_name} constant"
  printf '%s\n' "$value"
}

if [[ ${TUNE_CALIBRATION_TEST_FAIL_FIRST_CANDIDATE:-} == 1 \
    && ${TUNE_CALIBRATION_TEST_SCORE_OUTPUT+x} == x ]]; then
  die "candidate-failure and score-output hooks cannot be combined"
fi

best=$(score)
printf 'start SCORE=%s\n' "$best"
if [[ ${TUNE_CALIBRATION_TEST_SCORE_OUTPUT+x} == x ]]; then
  printf 'tune-calibration: test score-output contract accepted without search\n'
  exit 0
fi
for i in "${!names[@]}"; do
  accepted_values[i]=$(read_constant "${names[$i]}")
done
rollback_armed=1

for pass_n in 1 2; do
  for i in "${!names[@]}"; do
    name=${names[$i]}
    best_value=${accepted_values[$i]}
    for value in ${grids[$i]}; do
      setval "$name" "$value"
      candidate_active=1
      candidate=$(score)
      candidate_active=0
      if (( 10#$candidate > 10#$best )); then
        best=$candidate
        best_value=$value
      fi
    done
    setval "$name" "$best_value"
    accepted_values[i]=$best_value
    printf 'pass%s %s -> %s (SCORE=%s)\n' "$pass_n" "$name" "$best_value" "$best"
  done
done

for i in "${!names[@]}"; do
  name=${names[$i]}
  [[ $(read_constant "$name") == "${accepted_values[$i]}" ]] \
    || die "final accepted value was not fully written for ${name}"
done
rollback_armed=0
trap - EXIT HUP INT TERM
printf 'FINAL SCORE=%s\n' "$best"
