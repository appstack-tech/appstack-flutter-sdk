# Releasing

This document is for release maintainers. Integrators should start with
[README.md](README.md).

## Branches and how a release happens

- **`develop`** is where work lands. Open PRs against it and squash-merge
  them. Nothing on `develop` is published by merging.
- **`main`** only changes through release PRs. Merging one publishes to
  pub.dev.

To cut a stable release:

1. On a branch off `develop`:
   1. Confirm both native SDK pins are released versions: `exact: "X.Y.Z"` in
      `appstack_plugin/ios/appstack_plugin/Package.swift` (with the matching
      XCFramework vendored, see [XCFRAMEWORK_UPDATE.md](appstack_plugin/XCFRAMEWORK_UPDATE.md))
      and `appstackAndroidSdkVersion` in `appstack_plugin/android/build.gradle`.
      `bash appstack_plugin/tool/check_release_pins.sh` checks both.
   2. From `appstack_plugin/`, run:

      ```bash
      dart run tool/set_version.dart X.Y.Z
      ```

      It writes the version into every place it lives (`pubspec.yaml`, the
      podspec, `android/build.gradle`, the wrapper version constant in
      `lib/src/method_channel_appstack_plugin.dart`, and the install snippet
      in both READMEs) and promotes `## [Unreleased]` in `CHANGELOG.md` to
      `## [X.Y.Z] - <today>`.

   Merge that into `develop`.
2. Open a PR from `develop` into `main`. The **Release version** check
   (`release-pr.yml`) names the version that merging will publish. It fails if
   the changelog has no new version, if any copy of the version disagrees
   (`dart run tool/set_version.dart --check` runs the same check locally), or
   if a native pin is a candidate.
3. Get it approved by someone other than you, then merge it with **Create a
   merge commit**. Don't squash: a squash leaves `develop` and `main` with
   different commits for the same changes, and every later release PR then
   conflicts. That merge commit is the one record of each release on `main`.
4. `publish.yml` runs on the push to `main`: it reads the version from the
   changelog, checks iOS SDK parity, the native pins and every version copy
   again, runs the build and runtime checks, publishes that commit to pub.dev
   unchanged, then creates the `X.Y.Z` tag and GitHub Release on the merge
   commit.

A merge to `main` whose changelog has no new version publishes nothing. Such a
PR needs the `no-release` label to pass the Release version check. Version tags
are created by the workflow; pushing one by hand doesn't publish.

Publishing authenticates with the `GCP_SA_KEY` secret of the `release`
environment, which only `main` and `develop` can deploy to.

## Release candidates

Run `publish.yml` manually on `develop` with an RC version:

```bash
gh workflow run publish.yml --ref develop -f version=3.0.0-rc.1
```

It publishes a pub.dev prerelease and creates no git tag or GitHub Release.
Runs on any other branch are rejected. The RC version is stamped into the
package at publish time only; nothing is committed.

pub.dev versions are permanent (a version can only be retracted, within 7
days), so a candidate is public for good. An RC may pin native candidates (an
Android `-SNAPSHOT`, the iOS `rc` branch); restore released pins before the
release PR.

## Hotfixes

Branch `hotfix/<name>` off `main`, run `dart run tool/set_version.dart X.Y.Z`
for the patch version, and open the PR into `main` (merge commit, as above).
After it publishes, open a PR from `main` into `develop` and squash it, so the
fix is on `develop` too.
