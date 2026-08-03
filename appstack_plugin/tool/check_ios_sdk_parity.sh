#!/usr/bin/env bash
# Verifies the two iOS integration paths ship the same native SDK build.
#
# The plugin delivers the Appstack iOS SDK twice:
#
#   * SwiftPM (Flutter 3.44+)  — ios/appstack_plugin/Package.swift pins a tag
#   * CocoaPods (older Flutter) — ios/AppstackSDK.xcframework is vendored in git
#
# Nothing forces those to agree, and they silently diverged once: 2.4.0 shipped
# a 4.4.0-rc0 XCFramework against an `exact: "4.4.0"` pin. The public
# .swiftinterface was unchanged, so every build, lint and test stayed green.
#
# This check closes that gap by going back to the source of truth. Upstream
# publishes the SDK as a SwiftPM `binaryTarget`, so each tag has a release zip
# plus a checksum committed in upstream's own Package.swift. We resolve the
# pinned tag, download that exact artifact, verify its checksum, and compare it
# against the vendored tree.
#
# Design rule: this script must FAIL, never silently pass. Every parse step is
# checked and every unexpected condition is fatal. A reformatted manifest, a
# moved release asset or a network blip has to break the build — a check that
# quietly no-ops is worse than no check at all, because it reads as a guarantee.
#
# Usage:  bash appstack_plugin/tool/check_ios_sdk_parity.sh
# Exit:   0 = in sync, 1 = drift or any step that could not be verified.

set -euo pipefail

# Repo-relative paths, resolved from this script's location so the check runs
# from any working directory.
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
readonly PACKAGE_SWIFT="$PLUGIN_DIR/ios/appstack_plugin/Package.swift"
readonly VENDORED_XCFRAMEWORK="$PLUGIN_DIR/ios/AppstackSDK.xcframework"

readonly UPSTREAM_REPO="appstack-tech/ios-appstack-sdk"
readonly UPSTREAM_RAW="https://raw.githubusercontent.com/$UPSTREAM_REPO"

# Expected logical file count is deliberately not hardcoded — slice layout can
# legitimately change between SDK versions. Content parity is the invariant.

die() {
  echo "" >&2
  echo "FAIL: $*" >&2
  exit 1
}

log() { echo "==> $*"; }

WORKDIR=""
cleanup() { [[ -n "$WORKDIR" && -d "$WORKDIR" ]] && rm -rf "$WORKDIR"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

for tool in curl shasum; do
  command -v "$tool" >/dev/null 2>&1 || die "required tool '$tool' not found on PATH."
done

[[ -f "$PACKAGE_SWIFT" ]] \
  || die "plugin Package.swift not found at $PACKAGE_SWIFT"
[[ -d "$VENDORED_XCFRAMEWORK" ]] \
  || die "vendored XCFramework not found at $VENDORED_XCFRAMEWORK"

# ---------------------------------------------------------------------------
# 1. Which SDK version does the plugin pin?
# ---------------------------------------------------------------------------
# Matches:  .package(url: "…/ios-appstack-sdk.git", exact: "4.4.0"),
# An `exact:` pin is required on purpose. A range ("from:", "upToNextMinor")
# cannot be reconciled with a single vendored binary, so we refuse to guess.

log "Reading pinned SDK version from ${PACKAGE_SWIFT#"$PLUGIN_DIR"/}"

# `|| true` so a no-match falls through to the diagnostic below instead of being
# killed by `set -e`/`pipefail` with no explanation. Every such extraction is
# followed by an explicit emptiness check that exits non-zero — the tolerance is
# about producing a useful message, never about passing.
SDK_VERSION="$(
  sed -nE 's|.*ios-appstack-sdk\.git"[[:space:]]*,[[:space:]]*exact:[[:space:]]*"([^"]+)".*|\1|p' \
    "$PACKAGE_SWIFT" | head -n 1
)" || true

