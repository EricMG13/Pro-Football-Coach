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
cd "$(dirname "$0")/.." || exit 1

pass=0
fail=0
note() { printf '\n=== %s ===\n' "$1"; }
ok()   { printf 'PASS  %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf 'FAIL  %s\n' "$1"; fail=$((fail + 1)); }

note "toolchain"
if ! command -v swift >/dev/null 2>&1; then
    echo "swift not found on PATH."
    echo "This script must run where the toolchain is installed."
    echo "With swiftly: source ~/.swiftly/env.sh   (or open a new shell)"
    exit 127
fi
swift --version 2>&1 | head -2

# The package targets iOS 17 / macOS 14 and the UI target imports SwiftUI, so a
# host build needs the macOS SDK. swiftly supplies the compiler, not the SDK.
if [ "$(uname)" = "Darwin" ] && ! xcrun --show-sdk-path >/dev/null 2>&1; then
    echo
    echo "No macOS SDK found. Install the Command Line Tools first:"
    echo "  xcode-select --install"
    exit 127
fi

note "build"
if swift build 2>&1 | tee /tmp/pfc-build.log; then
    ok "swift build"
else
    bad "swift build — see /tmp/pfc-build.log"
    # A red build is expected at least once: Sources/FootballSimCore/Arcade/ has never
    # been compiled (no arcade symbol appears in the last artifact any compiler produced).
    # Grouping errors by directory says immediately whether that is where they live.
    note "errors by directory"
    grep -oE '^[^ :]+\.swift:[0-9]+:[0-9]+: error:' /tmp/pfc-build.log 2>/dev/null \
        | sed -E 's|/[^/]+\.swift.*||' | sort | uniq -c | sort -rn | head -20
    note "first 20 errors"
    grep -E ': error:' /tmp/pfc-build.log 2>/dev/null | head -20
    printf '\ntotal errors: %s\n' "$(grep -cE ': error:' /tmp/pfc-build.log 2>/dev/null || echo 0)"
    echo
    echo "Tests were not run. Paste the two sections above back into the session."
    exit 1
fi

if [ "${1:-}" = "--build" ]; then
    printf '\nbuild only: %s passed, %s failed\n' "$pass" "$fail"
    exit $((fail > 0))
fi

note "calibration tool contracts"
if ./scripts/test-calibration-tools.sh 2>&1 | tee /tmp/pfc-calibration-tools.log; then
    ok "calibration tool contracts"
else
    bad "calibration tool contracts — see /tmp/pfc-calibration-tools.log"
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
echo "Paste the tails of /tmp/pfc-build.log, /tmp/pfc-calibration-tools.log, and"
echo "/tmp/pfc-tests.log back into the session."
exit $((fail > 0))
