#!/usr/bin/env bash
# Fails unless both native SDK pins name a released X.Y.Z version.
#
# develop may pin native release candidates: an Android -SNAPSHOT coordinate,
# or the iOS SDK's rolling `rc` branch (see XCFRAMEWORK_UPDATE.md). A stable
# plugin release must never ship either: a snapshot is mutable and expires,
# and a branch pin moves under integrators. release-pr.yml runs this before a
# release PR can merge, and publish.yml runs it again before publishing.
#
# Usage:  bash appstack_plugin/tool/check_release_pins.sh
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ANDROID_PIN="$(sed -n "s/^def appstackAndroidSdkVersion = '\([^']*\)'$/\1/p" "$PLUGIN_DIR/android/build.gradle")"
# The ios-appstack-sdk dependency line, whatever requirement it uses.
IOS_LINE="$(grep -E 'ios-appstack-sdk\.git' "$PLUGIN_DIR/ios/appstack_plugin/Package.swift" || true)"
IOS_PIN="$(sed -n 's/.*exact: "\([^"]*\)".*/\1/p' <<< "$IOS_LINE")"

status=0
if [[ ! "$ANDROID_PIN" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
  echo "::error::The Android SDK pin in android/build.gradle must be a released X.Y.Z version, found '${ANDROID_PIN:-<none>}'."
  status=1
fi
if [[ ! "$IOS_PIN" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
  echo "::error::The iOS SDK pin in ios/appstack_plugin/Package.swift must be exact: \"X.Y.Z\", found: ${IOS_LINE:-<no ios-appstack-sdk dependency>}"
  status=1
fi
[[ "$status" -eq 0 ]] && echo "Native pins: Android $ANDROID_PIN, iOS $IOS_PIN."
exit "$status"