if [[ -z "$SDK_VERSION" ]]; then
  echo "" >&2
  echo "Could not find an \`exact:\` version pin for $UPSTREAM_REPO in:" >&2
  echo "  $PACKAGE_SWIFT" >&2
  echo "" >&2
  echo "Dependency lines found:" >&2
  grep -nE '\.package\(' "$PACKAGE_SWIFT" >&2 || echo "  (none)" >&2
  echo "" >&2
  echo "If the pin moved to a version range, the vendored XCFramework can no" >&2
  echo "longer be checked against it — restore an \`exact:\` pin, or update this" >&2
  echo "script deliberately." >&2
  die "unable to determine the pinned SDK version."
fi

log "Pinned iOS SDK version: $SDK_VERSION"

# Constrain the tag before it reaches a URL. Upstream tags look like 4.4.0 or
# 4.4.0-rc1; anything else is a parse failure, not something to fetch.
if ! printf '%s' "$SDK_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
  die "pinned version '$SDK_VERSION' is not a plain SemVer tag — refusing to build a URL from it."
fi

# ---------------------------------------------------------------------------
# 2. What artifact does that tag publish, and with what checksum?
# ---------------------------------------------------------------------------

WORKDIR="$(mktemp -d)"
readonly UPSTREAM_PACKAGE_SWIFT="$WORKDIR/upstream-Package.swift"
readonly UPSTREAM_PACKAGE_URL="$UPSTREAM_RAW/$SDK_VERSION/Package.swift"

log "Fetching upstream Package.swift at tag $SDK_VERSION"

curl -fsSL --retry 3 --retry-delay 2 --max-time 60 \
  -o "$UPSTREAM_PACKAGE_SWIFT" "$UPSTREAM_PACKAGE_URL" \
  || die "could not fetch $UPSTREAM_PACKAGE_URL
       Either tag '$SDK_VERSION' does not exist upstream, or the network is
       unavailable. This is fatal on purpose — an unreachable source of truth
       must not be reported as parity."

# Pull the binaryTarget's url + checksum. Tolerant of whitespace and line
# breaks, but not of absence — or of ambiguity. The two fields are matched
# independently, so more than one candidate for either means we could pair a url
# with another target's checksum. That would still fail closed at the checksum
# step, but it would blame a supply-chain mismatch for what is really an
# unrecognised manifest, so refuse to guess and say so.
UPSTREAM_ZIP_URLS="$(
  sed -nE 's/.*url:[[:space:]]*"(https:\/\/[^"]*\.zip)".*/\1/p' "$UPSTREAM_PACKAGE_SWIFT"
)" || true
UPSTREAM_CHECKSUMS="$(
  sed -nE 's/.*checksum:[[:space:]]*"([0-9a-fA-F]{64})".*/\1/p' "$UPSTREAM_PACKAGE_SWIFT"
)" || true

# grep -c rather than wc -l: an empty string must count as 0, not 1.
URL_COUNT="$(printf '%s' "$UPSTREAM_ZIP_URLS" | grep -c . || true)"
CHECKSUM_COUNT="$(printf '%s' "$UPSTREAM_CHECKSUMS" | grep -c . || true)"

if [[ "$URL_COUNT" -gt 1 || "$CHECKSUM_COUNT" -gt 1 ]]; then
  echo "" >&2
  echo "Upstream Package.swift at tag $SDK_VERSION declares more than one remote" >&2
  echo "binaryTarget field, so the url and checksum cannot be paired reliably." >&2
  echo "" >&2
  echo "  urls found ($URL_COUNT):" >&2
  printf '%s\n' "$UPSTREAM_ZIP_URLS" | sed 's/^/    /' >&2
  echo "  checksums found ($CHECKSUM_COUNT):" >&2
  printf '%s\n' "$UPSTREAM_CHECKSUMS" | sed 's/^/    /' >&2
  echo "" >&2
  echo "Update this script to select the correct target deliberately." >&2
  die "ambiguous binaryTarget manifest for $SDK_VERSION."
fi

UPSTREAM_ZIP_URL="$UPSTREAM_ZIP_URLS"
UPSTREAM_CHECKSUM="$UPSTREAM_CHECKSUMS"

