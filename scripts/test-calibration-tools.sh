#!/usr/bin/env bash
# Fast, deterministic contracts for the calibration scorer and tuner safety envelope.
set -euo pipefail

script_source=${BASH_SOURCE[0]}
script_parent=${script_source%/*}
[[ "$script_parent" != "$script_source" ]] || script_parent=.
script_dir=$(cd -P -- "$script_parent" && pwd)
repo_root=$(cd -P -- "$script_dir/.." && pwd)
tuner="$script_dir/tune-calibration.sh"
rules="$repo_root/Sources/FootballSimCore/Rules/MatchupRules.swift"

fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/pfc-calibration-tools.XXXXXX")
fixture_rules="$fixture_root/rules"
rollback_rules="$fixture_root/rollback-rules"
case_log="$fixture_root/case.log"
holder_log="$fixture_root/holder.log"
contender_log="$fixture_root/contender.log"
timeout_ready="$fixture_root/timeout-ready"
holder_pid=""
mkdir "$fixture_rules" "$rollback_rules"
resolved_rollback_rules=$(cd -P -- "$rollback_rules" && pwd)

supervised_wait_status=0

reap_exact_child() {
  local child_pid=$1
  if wait "$child_pid" 2>/dev/null; then
    supervised_wait_status=0
  else
    supervised_wait_status=$?
  fi
}

bounded_reap_pid() {
  local child_pid=$1
  local maximum_polls=$2
  local poll=0 state
  [[ "$child_pid" =~ ^[1-9][0-9]*$ && "$maximum_polls" =~ ^[0-9]+$ ]] || return 2
  while :; do
    if ! state=$(ps -o stat= -p "$child_pid" 2>/dev/null); then
      reap_exact_child "$child_pid"
      return 0
    fi
    state=${state//[[:space:]]/}
    if [[ $state == Z* ]]; then
      reap_exact_child "$child_pid"
      return 0
    fi
    (( poll < maximum_polls )) || return 1
    sleep 0.05
    ((poll += 1))
  done
}

terminate_and_reap_pid() {
  local child_pid=$1
  [[ "$child_pid" =~ ^[1-9][0-9]*$ ]] || return 2
  kill -TERM "$child_pid" 2>/dev/null || true
  if bounded_reap_pid "$child_pid" 10; then
    return 0
  fi
  kill -KILL "$child_pid" 2>/dev/null || true
  bounded_reap_pid "$child_pid" 10
}

cleanup() {
  local original_status=$?
  local cleanup_status=0
  local cleanup_directory leftover
  trap - EXIT HUP INT TERM
  set +e
  if [[ "$holder_pid" =~ ^[1-9][0-9]*$ ]]; then
    if ! bounded_reap_pid "$holder_pid" 10; then
      terminate_and_reap_pid "$holder_pid" || cleanup_status=1
    fi
    holder_pid=""
  fi
  rm -f -- "$fixture_root/rules-link" "$fixture_rules/MatchupRules.swift" \
    "$fixture_rules/referent.swift" "$rollback_rules/MatchupRules.swift" \
    "$case_log" "$holder_log" "$contender_log" "$timeout_ready" || cleanup_status=1
  for cleanup_directory in "$fixture_rules" "$rollback_rules"; do
    for leftover in "$cleanup_directory"/.[!.]* "$cleanup_directory"/..?*; do
      [[ -e "$leftover" || -L "$leftover" ]] || continue
      case "$leftover" in
        "$cleanup_directory"/*) rm -f -- "$leftover" || cleanup_status=1 ;;
        *) cleanup_status=1 ;;
      esac
    done
  done
  rmdir "$fixture_rules" "$rollback_rules" "$fixture_root" >/dev/null 2>&1 \
    || cleanup_status=1
  if (( original_status == 0 && cleanup_status != 0 )); then
    printf 'FAIL  fixture cleanup left unexpected paths under %s\n' "$fixture_root" >&2
    original_status=1
  fi
  exit "$original_status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

passes=0
pass_case() {
  printf 'PASS  %s\n' "$1"
  ((passes += 1))
}

fail_case() {
  printf 'FAIL  %s\n' "$1" >&2
  if [[ -s "$case_log" ]]; then
    sed -n '1,80p' "$case_log" >&2
  fi
  exit 1
}

expect_failure() {
  local label=$1
  shift
  if "$@" >"$case_log" 2>&1; then
    fail_case "$label unexpectedly succeeded"
  fi
  pass_case "$label"
}

expect_success() {
  local label=$1
  shift
  if ! "$@" >"$case_log" 2>&1; then
    fail_case "$label failed"
  fi
  pass_case "$label"
}

rules_checksum() {
  shasum -a 256 "$rules" | awk '{print $1}'
}

cd "$repo_root"
cp "$rules" "$rollback_rules/MatchupRules.swift"

# Exercise the deadline path without adding an advertised contract: the child ignores TERM after
# signalling readiness, so supervision must escalate to KILL for exactly this recorded `$!` PID.
/bin/bash -c 'trap "" TERM; : > "$1"; while :; do :; done' _ "$timeout_ready" &
holder_pid=$!
timeout_ready_seen=0
attempt=0
while (( attempt < 100 )); do
  if [[ -f "$timeout_ready" ]]; then
    timeout_ready_seen=1
    break
  fi
  sleep 0.01
  ((attempt += 1))
done
if (( timeout_ready_seen != 1 )); then
  terminate_and_reap_pid "$holder_pid" || true
  holder_pid=""
  fail_case "bounded-supervision timeout fixture did not become ready"
fi
if bounded_reap_pid "$holder_pid" 2; then
  holder_pid=""
  fail_case "bounded-supervision timeout fixture exited before its deadline"
fi
terminate_and_reap_pid "$holder_pid" \
  || fail_case "bounded supervision could not terminate and reap its exact child PID"
holder_pid=""
[[ $supervised_wait_status -eq 137 ]] \
  || fail_case "bounded supervision did not reach the exact-PID KILL fallback"
printf '      bounded supervision TERM/KILL/reap self-test passed\n'

expect_failure "scorer rejects a missing mode" swift run -c release CalibrationScore
grep -q 'usage: CalibrationScore <tuning|holdout>' "$case_log" \
  || fail_case "missing-mode scorer failure omitted usage"
expect_failure "scorer rejects an unknown mode" swift run -c release CalibrationScore unknown
grep -q 'usage: CalibrationScore <tuning|holdout>' "$case_log" \
  || fail_case "unknown-mode scorer failure omitted usage"

expect_success "tuner passes Bash syntax validation" /bin/bash -n "$tuner"
expect_success "tuner --validate is lock-free and non-mutating" /bin/bash "$tuner" --validate
grep -q '^validated .*MatchupRules.swift$' "$case_log" \
  || fail_case "tuner --validate omitted its validated target"
expect_failure "tuner rejects unknown arguments" /bin/bash "$tuner" --unknown
grep -q 'usage: tune-calibration.sh \[--validate\]' "$case_log" \
  || fail_case "unknown tuner argument omitted usage"

initial_rules_checksum=$(rules_checksum)
if env TUNE_CALIBRATION_TEST_CONTRACT_MODE=1 \
    TUNE_CALIBRATION_TEST_CONTRACT_RULES_DIR="${rules%/*}" \
    TUNE_CALIBRATION_TEST_FAIL_FIRST_CANDIDATE=1 \
    TUNE_CALIBRATION_TEST_ROLLBACK_HOLD=1 \
    /bin/bash "$tuner" >"$case_log" 2>&1; then
  fail_case "contract rules override accepted the tracked Rules directory"
fi
grep -Fq "contract rules override must be the gate's isolated rollback-rules directory" \
  "$case_log" || fail_case "tracked rules override refusal omitted its safety diagnostic"
[[ $(rules_checksum) == "$initial_rules_checksum" ]] \
  || fail_case "rejected contract rules override changed tracked MatchupRules.swift"
printf '      tracked Rules override refusal self-test passed\n'

score_labels=(
  "malformed score"
  "missing score"
  "duplicate score"
  "passed greater than total"
  "zero total"
  "missing implemented band"
  "extra implemented band"
)
score_outputs=(
  "SCORE nope"
  "no score line"
  $'SCORE 0/24\nSCORE 0/24'
  "SCORE 25/24"
  "SCORE 0/0"
  "SCORE 0/23"
  "SCORE 0/25"
)
score_diagnostics=(
  "tune-calibration: expected exactly one well-formed SCORE passed/total line"
  "tune-calibration: expected exactly one well-formed SCORE passed/total line"
  "tune-calibration: expected exactly one well-formed SCORE passed/total line"
  "tune-calibration: SCORE passed count exceeds total"
  "tune-calibration: SCORE total must be greater than zero"
  "tune-calibration: SCORE total must equal the 24 implemented bands"
  "tune-calibration: SCORE total must equal the 24 implemented bands"
)
for index in "${!score_outputs[@]}"; do
  if env TUNE_CALIBRATION_TEST_SCORE_OUTPUT="${score_outputs[$index]}" \
      /bin/bash "$tuner" >"$case_log" 2>&1; then
    fail_case "tuner rejects ${score_labels[$index]} unexpectedly succeeded"
  fi
  grep -Fq "${score_diagnostics[$index]}" "$case_log" \
    || fail_case "${score_labels[$index]} omitted its expected parser diagnostic"
  pass_case "tuner rejects ${score_labels[$index]}"
  [[ $(rules_checksum) == "$initial_rules_checksum" ]] \
    || fail_case "${score_labels[$index]} mutated MatchupRules.swift"
done
expect_success "valid score hook parses without entering a search" env \
  TUNE_CALIBRATION_TEST_SCORE_OUTPUT="SCORE 0/24" /bin/bash "$tuner"
grep -q 'test score-output contract accepted without search' "$case_log" \
  || fail_case "valid score hook did not stop before candidate mutation"
[[ $(rules_checksum) == "$initial_rules_checksum" ]] \
  || fail_case "valid score hook changed retained MatchupRules.swift constants"

real_rollback_before=$(rules_checksum)
fixture_rollback_before=$(shasum -a 256 "$rollback_rules/MatchupRules.swift" | awk '{print $1}')
grep -q 'TUNE_CALIBRATION_TEST_CONTRACT_RULES_DIR' "$tuner" \
  || fail_case "fixture-only rollback target override is unavailable"
env TUNE_CALIBRATION_TEST_CONTRACT_MODE=1 \
  TUNE_CALIBRATION_TEST_CONTRACT_RULES_DIR="$rollback_rules" \
  TUNE_CALIBRATION_TEST_FAIL_FIRST_CANDIDATE=1 \
  TUNE_CALIBRATION_TEST_ROLLBACK_HOLD=1 \
  /bin/bash "$tuner" >"$holder_log" 2>&1 &
holder_pid=$!
rollback_ready=0
attempt=0
while (( attempt < 100 )); do
  if grep -q 'test rollback lockless helper pid=' "$holder_log"; then
    rollback_ready=1
    break
  fi
  sleep 0.05
  ((attempt += 1))
done
if (( rollback_ready != 1 )); then
  terminate_and_reap_pid "$holder_pid" || true
  holder_pid=""
  fail_case "candidate failure did not enter rollback before its readiness deadline"
fi
grep -Fq "contract rules target $resolved_rollback_rules/MatchupRules.swift" "$holder_log" \
  || fail_case "candidate rollback did not activate its isolated rules target"
real_rollback_during=$(rules_checksum)
fixture_rollback_during=$(shasum -a 256 "$rollback_rules/MatchupRules.swift" | awk '{print $1}')
[[ "$real_rollback_during" == "$real_rollback_before" ]] \
  || fail_case "candidate fixture changed tracked MatchupRules.swift during rollback"
[[ "$fixture_rollback_during" != "$fixture_rollback_before" ]] \
  || fail_case "candidate fixture never held a trial constant before rollback"
if env TUNE_CALIBRATION_TEST_LOCK_ONLY=1 /bin/bash "$tuner" >"$contender_log" 2>&1; then
  fail_case "contender acquired the owner lock during rollback"
fi
grep -q 'another tuner holds the advisory lock' "$contender_log" \
  || fail_case "rollback contender failure did not identify lock ownership"
if ! bounded_reap_pid "$holder_pid" 100; then
  terminate_and_reap_pid "$holder_pid" || true
  holder_pid=""
  fail_case "first-candidate rollback exceeded its completion deadline"
fi
rollback_status=$supervised_wait_status
holder_pid=""
(( rollback_status != 0 )) || fail_case "first-candidate score failure unexpectedly succeeded"
grep -q 'restoring last accepted calibration constants' "$holder_log" \
  || fail_case "candidate failure did not report rollback"
real_rollback_after=$(rules_checksum)
fixture_rollback_after=$(shasum -a 256 "$rollback_rules/MatchupRules.swift" | awk '{print $1}')
[[ "$real_rollback_after" == "$real_rollback_before" ]] \
  || fail_case "candidate rollback changed tracked MatchupRules.swift"
[[ "$fixture_rollback_after" == "$fixture_rollback_before" ]] \
  || fail_case "candidate rollback left a trial constant in its isolated fixture"
pass_case "first-candidate failure rolls back while owner lock excludes contenders"
printf '      tracked checksum %s -> %s -> %s\n' \
  "$real_rollback_before" "$real_rollback_during" "$real_rollback_after"
printf '      fixture checksum %s -> %s -> %s\n' \
  "$fixture_rollback_before" "$fixture_rollback_during" "$fixture_rollback_after"

expect_success "ordinary search child sees a closed lock descriptor" env \
  TUNE_CALIBRATION_TEST_CHILD_FD=1 /bin/bash "$tuner"
grep -q 'closed for child (EBADF)' "$case_log" \
  || fail_case "ordinary child did not observe EBADF"
expect_success "re-entry validation descendant sees a closed lock descriptor" env \
  TUNE_CALIBRATION_TEST_REENTRY_FD=1 TUNE_CALIBRATION_TEST_LOCK_ONLY=1 /bin/bash "$tuner"
grep -q 're-entry validation descendant closed advisory lock descriptor (EBADF)' "$case_log" \
  || fail_case "re-entry validation descendant did not observe EBADF"
expect_success "recursive tuner cannot inherit or reacquire the owner lock" env \
  TUNE_CALIBRATION_TEST_RECURSIVE_CHILD=1 /bin/bash "$tuner"
grep -q 'another tuner holds the advisory lock' "$case_log" \
  || fail_case "recursive tuner did not contend on the owner lock"

env TUNE_CALIBRATION_TEST_HOLD_LOCK=1 TUNE_CALIBRATION_TEST_HOLD_SECONDS=2 \
  /bin/bash "$tuner" >"$holder_log" 2>&1 &
holder_pid=$!
holder_ready=0
attempt=0
while (( attempt < 100 )); do
  if grep -q 'test lockless helper pid=' "$holder_log"; then
    holder_ready=1
    break
  fi
  sleep 0.05
  ((attempt += 1))
done
if (( holder_ready != 1 )); then
  terminate_and_reap_pid "$holder_pid" || true
  holder_pid=""
  fail_case "lock holder did not become ready before its deadline"
fi
if env TUNE_CALIBRATION_TEST_LOCK_ONLY=1 /bin/bash "$tuner" >"$contender_log" 2>&1; then
  fail_case "contender acquired the held advisory lock"
fi
grep -q 'another tuner holds the advisory lock' "$contender_log" \
  || fail_case "contender failure did not identify lock ownership"
pass_case "holder excludes a contender while its lockless helper runs"
if ! bounded_reap_pid "$holder_pid" 100; then
  terminate_and_reap_pid "$holder_pid" || true
  holder_pid=""
  fail_case "lock holder exceeded its completion deadline"
fi
holder_status=$supervised_wait_status
holder_pid=""
(( holder_status == 0 )) || fail_case "lock holder failed"
expect_success "advisory lock is reacquirable after owner exit" env \
  TUNE_CALIBRATION_TEST_LOCK_ONLY=1 /bin/bash "$tuner"

printf 'public static let probe = 1\n' > "$fixture_rules/MatchupRules.swift"
fixture_before=$(shasum -a 256 "$fixture_rules/MatchupRules.swift" | awk '{print $1}')
ln -s "$fixture_rules" "$fixture_root/rules-link"
expect_failure "anchored replacement refuses a symlinked parent" env \
  TUNE_CALIBRATION_TEST_SETVAL=1 \
  TUNE_CALIBRATION_TEST_RULES_DIR="$fixture_root/rules-link" \
  TUNE_CALIBRATION_TEST_RULES_TARGET=MatchupRules.swift \
  TUNE_CALIBRATION_TEST_RULES_NAME=probe \
  TUNE_CALIBRATION_TEST_RULES_VALUE=2 \
  /bin/bash "$tuner"
fixture_after=$(shasum -a 256 "$fixture_rules/MatchupRules.swift" | awk '{print $1}')
[[ "$fixture_after" == "$fixture_before" ]] \
  || fail_case "symlinked parent test changed its anchored target"

mv "$fixture_rules/MatchupRules.swift" "$fixture_rules/referent.swift"
ln -s referent.swift "$fixture_rules/MatchupRules.swift"
expect_failure "anchored replacement refuses a symlinked target" env \
  TUNE_CALIBRATION_TEST_SETVAL=1 \
  TUNE_CALIBRATION_TEST_RULES_DIR="$fixture_rules" \
  TUNE_CALIBRATION_TEST_RULES_TARGET=MatchupRules.swift \
  TUNE_CALIBRATION_TEST_RULES_NAME=probe \
  TUNE_CALIBRATION_TEST_RULES_VALUE=2 \
  /bin/bash "$tuner"
[[ $(< "$fixture_rules/referent.swift") == 'public static let probe = 1' ]] \
  || fail_case "symlinked target test changed its referent"
rm -f -- "$fixture_rules/MatchupRules.swift"
mv "$fixture_rules/referent.swift" "$fixture_rules/MatchupRules.swift"

replacement_content="attacker replacement"
expect_failure "anchored replacement refuses changed target identity" env \
  TUNE_CALIBRATION_TEST_SETVAL=1 \
  TUNE_CALIBRATION_TEST_RULES_DIR="$fixture_rules" \
  TUNE_CALIBRATION_TEST_RULES_TARGET=MatchupRules.swift \
  TUNE_CALIBRATION_TEST_RULES_NAME=probe \
  TUNE_CALIBRATION_TEST_RULES_VALUE=2 \
  TUNE_CALIBRATION_TEST_REPLACE_TARGET=1 \
  TUNE_CALIBRATION_TEST_REPLACEMENT_CONTENT="$replacement_content" \
  /bin/bash "$tuner"
[[ $(< "$fixture_rules/MatchupRules.swift") == "$replacement_content" ]] \
  || fail_case "changed-target fixture was overwritten by the trial constant"
if compgen -G "$fixture_rules/.MatchupRules.swift.*" >/dev/null; then
  fail_case "anchored replacement left a temporary file after refusal"
fi

printf 'public static let probe = 1\n' > "$fixture_rules/MatchupRules.swift"
expect_success "anchored replacement updates an unchanged regular target" env \
  TUNE_CALIBRATION_TEST_SETVAL=1 \
  TUNE_CALIBRATION_TEST_RULES_DIR="$fixture_rules" \
  TUNE_CALIBRATION_TEST_RULES_TARGET=MatchupRules.swift \
  TUNE_CALIBRATION_TEST_RULES_NAME=probe \
  TUNE_CALIBRATION_TEST_RULES_VALUE=2 \
  /bin/bash "$tuner"
grep -q '^public static let probe = 2$' "$fixture_rules/MatchupRules.swift" \
  || fail_case "anchored replacement did not write the requested value"

final_rules_checksum=$(rules_checksum)
[[ "$final_rules_checksum" == "$initial_rules_checksum" ]] \
  || fail_case "calibration-tool gate changed retained MatchupRules.swift constants"
(( passes == 23 )) || fail_case "calibration-tool contract count drifted from 23 to ${passes}"
printf '\ncalibration tool contracts: %s passed, 0 failed\n' "$passes"
