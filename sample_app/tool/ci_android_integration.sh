#!/usr/bin/env bash
# Runs the Android integration suite on the CI emulator while capturing logcat,
# then surfaces the Appstack SDK's own log lines (event POSTs, HTTP status codes)
# in the job output.
#
# This lives in a file rather than inline in the workflow because
# reactivecircus/android-emulator-runner executes its `script:` input one line
# at a time (each as a separate `sh -c`), which breaks shell state — background
# jobs, variables, and line continuations don't survive across lines. Invoking a
# single script keeps it all in one shell.
#
# Delivery is only observable when a real APPSTACK_API_KEY is provided; with the
# placeholder key the SDK reports itself disabled and the delivery test self-skips.
set -uo pipefail

adb logcat -c || true
adb logcat > "$RUNNER_TEMP/appstack-android.log" 2>&1 &
LOGCAT_PID=$!

TEST_RC=0
flutter test integration_test \
  --dart-define=APPSTACK_API_KEY="${APPSTACK_API_KEY:-integration-test-placeholder-key}" \
  || TEST_RC=$?

kill "$LOGCAT_PID" 2>/dev/null || true

echo "::group::Appstack SDK / event traffic (Android)"
grep -iE "AppstackSdk|okhttp|/android/v2/events|<-- 20[0-9]" \
  "$RUNNER_TEMP/appstack-android.log" \
  || echo "(no Appstack SDK log lines captured — is APPSTACK_API_KEY set?)"
echo "::endgroup::"

exit "$TEST_RC"