if [[ -z "$UPSTREAM_ZIP_URL" || -z "$UPSTREAM_CHECKSUM" ]]; then
  echo "" >&2
  echo "Could not extract the binaryTarget url and/or checksum from upstream's" >&2
  echo "Package.swift at tag $SDK_VERSION ($UPSTREAM_PACKAGE_URL)." >&2
  echo "" >&2
  echo "  url found:      ${UPSTREAM_ZIP_URL:-<none>}" >&2
  echo "  checksum found: ${UPSTREAM_CHECKSUM:-<none>}" >&2
  echo "" >&2
  echo "Fetched contents:" >&2
  sed -n '1,80p' "$UPSTREAM_PACKAGE_SWIFT" >&2
  echo "" >&2
  echo "Upstream may have restructured its manifest (e.g. switched away from a" >&2
  echo "remote binaryTarget). Update this script to match before releasing." >&2
  die "unable to determine the official artifact for $SDK_VERSION."
fi

log "Official artifact: $UPSTREAM_ZIP_URL"
log "Expected sha256:   $UPSTREAM_CHECKSUM"

# ---------------------------------------------------------------------------
# 3. Download the artifact and verify its checksum
# ---------------------------------------------------------------------------
# The checksum in Package.swift covers the ZIP, not the extracted .xcframework,
# so it can only be verified here — hashing the vendored directory and
# comparing against it would be meaningless.

readonly ZIP_PATH="$WORKDIR/AppstackSDK.xcframework.zip"

log "Downloading official artifact"
curl -fsSL --retry 3 --retry-delay 2 --max-time 600 \
  -o "$ZIP_PATH" "$UPSTREAM_ZIP_URL" \
  || die "could not download $UPSTREAM_ZIP_URL
       The release asset may have been renamed, moved or removed. Fatal on
       purpose: parity cannot be asserted without the artifact."

ACTUAL_CHECKSUM="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
[[ -n "$ACTUAL_CHECKSUM" ]] || die "could not compute a sha256 for the downloaded zip."

# Compare case-insensitively. A SHA256 hex digest is the same value in either
# case, but `shasum` always prints lowercase while the manifest regex accepts
# [0-9a-fA-F] — so an uppercase digest upstream would otherwise be reported as a
# supply-chain failure on a perfectly good artifact. `tr` rather than ${var,,}
# because macOS ships bash 3.2 as /bin/bash.
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

if [[ "$(lower "$ACTUAL_CHECKSUM")" != "$(lower "$UPSTREAM_CHECKSUM")" ]]; then
  echo "" >&2
  echo "Checksum mismatch on the downloaded release artifact." >&2
  echo "  url:      $UPSTREAM_ZIP_URL" >&2
  echo "  expected: $UPSTREAM_CHECKSUM  (from upstream Package.swift @ $SDK_VERSION)" >&2
  echo "  actual:   $ACTUAL_CHECKSUM" >&2
  echo "" >&2
  echo "The release asset does not match the checksum upstream committed for it." >&2
  echo "Treat this as a supply-chain problem, not a flaky download: a mutated" >&2
  echo "release asset would let an unverified binary into the plugin." >&2
  die "artifact checksum verification failed."
fi

log "Checksum verified"

# ---------------------------------------------------------------------------
# 4. Extract
# ---------------------------------------------------------------------------
# Prefer ditto on macOS: the system unzip does not faithfully restore symlinked
# framework bundles. Fall back to unzip elsewhere (Linux CI) — Info-ZIP handles
# symlinks correctly, and the comparison below is symlink-agnostic regardless.

readonly EXTRACT_DIR="$WORKDIR/official"
mkdir -p "$EXTRACT_DIR"

log "Extracting artifact"
if command -v ditto >/dev/null 2>&1; then
  ditto -x -k "$ZIP_PATH" "$EXTRACT_DIR" \
    || die "ditto failed to extract $ZIP_PATH"
elif command -v unzip >/dev/null 2>&1; then
  unzip -qq "$ZIP_PATH" -d "$EXTRACT_DIR" \
    || die "unzip failed to extract $ZIP_PATH"
else
  die "neither 'ditto' nor 'unzip' available to extract the artifact."
fi

# Locate the .xcframework inside the extraction rather than assuming a layout.
# Depth-limited so a nested framework bundle can't be mistaken for the root.
OFFICIAL_XCFRAMEWORKS="$(
  find "$EXTRACT_DIR" -maxdepth 3 -type d -name '*.xcframework' 2>/dev/null \
    | LC_ALL=C sort
)" || true

