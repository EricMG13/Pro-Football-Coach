#!/usr/bin/env bash
# Coordinate descent over the dominant calibration constants. Every candidate is measured by the
# checked-in scorer against tuning seeds only; holdout seeds remain untouched until handoff.
set -euo pipefail

die() {
  printf 'tune-calibration: %s\n' "$*" >&2
  exit 1
}

script_dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -P -- "$script_dir/.." && pwd)
expected_rules_dir=$(cd -P -- "$repo_root/Sources/FootballSimCore/Rules" && pwd) \
  || die "cannot resolve Rules directory under script-derived repository"
matchup_rules="$expected_rules_dir/MatchupRules.swift"
lock_parent="$repo_root/.build"
lock_file="$lock_parent/tune-calibration.lock"
advisory_lock_fd=""

validate_matchup_rules() {
  [[ "$matchup_rules" == "$expected_rules_dir/MatchupRules.swift" ]] \
    || die "unexpected MatchupRules path"
  [[ "$expected_rules_dir" == "$repo_root/"* ]] \
    || die "Rules directory escapes script-derived repository"
  [[ -f "$matchup_rules" && ! -L "$matchup_rules" ]] \
    || die "expected a regular, non-symlink MatchupRules.swift"
  local resolved_rules_dir
  resolved_rules_dir=$(cd -P -- "$(dirname -- "$matchup_rules")" && pwd) \
    || die "cannot resolve MatchupRules.swift parent"
  [[ "$resolved_rules_dir" == "$expected_rules_dir" ]] \
    || die "MatchupRules.swift is outside its expected repository path"
}

validate_lock_parent() {
  [[ "$lock_parent" == "$repo_root/.build" && "$lock_file" == "$lock_parent/tune-calibration.lock" ]] \
    || die "unexpected calibration lock path"
  [[ "$lock_parent" == "$repo_root/"* && "$lock_parent" != "$repo_root" ]] \
    || die "calibration lock parent escapes script-derived repository"
  [[ -d "$lock_parent" && ! -L "$lock_parent" ]] \
    || die "calibration lock parent must be a real directory, not a symlink"
  local resolved_lock_parent
  resolved_lock_parent=$(cd -P -- "$lock_parent" && pwd) \
    || die "cannot resolve calibration lock parent"
  [[ "$resolved_lock_parent" == "$repo_root/.build" ]] \
    || die "calibration lock parent escapes script-derived repository"
  git -C "$repo_root" check-ignore -q -- .build/tune-calibration.lock \
    || die "calibration lock location must be an ignored build or scratch path"
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
flags = os.O_RDWR | os.O_CREAT
if hasattr(os, "O_NOFOLLOW"):
    flags |= os.O_NOFOLLOW
try:
    lock_fd = os.open(lock_path, flags, 0o600)
    fd_stat = os.fstat(lock_fd)
    path_stat = os.lstat(lock_path)
    if (not stat.S_ISREG(fd_stat.st_mode) or stat.S_ISLNK(path_stat.st_mode)
            or (fd_stat.st_dev, fd_stat.st_ino) != (path_stat.st_dev, path_stat.st_ino)):
        raise OSError(errno.EPERM, "lock path is not the opened regular file")
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    print("tune-calibration: another tuner holds the advisory lock; wait for it to exit", file=sys.stderr)
    raise SystemExit(1)
except OSError as error:
    print(f"tune-calibration: cannot safely acquire advisory lock: {error}", file=sys.stderr)
    raise SystemExit(1)

os.set_inheritable(lock_fd, True)
environment = os.environ.copy()
environment["TUNE_CALIBRATION_INHERITED_LOCK"] = "1"
environment["TUNE_CALIBRATION_LOCK_FD"] = str(lock_fd)
os.execve("/bin/bash", ["/bin/bash", script], environment)
PY
}

