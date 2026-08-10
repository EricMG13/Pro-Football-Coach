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
lock_dir="$lock_parent/tune-calibration.lock"
lock_parent_identity=""
lock_identity=""
search_lock_held=0

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
  [[ "$lock_parent" == "$repo_root/.build" && "$lock_dir" == "$lock_parent/tune-calibration.lock" ]] \
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

release_search_lock() {
  (( search_lock_held )) || return 0
  [[ "$lock_dir" == "$lock_parent/tune-calibration.lock" && -d "$lock_dir" && ! -L "$lock_dir" ]] \
    || {
      printf 'tune-calibration: refusing to release a changed calibration lock; inspect %s manually\n' \
        "$lock_dir" >&2
      return 1
    }
  local current_parent_identity current_lock_identity
  current_parent_identity=$(stat -f '%d:%i' "$lock_parent") \
    || {
      printf 'tune-calibration: cannot inspect calibration lock parent; inspect %s manually\n' \
        "$lock_dir" >&2
      return 1
    }
  current_lock_identity=$(stat -f '%d:%i' "$lock_dir") \
    || {
      printf 'tune-calibration: cannot inspect calibration lock; inspect %s manually\n' "$lock_dir" >&2
      return 1
    }
  [[ "$current_parent_identity" == "$lock_parent_identity" && "$current_lock_identity" == "$lock_identity" ]] \
    || {
      printf 'tune-calibration: refusing to release a replaced calibration lock; inspect %s manually\n' \
        "$lock_dir" >&2
      return 1
    }
  if ! rmdir "$lock_dir"; then
    printf 'tune-calibration: could not safely release calibration lock %s; inspect it manually\n' \
      "$lock_dir" >&2
    return 1
  fi
  search_lock_held=0
}

release_search_lock_on_exit() {
  local status=$?
  trap - EXIT HUP INT TERM
  release_search_lock || exit 1
  exit "$status"
}

acquire_search_lock() {
  prepare_lock_parent
  lock_parent_identity=$(stat -f '%d:%i' "$lock_parent") \
    || die "cannot inspect calibration lock parent"
  if ! mkdir "$lock_dir"; then
    die "cannot acquire calibration lock at $lock_dir; another tuner may be running or the lock may be stale/tampered. Confirm no tuner is running, inspect the lock, then remove only that empty directory."
  fi
  lock_identity=$(stat -f '%d:%i' "$lock_dir") \
    || die "cannot inspect newly acquired calibration lock"
  search_lock_held=1
  trap release_search_lock_on_exit EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
}

# Validate the exact mutation target before parsing modes or starting the search.
validate_matchup_rules

if [[ ${1:-} == "--validate" && $# -eq 1 ]]; then
  printf 'validated %s\n' "$matchup_rules"
  exit 0
fi
[[ $# -eq 0 ]] || die "usage: tune-calibration.sh [--validate]"

# Search must own this lock before its first score or source mutation.
acquire_search_lock

setval() {
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
}

score() {
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
    original=$(sed -nE "s/^[[:space:]]*public static let ${name}[[:space:]]*=[[:space:]]*([-0-9._]+).*/\1/p" "$matchup_rules")
    [[ $(printf '%s\n' "$original" | sed '/^$/d' | wc -l | tr -d ' ') -eq 1 ]] \
      || die "expected exactly one readable ${name} constant"
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
