#!/usr/bin/env bash
# Run reproducible release lanes with isolated SwiftPM/Xcode scratch directories.
#
#   ./scripts/verify.sh                 full package lane
#   ./scripts/verify.sh --lane core     core contracts
#   ./scripts/verify.sh --lane app      XcodeGen + generic iOS build
#   ./scripts/verify.sh --build         full package build only
#
# The default lane remains the historical build + complete SimTests run. Named lanes keep their
# own logs and scratch paths so a failed calibration or archive cannot contaminate another run.

set -euo pipefail
cd "$(dirname "$0")/.."

lane="full"
build_only=false
keep_scratch="${PFC_VERIFY_KEEP_SCRATCH:-0}"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --build) build_only=true; shift ;;
        --lane=*) lane="${1#*=}"; shift ;;
        --lane)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                printf '%s\n' "--lane requires a value" >&2
                exit 2
            fi
            lane="$2"
            shift 2
            ;;
        --keep-scratch) keep_scratch=1; shift ;;
        -h|--help)
            sed -n '1,18p' "$0"
            exit 0
            ;;
        *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

case "$lane" in
    accessibility|app|archive|calibration|core|determinism|full|release|soaks) ;;
    *) printf 'unknown lane: %s\n' "$lane" >&2; exit 2 ;;
esac

if ! command -v swift >/dev/null 2>&1; then
    echo "swift not found on PATH."
    exit 127
fi
if [ "$(uname)" = "Darwin" ] && ! xcrun --show-sdk-path >/dev/null 2>&1; then
    echo "No macOS SDK found. Install the Command Line Tools first."
    exit 127
fi

verify_root="$(mktemp -d "${TMPDIR:-/tmp}/pfc-verify.XXXXXX")"
if [ -z "$verify_root" ] || [ ! -d "$verify_root" ]; then
    echo "Could not create an isolated verification directory." >&2
    exit 1
fi
cleanup() {
    if [ "$keep_scratch" != "1" ]; then
        rm -rf -- "${verify_root:?}"
    else
        printf 'verification artifacts: %s\n' "$verify_root"
    fi
}
trap cleanup EXIT

lane_root="$verify_root/$lane"
mkdir -p "$lane_root/scratch" "$lane_root/logs"
pass=0
fail=0
note() { printf '\n=== %s ===\n' "$1"; }
ok() { printf 'PASS  %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL  %s\n' "$1"; fail=$((fail + 1)); }

run_command() {
    local label="$1"
    shift
    local log="$lane_root/logs/$label.log"
    if "$@" 2>&1 | tee "$log"; then
        ok "$label"
    else
        bad "$label — see $log"
        return 1
    fi
}

run_sim() {
    local label="$1"
    shift
    # SimTests is a plain executable target that @testable imports ProFootballCoachUI (03b section
    # 5: "the ported TestKit harness, run as an executable target" -- not a recognised .testTarget,
    # so SwiftPM has no reason to infer testability the way `swift test` would). -c release does not
    # enable it by default the way debug builds happen to, so a release run fails every target that
    # @testable imports anything with "module ... was not compiled for testing" unless asked for
    # explicitly.
    run_command "$label" swift run --scratch-path "$lane_root/scratch" -c release \
        -Xswiftc -enable-testing SimTests "$@"
}

note "toolchain"
swift --version 2>&1 | head -2

case "$lane" in
    core)
        run_sim core-contracts --core-contracts
        ;;
    determinism)
        run_sim architecture --architecture-only
        run_sim competition --competition-only
        ;;
    calibration)
        run_sim calibration --calibration
        run_sim m3-recruiting-calibration --m3-recruiting-calibration
        ;;
    soaks)
        run_sim college-soak --m1-soak
        run_sim pro-soak --m2-soak
        ;;
    accessibility)
        run_sim design-contracts --design-contracts
        run_sim reduce-motion --reduce-motion
        run_sim read-models --screen-read-models
        run_sim smallest-device-layout --smallest-device-layout
        ;;
    archive)
        run_sim history-archive --history-archive
        run_sim history-gate --m7-gate
        ;;
    release)
        run_sim catalog --catalog
        run_sim commitment-coverage --commitment-coverage
        run_sim save-document --save-document
        ;;
    app)
        command -v xcodegen >/dev/null 2>&1 || {
            echo "xcodegen not found on PATH." >&2
            exit 127
        }
        command -v xcodebuild >/dev/null 2>&1 || {
            echo "xcodebuild not found on PATH." >&2
            exit 127
        }
        package_root="$verify_root/pro-football-coach"
        project_root="$package_root/App"
        mkdir -p "$project_root"
        cp Package.swift "$package_root/Package.swift"
        cp -R Sources "$package_root/Sources"
        project="$project_root/ProFootballCoach.xcodeproj"
        run_command xcodegen xcodegen generate --spec App/project.yml --project "$project_root"
        run_command xcodebuild xcodebuild \
            -project "$project" \
            -scheme ProFootballCoach \
            -configuration Debug \
            -destination 'generic/platform=iOS' \
            -derivedDataPath "$lane_root/derived-data" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            build
        ;;
    full)
        # -enable-testing for the same reason run_sim needs it: an unfiltered `swift build` also
        # builds SimTests, which @testable imports ProFootballCoachUI.
        run_command build swift build --scratch-path "$lane_root/scratch" -c release \
            -Xswiftc -enable-testing
        if [ "$build_only" = true ]; then
            printf '\n%s passed, %s failed\n' "$pass" "$fail"
            exit "$((fail > 0))"
        fi
        run_sim full
        ;;
esac

printf '\n%s passed, %s failed\n' "$pass" "$fail"
exit "$((fail > 0))"
