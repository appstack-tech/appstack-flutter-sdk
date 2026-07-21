#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_ROOT="$(cd "$APP_ROOT/../appstack_plugin" && pwd)"
MODE="${1:-}"
REQUESTED_DEVICE="${2:-}"

case "$MODE" in
  ios|android) ;;
  *)
    echo "Usage: $0 <ios|android> [device-id]" >&2
    exit 2
    ;;
esac

if [[ -n "${APPSTACK_RUNTIME_ARTIFACT_DIR:-}" ]]; then
  WORK_DIR="$APPSTACK_RUNTIME_ARTIFACT_DIR"
  mkdir -p "$WORK_DIR"
else
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/appstack-flutter-runtime-validation.XXXXXX")"
fi

PORT_FILE="$WORK_DIR/mock-port.txt"
TLS_PORT_FILE="$WORK_DIR/mock-tls-port.txt"
TLS_CERT="$WORK_DIR/mock-ca.pem"
TLS_KEY="$WORK_DIR/mock-ca-key.pem"
REQUESTS_FILE="$WORK_DIR/mock-requests.jsonl"
RUNTIME_LOG="$WORK_DIR/runtime.log"
VALIDATOR_LOG="$WORK_DIR/validator.log"
MOCK_LOG="$WORK_DIR/mock-server.log"
IOS_XCCONFIG="$APP_ROOT/ios/Flutter/RuntimeValidation.xcconfig"
ANDROID_GENERATED_ROOT="$APP_ROOT/android/app/src/runtimeValidationGenerated"

rm -f "$PORT_FILE" "$TLS_PORT_FILE" "$REQUESTS_FILE" "$RUNTIME_LOG" \
  "$VALIDATOR_LOG" "$MOCK_LOG"
: > "$REQUESTS_FILE"

mock_arguments=(
  --port-file "$PORT_FILE"
  --requests-file "$REQUESTS_FILE"
)
if [[ "$MODE" == "android" ]]; then
  openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 1 \
    -subj '/CN=127.0.0.1' \
    -addext 'subjectAltName=IP:127.0.0.1' \
    -keyout "$TLS_KEY" \
    -out "$TLS_CERT" \
    >/dev/null 2>&1
  mock_arguments+=(
    --tls-cert "$TLS_CERT"
    --tls-key "$TLS_KEY"
    --tls-port-file "$TLS_PORT_FILE"
  )
fi

python3 "$SCRIPT_DIR/runtime_validation/mock_server.py" "${mock_arguments[@]}" \
  > "$MOCK_LOG" 2>&1 &
mock_pid=$!
adb=""
serial=""
http_port=""
tls_port=""

cleanup() {
  if [[ -n "$adb" && -n "$serial" && -n "$http_port" ]]; then
    "$adb" -s "$serial" reverse --remove "tcp:$http_port" >/dev/null 2>&1 || true
  fi
  if [[ -n "$adb" && -n "$serial" && -n "$tls_port" ]]; then
    "$adb" -s "$serial" reverse --remove "tcp:$tls_port" >/dev/null 2>&1 || true
  fi
  kill "$mock_pid" >/dev/null 2>&1 || true
  wait "$mock_pid" >/dev/null 2>&1 || true
  rm -f "$IOS_XCCONFIG"
  rm -rf "$ANDROID_GENERATED_ROOT"
}
trap cleanup EXIT

for _ in {1..100}; do
  if [[ -s "$PORT_FILE" && ( "$MODE" == "ios" || -s "$TLS_PORT_FILE" ) ]]; then
    break
  fi
  sleep 0.1
done
if [[ ! -s "$PORT_FILE" ]]; then
  echo "Mock backend did not start; see $MOCK_LOG" >&2
  exit 1
fi
if [[ "$MODE" == "android" && ! -s "$TLS_PORT_FILE" ]]; then
  echo "Mock TLS attribution endpoint did not start; see $MOCK_LOG" >&2
  exit 1
