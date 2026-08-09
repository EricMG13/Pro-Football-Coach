#!/usr/bin/env bash
# Run the machine gates and print a result an agent can be handed back.
#
# Why this exists: D11(b). Agent environments here have no Swift toolchain
# (download.swift.org is refused by egress policy, 403 on CONNECT), so the owner's
# machine runs the gates. This script makes that one command instead of a ritual.
#
#   ./scripts/verify.sh          build + tests
#   ./scripts/verify.sh --build  build only
#
# Needs only the Swift Command Line Tools, not full Xcode: the suite is an executable
# target with a hand-rolled harness (Tests/SimTests/TestKit.swift), because neither
# XCTest nor swift-testing ships outside Xcode.

set -uo pipefail
cd "$(dirname "$0")/.."

pass=0
fail=0
note() { printf '\n=== %s ===\n' "$1"; }
ok()   { printf 'PASS  %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf 'FAIL  %s\n' "$1"; fail=$((fail + 1)); }

note "toolchain"
if ! command -v swift >/dev/null 2>&1; then
    echo "swift not found on PATH."
    echo "This script must run where the toolchain is installed."
    exit 127
fi
swift --version 2>&1 | head -2

note "build"
if swift build 2>&1 | tee /tmp/pfc-build.log; then
    ok "swift build"
else
    bad "swift build — see /tmp/pfc-build.log"
    echo
    echo "Build failed, so tests were not run. Paste the log back."
    exit 1
fi

if [ "${1:-}" = "--build" ]; then
    printf '\nbuild only: %s passed, %s failed\n' "$pass" "$fail"
    exit $((fail > 0))
fi

note "tests"
# The harness exits non-zero on failure and prints its own counts.
if swift run -c release SimTests 2>&1 | tee /tmp/pfc-tests.log; then
    ok "SimTests"
else
    bad "SimTests — see /tmp/pfc-tests.log"
fi

note "result"
printf '%s passed, %s failed\n' "$pass" "$fail"
echo
echo "Paste the tail of /tmp/pfc-build.log and /tmp/pfc-tests.log back into the session."
exit $((fail > 0))