if [[ -z "$OFFICIAL_XCFRAMEWORKS" ]]; then
  echo "" >&2
  echo "No .xcframework found in the extracted artifact. Top-level contents:" >&2
  find "$EXTRACT_DIR" -maxdepth 2 -mindepth 1 >&2
  die "unexpected artifact layout for $SDK_VERSION."
fi

# Exactly one, or we bail. Picking the first of several would compare an
# arbitrary bundle and could report parity against the wrong artifact.
XCFRAMEWORK_COUNT="$(printf '%s' "$OFFICIAL_XCFRAMEWORKS" | grep -c . || true)"
if [[ "$XCFRAMEWORK_COUNT" -ne 1 ]]; then
  echo "" >&2
  echo "Expected exactly one .xcframework in the $SDK_VERSION artifact, found $XCFRAMEWORK_COUNT:" >&2
  printf '%s\n' "$OFFICIAL_XCFRAMEWORKS" | sed "s|$EXTRACT_DIR/||" | sed 's/^/    /' >&2
  echo "" >&2
  echo "Update this script to select the right bundle deliberately." >&2
  die "ambiguous artifact layout for $SDK_VERSION."
fi

OFFICIAL_XCFRAMEWORK="$OFFICIAL_XCFRAMEWORKS"

# ---------------------------------------------------------------------------
# 5. Compare the official tree against the vendored one
# ---------------------------------------------------------------------------
# Compared as a canonical manifest of "sha256  relative-path" over
# `find -L -type f`, rather than with `diff -r`.
#
# `-L` follows symlinks, which is what makes the two sides comparable at all.
# Upstream's zip stores the maccatalyst framework flattened, while a framework
# bundle on disk may use the canonical symlink layout
# (AppstackSDK -> Versions/Current/AppstackSDK, Headers, Modules, Resources,
# Versions/Current -> A). Those describe the same logical tree, but a naive
# `diff -r` reports bogus "Only in" entries for ~24 files and can abort with
# "Directory loop detected". Following symlinks on both sides normalizes them.
#
# Note this compares content only. The top-level Info.plist lists
# `AvailableLibraries` in an order that is not stable between copies, so a
# byte-compare of that one file can fail even when the slices are equivalent.
# Vendoring the zip contents verbatim (see XCFRAMEWORK_UPDATE.md) keeps it
# byte-identical; if it ever shows up as the *only* difference, compare the
# parsed plists before assuming a real drift.

manifest() {
  # Print "sha256  path" for every file, paths relative to $1, sorted stably.
  # Fails loudly rather than emitting a short manifest.
  local root="$1" out="$2"

  # A dangling symlink matches neither `-type f` (nothing to follow) nor its
  # target, so it would drop out of the manifest entirely — and a stray one
  # present only in the vendored tree would then let both manifests agree while
  # the trees differ. Under `-L`, `-type l` matches *only* broken links (valid
  # ones resolve to their target's type), so this does not fire on the canonical
  # symlinked framework layout.
  local broken
  broken="$( cd "$root" && find -L . -type l -print )" \
    || die "could not scan for broken symlinks in $root"
  if [[ -n "$broken" ]]; then
    echo "" >&2
    echo "Broken symlink(s) under $root:" >&2
    printf '%s\n' "$broken" | sed 's|^\./|    |' >&2
    die "cannot assert parity for a tree containing broken symlinks."
  fi

  ( cd "$root" \
      && find -L . -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256 \
      | sed 's|  \./|  |' ) > "$out" \
    || die "could not build a file manifest for $root"
  [[ -s "$out" ]] || die "empty file manifest for $root — nothing was compared."
}

readonly OFFICIAL_MANIFEST="$WORKDIR/manifest-official.txt"
readonly VENDORED_MANIFEST="$WORKDIR/manifest-vendored.txt"

log "Comparing vendored XCFramework against the official $SDK_VERSION artifact"
manifest "$OFFICIAL_XCFRAMEWORK" "$OFFICIAL_MANIFEST"
manifest "$VENDORED_XCFRAMEWORK" "$VENDORED_MANIFEST"

