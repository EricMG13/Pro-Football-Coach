#!/usr/bin/env bash
# Coordinate descent over the dominant calibration constants. Rebuilds and re-measures for each
# candidate value, keeps the best, and repeats. Hand-tuning was thrashing; this is bounded and
# reproducible.
set -uo pipefail
REPO=/Users/ericguei/Documents/Pro-Football-Coach
PROBE=/private/tmp/claude-501/-Users-ericguei-Documents-Pro-Football-Coach/9de0fe25-1ad8-4476-8f7d-9f2e1cc20bbb/scratchpad/fallback
M=$REPO/Sources/FootballSimCore/Rules/MatchupRules.swift
C=$REPO/Sources/FootballSimCore/Rules/ClockRules.swift

setval() { python3 - "$1" "$2" "$3" <<'PY'
import sys, re, pathlib
path, name, val = sys.argv[1], sys.argv[2], sys.argv[3]
p = pathlib.Path(path); t = p.read_text()
t2 = re.sub(r'(public static let ' + re.escape(name) + r' = )[-0-9._]+', r'\g<1>' + val, t, count=1)
p.write_text(t2)
PY
}
score() {
  ( cd "$PROBE" && swift run -c release Search 2>/dev/null | grep -oE 'SCORE [0-9]+' | awk '{print $2}' )
}

declare -A BEST
names=(leverageNoise laneYardScale breakTackleThreshold sackPressureThreshold completionThreshold homeAdvantage)
files=("$M" "$M" "$M" "$M" "$M" "$M")
grids=("0.22 0.30 0.38 0.46" "5.0 7.0 9.0 11.0" "0.40 0.50 0.60 0.70" "0.45 0.60 0.75 0.90" "-0.30 -0.16 -0.02 0.10" "0.02 0.04 0.07 0.10")

best=$(score); echo "start SCORE=$best"
for pass_n in 1 2; do
  for i in "${!names[@]}"; do
    n=${names[$i]}; f=${files[$i]}
    orig=$(grep -oE "public static let $n = [-0-9._]+" "$f" | grep -oE '[-0-9._]+$')
    bestv=$orig
    for v in ${grids[$i]}; do
      setval "$f" "$n" "$v"
      s=$(score)
      [ -z "$s" ] && s=0
      if [ "$s" -gt "$best" ]; then best=$s; bestv=$v; fi
    done
    setval "$f" "$n" "$bestv"
    echo "pass$pass_n $n -> $bestv (SCORE=$best)"
  done
done
echo "FINAL SCORE=$best"
