# Publishing to pub.dev

This document describes how to publish the Appstack Flutter Plugin to pub.dev.

## Prerequisites

1. **pub.dev Account**: You need a verified pub.dev account
2. **Package Ownership**: You must be added as an uploader for the `appstack_plugin` package
3. **GitHub Secrets**: The repository must have the `PUB_DEV_CREDENTIALS` secret configured

## Setting Up GitHub Secrets

To enable automatic publishing, you need to set up pub.dev credentials as a GitHub secret:

1. **Generate pub.dev credentials:**
   ```bash
   # On your local machine, run:
   flutter pub publish --dry-run
   
   # This will create credentials at:
   # - macOS/Linux: ~/.pub-cache/credentials.json
   # - Windows: %APPDATA%\Pub\Cache\credentials.json
   ```

2. **Copy the credentials file content:**
   ```bash
   cat ~/.pub-cache/credentials.json
   ```

3. **Add to GitHub Secrets:**
   - Go to your repository on GitHub
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `PUB_DEV_CREDENTIALS`
   - Value: Paste the entire content of `credentials.json`
   - Click "Add secret"

## Publishing Process

### Automatic Publishing (Recommended)

The package is automatically published when you create a new release tag:

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 0.0.2  # Increment version
   ```

2. **Update CHANGELOG.md:**
   ```markdown
   ## [0.0.2] - 2025-10-XX
   
   ### Added
   - New feature description
   
   ### Fixed
   - Bug fix description
   ```

3. **Commit changes:**
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "Bump version to 0.0.2"
   git push
   ```

4. **Create and push a tag:**
   ```bash
   git tag v0.0.2
   git push origin v0.0.2
   ```

5. **GitHub Actions will automatically:**
   - Run tests
   - Verify the package
   - Check formatting and analysis
   - Publish to pub.dev

### Manual Publishing

If you need to publish manually:

1. **Verify the package:**
   ```bash
   cd appstack_plugin
   flutter pub publish --dry-run
   ```

2. **Publish to pub.dev:**
   ```bash
   flutter pub publish
   ```

3. **Confirm the publication** when prompted

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.1.0): New features, backward compatible
- **PATCH** (0.0.1): Bug fixes, backward compatible

Examples:
- `0.0.1` → `0.0.2`: Bug fixes
- `0.0.2` → `0.1.0`: New features added
- `0.1.0` → `1.0.0`: Breaking changes or first stable release

## Pre-release Versions

For beta or alpha releases:

```yaml
version: 0.1.0-beta.1
version: 0.1.0-alpha.1
```

Tag format:
```bash
git tag v0.1.0-beta.1
```

## Checklist Before Publishing

- [ ] Version number updated in `pubspec.yaml`
- [ ] CHANGELOG.md updated with changes
- [ ] All tests passing locally (`flutter test`)
- [ ] Code formatted (`dart format .`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] README.md is up to date
- [ ] Example app works correctly
- [ ] iOS xcframework is up to date
- [ ] Android SDK version is correct in build.gradle

## Troubleshooting

### Publishing Fails

1. **Check credentials:**
   - Ensure `PUB_DEV_CREDENTIALS` secret is set correctly
   - Verify you're an uploader for the package

2. **Version conflict:**
   - Ensure the version in `pubspec.yaml` hasn't been published before
   - Check pub.dev for existing versions

3. **Validation errors:**
   - Run `flutter pub publish --dry-run` locally
   - Fix any issues reported

### GitHub Actions Fails

1. **Check workflow logs** in the Actions tab
2. **Common issues:**
   - Formatting errors: Run `dart format .`
   - Analysis errors: Run `flutter analyze` and fix issues
   - Test failures: Run `flutter test` and fix failing tests

## Monitoring

After publishing:

1. **Check pub.dev:** Visit https://pub.dev/packages/appstack_plugin
2. **Verify documentation:** Ensure README renders correctly
3. **Check package score:** Aim for 130+ points
4. **Monitor issues:** Watch for user-reported issues

## Support

For questions or issues with publishing:
- Check pub.dev documentation: https://dart.dev/tools/pub/publishing
- Contact the package maintainers
