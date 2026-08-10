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

# Validate the exact mutation target before parsing modes or starting the search.
validate_matchup_rules

if [[ ${1:-} == "--validate" && $# -eq 1 ]]; then
  printf 'validated %s\n' "$matchup_rules"
  exit 0
fi
[[ $# -eq 0 ]] || die "usage: tune-calibration.sh [--validate]"

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