verify_inherited_advisory_lock() {
  [[ ${TUNE_CALIBRATION_INHERITED_LOCK:-} == 1 ]] \
    || die "missing inherited advisory-lock marker"
  [[ ${TUNE_CALIBRATION_LOCK_FD:-} =~ ^[0-9]+$ ]] \
    || die "invalid inherited advisory-lock descriptor"
  python3 - "$TUNE_CALIBRATION_LOCK_FD" "$lock_file" <<'PY'
import fcntl
import os
import stat
import sys

try:
    lock_fd = int(sys.argv[1])
    fd_stat = os.fstat(lock_fd)
    path_stat = os.lstat(sys.argv[2])
    if (not stat.S_ISREG(fd_stat.st_mode) or stat.S_ISLNK(path_stat.st_mode)
            or (fd_stat.st_dev, fd_stat.st_ino) != (path_stat.st_dev, path_stat.st_ino)):
        raise OSError("inherited descriptor does not match the regular lock file")
    fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except (OSError, ValueError) as error:
    print(f"tune-calibration: inherited advisory lock is invalid: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
}

close_advisory_lock_for_child() {
  [[ "$advisory_lock_fd" =~ ^[0-9]+$ ]] \
    || die "invalid advisory-lock descriptor for child"
  # The descriptor is numeric and verified above, so this evaluates exactly `exec N>&-`.
  eval "exec ${advisory_lock_fd}>&-"
}

# Validate the exact mutation target before parsing modes or starting the search.
validate_matchup_rules

if [[ ${1:-} == "--validate" && $# -eq 1 ]]; then
  printf 'validated %s\n' "$matchup_rules"
  exit 0
fi
[[ $# -eq 0 ]] || die "usage: tune-calibration.sh [--validate]"

if [[ ${TUNE_CALIBRATION_INHERITED_LOCK:-} != 1 ]]; then
  prepare_lock_parent
  launch_with_advisory_lock
fi
validate_lock_parent
verify_inherited_advisory_lock
advisory_lock_fd=$TUNE_CALIBRATION_LOCK_FD
unset TUNE_CALIBRATION_INHERITED_LOCK TUNE_CALIBRATION_LOCK_FD

# Test-only modes are inert normally and run after descriptor verification, before score/mutation.
if [[ ${TUNE_CALIBRATION_TEST_HOLD_LOCK:-} == 1 ]]; then
  (
    close_advisory_lock_for_child
    sleep 10
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
        print("advisory lock descriptor closed for child")
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
    TUNE_CALIBRATION_TEST_RECURSIVE_CHILD= TUNE_CALIBRATION_TEST_LOCK_ONLY=1 \
      "$script_dir/tune-calibration.sh"
  ) || recursive_status=$?
  if (( recursive_status == 0 )); then
    die "recursive child unexpectedly acquired advisory lock"
  fi
  exit 0
fi

setval() {
  (
    close_advisory_lock_for_child
    python3 - "$matchup_rules" "$1" "$2" <<'PY'
import os
import pathlib
import re
import sys
import tempfile

path = pathlib.Path(sys.argv[1])
name = sys.argv[2]
value = sys.argv[3]

try:
    stat = path.lstat()
except FileNotFoundError:
    raise SystemExit(f"missing target: {path}")
if path.is_symlink() or not path.is_file():
    raise SystemExit(f"refusing to replace non-regular target: {path}")

pattern = re.compile(
    rf"^(?P<prefix>\s*public static let {re.escape(name)}\s*=\s*)"
    rf"[-0-9._]+(?P<suffix>\s*(?://.*)?)$",
    re.MULTILINE,
)
text = path.read_text(encoding="utf-8")
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise SystemExit(f"expected exactly one {name} constant in {path}, found {len(matches)}")
updated = pattern.sub(lambda match: match["prefix"] + value + match["suffix"], text)

descriptor, temporary_path = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
try:
    with os.fdopen(descriptor, "w", encoding="utf-8") as temporary:
        temporary.write(updated)
        temporary.flush()
        os.fsync(temporary.fileno())
    os.chmod(temporary_path, stat.st_mode)
    if path.is_symlink() or not path.is_file():
        raise SystemExit(f"refusing to replace changed target: {path}")
    os.replace(temporary_path, path)
except BaseException:
    try:
        os.unlink(temporary_path)
    except FileNotFoundError:
        pass
    raise
PY
  )
}

score() {
  # score is always called through command substitution; close this subshell's inherited FD first.
  close_advisory_lock_for_child
  local output line
  local -a score_lines=()
  if ! output=$(cd "$repo_root" && swift run -c release CalibrationScore tuning); then
    die "CalibrationScore failed"
  fi
  printf '%s\n' "$output" >&2
  while IFS= read -r line; do
    if [[ $line =~ ^SCORE\ [0-9]+/[0-9]+$ ]]; then
      score_lines+=("$line")
    fi
  done <<< "$output"
  [[ ${#score_lines[@]} -eq 1 ]] || die "expected exactly one SCORE passed/total line"
  local passed=${score_lines[0]#SCORE }
  passed=${passed%/*}
  [[ $passed =~ ^[0-9]+$ ]] || die "SCORE passed count is not numeric"
  printf '%s\n' "$passed"
}

names=(leverageNoise laneYardScale breakTackleThreshold sackPressureThreshold completionThreshold homeAdvantage brokenTackleYards maximumBrokenTackles)
grids=("0.22 0.30 0.38 0.46" "3.0 5.0 7.0 9.0" "0.35 0.45 0.55 0.65" "0.45 0.60 0.75 0.90" "-0.30 -0.16 -0.02 0.10" "0.02 0.04 0.07 0.10" "2 3 4 5" "2 3 4 5")

best=$(score)
printf 'start SCORE=%s\n' "$best"
for pass_n in 1 2; do
  for i in "${!names[@]}"; do
    name=${names[$i]}
    original=""
    original_count=0
    while IFS= read -r rules_line || [[ -n "$rules_line" ]]; do
      if [[ $rules_line =~ ^[[:space:]]*public[[:space:]]static[[:space:]]let[[:space:]]${name}[[:space:]]*=[[:space:]]*([-0-9._]+) ]]; then
        original=${BASH_REMATCH[1]}
        ((original_count += 1))
      fi
    done < "$matchup_rules"
    [[ $original_count -eq 1 ]] || die "expected exactly one readable ${name} constant"
    best_value=$original
    for value in ${grids[$i]}; do
      setval "$name" "$value"
      candidate=$(score)
      if (( 10#$candidate > 10#$best )); then
        best=$candidate
        best_value=$value
      fi
    done
    setval "$name" "$best_value"
    printf 'pass%s %s -> %s (SCORE=%s)\n' "$pass_n" "$name" "$best_value" "$best"
  done
done
printf 'FINAL SCORE=%s\n' "$best"
