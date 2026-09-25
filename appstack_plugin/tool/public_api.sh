#!/usr/bin/env bash
# Keeps the committed public Dart API baseline honest.
#
# appstack_plugin/api/appstack_plugin.api.json is the dart_apitool model of
# everything an app can import from package:appstack_plugin — every library
# directly under lib/ (not only the barrel appstack_plugin.dart), plus the
# platform constraints and dependencies from pubspec.yaml, android/ and ios/.
# Apps compile against this surface, so every change to it is reviewed on
# purpose: test.yml runs `check`, and api-change-gate.yml requires a label on
# any PR that changes the baseline.
#
# dart_apitool runs `pub get` in the directory it is given and rewrites its
# analysis_options.yaml, and it records that directory's absolute path in the
# output. So we never point it at the working tree: each run extracts from a
# scratch copy, and the machine-specific fields are dropped before writing.
#
# Usage (from anywhere):
#   bash appstack_plugin/tool/public_api.sh dump        # rewrite the baseline
#   bash appstack_plugin/tool/public_api.sh check       # fail if it drifted
#   bash appstack_plugin/tool/public_api.sh diff <ref>  # classify changes vs a
#                                                       # git ref (markdown)
#
# Requires dart-apitool on PATH (see DART_APITOOL_VERSION below), jq and rsync.
# Maintainer docs: appstack_plugin/PUBLIC_API.md
# Exit: 0 = ok, 1 = drift or any step that failed.

set -euo pipefail

# test.yml reads this line to activate the same version. A different version
# can serialise the model differently and make `check` fail on an unchanged API.
readonly DART_APITOOL_VERSION="0.23.2"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
readonly REPO_DIR="$(dirname "$PLUGIN_DIR")"
readonly BASELINE="$PLUGIN_DIR/api/appstack_plugin.api.json"

die() {
  echo "" >&2
  echo "FAIL: $*" >&2
  exit 1
}

log() { echo "==> $*" >&2; }

WORKDIR=""
cleanup() { if [[ -n "$WORKDIR" ]]; then rm -rf "$WORKDIR"; fi; }
trap cleanup EXIT

require_tools() {
  command -v jq >/dev/null || die "jq is not installed."
  command -v dart-apitool >/dev/null \
    || die "dart-apitool is not on PATH. Run: dart pub global activate dart_apitool $DART_APITOOL_VERSION"
  local installed
  installed="$(dart-apitool --version 2>/dev/null | tr -d '[:space:]')"
  [[ "$installed" == "$DART_APITOOL_VERSION" ]] \
    || die "dart-apitool $installed is installed, expected $DART_APITOOL_VERSION. Run: dart pub global activate dart_apitool $DART_APITOOL_VERSION"
}

# Copies the plugin at $1 (the working tree) into $2, leaving out what the
# analysis never reads: build output, the example app (dart_apitool would
# resolve its dependencies too) and the vendored XCFramework.
copy_package() {
  mkdir -p "$2"
  rsync -a \
    --exclude '.dart_tool/' --exclude 'build/' --exclude 'example/' \
    --exclude 'api/' --exclude 'ios/AppstackSDK.xcframework/' \
    "$1/" "$2/"
}

# Extracts the API of the package directory $1 into the normalised file $2.
# packagePath is a temp dir; packageVersion stays 0.0.1 in git and is only
# stamped by publish.yml, so neither says anything about the API.
extract() {
  local raw="$WORKDIR/raw.api.json"
  dart-apitool extract --input "$1" --output "$raw" --set-exit-on-missing-export >&2 \
    || die "dart-apitool extract failed (see output above)."
  jq --indent 2 'del(.packageApi.packagePath, .packageApi.packageVersion)' "$raw" > "$2" \
    || die "could not normalise $raw."
}

cmd_dump() {
  copy_package "$PLUGIN_DIR" "$WORKDIR/current"
  mkdir -p "$(dirname "$BASELINE")"
  extract "$WORKDIR/current" "$BASELINE"
  log "Wrote ${BASELINE#"$REPO_DIR"/}"
}

cmd_check() {
  [[ -f "$BASELINE" ]] || die "${BASELINE#"$REPO_DIR"/} is missing. Run: bash appstack_plugin/tool/public_api.sh dump"
  copy_package "$PLUGIN_DIR" "$WORKDIR/current"
  extract "$WORKDIR/current" "$WORKDIR/current.api.json"
  if ! diff -u --label "baseline (${BASELINE#"$REPO_DIR"/})" --label "lib/ (extracted)" \
      "$BASELINE" "$WORKDIR/current.api.json"; then
    die "The public Dart API no longer matches ${BASELINE#"$REPO_DIR"/}. If the change is intended, run 'bash appstack_plugin/tool/public_api.sh dump', commit the baseline and label the PR 'api-change' or 'breaking'. See appstack_plugin/PUBLIC_API.md."
  fi
  log "Public API matches the baseline."
}

# Writes a markdown report classifying every API change between git ref $1
# and the working tree as breaking or non-breaking.
cmd_diff() {
  local ref="${1:-}"
  [[ -n "$ref" ]] || die "usage: public_api.sh diff <git-ref>"
  git -C "$REPO_DIR" rev-parse --verify --quiet "$ref^{commit}" >/dev/null \
    || die "unknown git ref '$ref'."

  # Leave out what copy_package leaves out, so both sides are prepared the same.
  mkdir -p "$WORKDIR/old"
  git -C "$REPO_DIR" archive "$ref" -- appstack_plugin \
      ':!appstack_plugin/example' ':!appstack_plugin/api' \
      ':!appstack_plugin/ios/AppstackSDK.xcframework' \
    | tar -x -C "$WORKDIR/old" \
    || die "could not export appstack_plugin at $ref."
  copy_package "$PLUGIN_DIR" "$WORKDIR/new"

  # Versions are managed by publish.yml, not here: report, don't enforce.
  # --check-sdk-version reports a raised Dart SDK lower bound as breaking; it
  # is off by default.
  dart-apitool diff \
    --old "$WORKDIR/old/appstack_plugin" --new "$WORKDIR/new" \
    --version-check-mode none --check-sdk-version \
    --report-format markdown --report-file-path "$WORKDIR/report.md" >&2 \
    || die "dart-apitool diff failed (see output above)."
  # Drop the tool-info header: it only names the temp dirs and a timestamp.
  sed -n '/^## Report/,$p' "$WORKDIR/report.md"
}

main() {
  local cmd="${1:-}"
  shift || true
  require_tools
  WORKDIR="$(mktemp -d)"
  case "$cmd" in
    dump)  cmd_dump ;;
    check) cmd_check ;;
    diff)  cmd_diff "$@" ;;
    *)     die "usage: public_api.sh dump | check | diff <git-ref>" ;;
  esac
}

main "$@"