OFFICIAL_COUNT="$(wc -l < "$OFFICIAL_MANIFEST" | tr -d ' ')"
VENDORED_COUNT="$(wc -l < "$VENDORED_MANIFEST" | tr -d ' ')"
log "Logical files: $OFFICIAL_COUNT official / $VENDORED_COUNT vendored"

if diff -q "$OFFICIAL_MANIFEST" "$VENDORED_MANIFEST" >/dev/null 2>&1; then
  echo ""
  echo "PASS: vendored AppstackSDK.xcframework matches the official $SDK_VERSION release."
  echo "      artifact: $UPSTREAM_ZIP_URL"
  echo "      sha256:   $UPSTREAM_CHECKSUM"
  echo "      $OFFICIAL_COUNT files compared, all identical."
  exit 0
fi

# Drift. Report which paths differ and how — "trees differ" is not actionable.
echo "" >&2
echo "The vendored XCFramework does not match the official $SDK_VERSION release." >&2
echo "" >&2
echo "  pinned version: $SDK_VERSION  (ios/appstack_plugin/Package.swift)" >&2
echo "  official:       $UPSTREAM_ZIP_URL" >&2
echo "  vendored:       ${VENDORED_XCFRAMEWORK#"$PLUGIN_DIR"/}" >&2
echo "" >&2

# Content differences: same path, different hash.
CHANGED="$(
  LC_ALL=C join -j 2 \
    <(LC_ALL=C sort -k2,2 "$OFFICIAL_MANIFEST") \
    <(LC_ALL=C sort -k2,2 "$VENDORED_MANIFEST") \
    | awk '$2 != $3 {print $1}' \
    | LC_ALL=C sort
)"
if [[ -n "$CHANGED" ]]; then
  echo "  Files whose contents differ ($(printf '%s\n' "$CHANGED" | wc -l | tr -d ' ')):" >&2
  printf '%s\n' "$CHANGED" | sed 's/^/    M /' >&2
  echo "" >&2
fi

# Presence differences, keyed on path only.
ONLY_OFFICIAL="$(
  LC_ALL=C comm -23 \
    <(awk '{print $2}' "$OFFICIAL_MANIFEST" | LC_ALL=C sort) \
    <(awk '{print $2}' "$VENDORED_MANIFEST" | LC_ALL=C sort)
)"
ONLY_VENDORED="$(
  LC_ALL=C comm -13 \
    <(awk '{print $2}' "$OFFICIAL_MANIFEST" | LC_ALL=C sort) \
    <(awk '{print $2}' "$VENDORED_MANIFEST" | LC_ALL=C sort)
)"
if [[ -n "$ONLY_OFFICIAL" ]]; then
  echo "  Present in the official release but missing from the vendored copy:" >&2
  printf '%s\n' "$ONLY_OFFICIAL" | sed 's/^/    - /' >&2
  echo "" >&2
fi
if [[ -n "$ONLY_VENDORED" ]]; then
  echo "  Present in the vendored copy but not in the official release:" >&2
  printf '%s\n' "$ONLY_VENDORED" | sed 's/^/    + /' >&2
  echo "" >&2
fi

cat >&2 <<EOF
  SwiftPM users would get the official $SDK_VERSION binary while CocoaPods users
  get the vendored one. Fix by re-vendoring from the pinned release — the paths
  below are relative to the plugin directory, so run this from there:

    cd "$PLUGIN_DIR"
    curl -fsSL -o /tmp/AppstackSDK.xcframework.zip \\
      "$UPSTREAM_ZIP_URL"
    shasum -a 256 /tmp/AppstackSDK.xcframework.zip   # expect $UPSTREAM_CHECKSUM
    rm -rf "${VENDORED_XCFRAMEWORK#"$PLUGIN_DIR"/}"
    ditto -x -k /tmp/AppstackSDK.xcframework.zip "$(dirname "${VENDORED_XCFRAMEWORK#"$PLUGIN_DIR"/}")"

  See appstack_plugin/XCFRAMEWORK_UPDATE.md. If the intent was to move to a new
  SDK version, update the \`exact:\` pin and re-vendor in the same commit.
EOF

die "iOS SDK parity check failed."