fi

http_port="$(<"$PORT_FILE")"
proxy_url="http://127.0.0.1:$http_port"
target_device="$REQUESTED_DEVICE"

if [[ "$MODE" == "ios" ]]; then
  if [[ -z "$target_device" ]]; then
    target_device="${IOS_SIMULATOR_UDID:-}"
  fi
  if [[ -z "$target_device" ]]; then
    target_device="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
for devices in data["devices"].values():
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit(1)
')"
  fi
  xcrun simctl boot "$target_device" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$target_device" -b
  # xcconfig treats // as a comment delimiter. $() expands to an empty build
  # setting, preserving the two URL slashes without truncating the value.
  printf 'APPSTACK_DEV_PROXY_URL = http:/$()/127.0.0.1:%s\n' "$http_port" > "$IOS_XCCONFIG"
else
  if command -v adb >/dev/null 2>&1; then
    adb="$(command -v adb)"
  elif [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
    adb="$ANDROID_HOME/platform-tools/adb"
  elif [[ -n "${ANDROID_SDK_ROOT:-}" && -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
    adb="$ANDROID_SDK_ROOT/platform-tools/adb"
  else
    echo "adb not found; set ANDROID_HOME or put platform-tools on PATH" >&2
    exit 1
  fi

  serial="$target_device"
  if [[ -z "$serial" ]]; then
    serial="${ANDROID_SERIAL:-}"
  fi
  if [[ -z "$serial" ]]; then
    serial="$("$adb" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
  fi
  if [[ -z "$serial" ]]; then
    echo "No Android target is available; set ANDROID_SERIAL" >&2
    exit 1
  fi
  target_device="$serial"
  tls_port="$(<"$TLS_PORT_FILE")"

  generated_res="$ANDROID_GENERATED_ROOT/res"
  mkdir -p "$generated_res/raw" "$generated_res/xml"
  cp "$TLS_CERT" "$generated_res/raw/appstack_runtime_validation_ca.pem"
  cp "$SCRIPT_DIR/runtime_validation/network_security_config.xml" \
    "$generated_res/xml/appstack_runtime_validation_network_security_config.xml"

  export ORG_GRADLE_PROJECT_appstackRuntimeProxyUrl="$proxy_url"
  export ORG_GRADLE_PROJECT_appstackNetworkSecurityConfig="@xml/appstack_runtime_validation_network_security_config"
  "$adb" -s "$serial" reverse "tcp:$http_port" "tcp:$http_port"
  "$adb" -s "$serial" reverse "tcp:$tls_port" "tcp:$tls_port"
fi

export APPSTACK_RUNTIME_PROXY_URL="$proxy_url"
wrapper_version="flutter-$(awk '/^version:/ { print $2; exit }' "$PLUGIN_ROOT/pubspec.yaml")"
cd "$APP_ROOT"

echo "Hermetic runtime validation workspace: $WORK_DIR"
echo "Target: $MODE / $target_device"
echo "Local proxy: $proxy_url"

set +e
flutter test integration_test/appstack_sdk_integration_test.dart \
  --dart-define=APPSTACK_RUNTIME_VALIDATION=true \
  --dart-define=APPSTACK_RUNTIME_PROXY_URL="$proxy_url" \
  -d "$target_device" \
  2>&1 | tee "$RUNTIME_LOG"
test_rc=${PIPESTATUS[0]}
set -e
if [[ "$test_rc" -ne 0 ]]; then
  echo "Flutter runtime probe failed; diagnostics are in $WORK_DIR" >&2
  exit "$test_rc"
fi

python3 "$SCRIPT_DIR/runtime_validation/validate_runtime.py" \
  --runtime-log "$RUNTIME_LOG" \
  --requests-file "$REQUESTS_FILE" \
  --expected-wrapper-version "$wrapper_version" \
  2>&1 | tee "$VALIDATOR_LOG"

echo "Hermetic runtime validation passed for $MODE"
