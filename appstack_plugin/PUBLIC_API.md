# Public API baseline

This document is for maintainers. Integrators should use [README.md](README.md).

`api/appstack_plugin.api.json` is the committed model of the plugin's public
Dart API, extracted by [dart_apitool](https://pub.dev/packages/dart_apitool).
Apps compile against this API, so every change to it is reviewed on purpose.

## What it covers

Everything an app can import from `package:appstack_plugin`. That is every
library directly under `lib/`, not only the `appstack_plugin.dart` barrel.
`appstack_plugin_platform_interface.dart` is public on purpose, as the seam
apps use to fake the plugin in tests. Implementation details belong in
`lib/src/`, which the baseline leaves out. It also records what `pub` and the native builds hold apps to:
the Dart SDK lower bound and dependency constraints from `pubspec.yaml`, the
Android `minSdkVersion`/`compileSdkVersion`/`targetSdkVersion`, and the iOS
minimum version.

The absolute package path and `version` are left out: the path is a temp dir,
and `version` stays `0.0.1` in git until `publish.yml` stamps it.

## CI

- **Test (`test.yml`)**, job *Public API baseline (Dart)*, re-extracts the API
  and fails when it no longer matches the baseline. On PRs it also runs
  `dart-apitool diff` against the base branch and writes the result, split
  into 🚨 breaking and non-breaking changes, to the job summary.
- **API change gate (`api-change-gate.yml`)** fails any PR that changes
  `api/appstack_plugin.api.json` unless the PR has one of these labels:
  - `api-change`: additive only (new class, method, optional parameter or enum
    value). Existing callers keep compiling. A new `EventType` value also goes
    here, but an exhaustive `switch` over the enum in an app stops compiling,
    so call it out in the changelog.
  - `breaking`: something was removed or renamed, or a signature, return type,
    nullability, supertype or platform minimum changed. Plan a major version.

  The raw baseline diff is in the gate job's summary. Adding or removing a
  label re-runs the gate by itself, without the Flutter jobs.

## Updating the baseline

Install the pinned tool once (the script refuses any other version, because a
different one can serialise the same API differently):

```bash
dart pub global activate dart_apitool 0.23.2
```

Then, after changing the API on purpose:

```bash
bash appstack_plugin/tool/public_api.sh dump
bash appstack_plugin/tool/public_api.sh check
```

Commit the updated `api/appstack_plugin.api.json` with the code change and
label the PR. To preview the breaking / non-breaking classification locally:

```bash
bash appstack_plugin/tool/public_api.sh diff origin/main
```

The script extracts from a scratch copy, because dart_apitool runs `pub get`
in the directory it is given and rewrites its `analysis_options.yaml`. Your
working tree is left untouched. It needs `jq` and `rsync`.

To bump dart_apitool, change `DART_APITOOL_VERSION` in
`tool/public_api.sh` (CI reads it from there), re-run `dump`, and label the PR
`api-change` if the regenerated baseline differs only in formatting.
