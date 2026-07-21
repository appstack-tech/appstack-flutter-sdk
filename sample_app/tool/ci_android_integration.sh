#!/usr/bin/env bash
# Runs Android's build/link and hermetic runtime checks on the CI emulator while
# capturing logcat, then surfaces the Appstack SDK's own diagnostic lines.
#
# This lives in a file rather than inline in the workflow because
# reactivecircus/android-emulator-runner executes its `script:` input one line
# at a time (each as a separate `sh -c`), which breaks shell state — background
# jobs, variables, and line continuations don't survive across lines. Invoking a
# single script keeps it all in one shell.
#
set -uo pipefail

adb logcat -c || true
adb logcat > "$RUNNER_TEMP/appstack-android.log" 2>&1 &
LOGCAT_PID=$!

TEST_RC=0
export APPSTACK_RUNTIME_ARTIFACT_DIR="${APPSTACK_RUNTIME_ARTIFACT_DIR:-$RUNNER_TEMP/appstack-runtime-validation/android}"
bash tool/run_runtime_validation.sh android || TEST_RC=$?

kill "$LOGCAT_PID" 2>/dev/null || true

echo "::group::Appstack SDK / event traffic (Android)"
grep -iE "AppstackSdk|okhttp|/android/v2/events|<-- 20[0-9]" \
  "$RUNNER_TEMP/appstack-android.log" \
  || echo "(no Appstack SDK log lines captured)"
echo "::endgroup::"

exit "$TEST_RC"
