# Deployment Guide

Quick guide for deploying new versions of the Appstack Flutter Plugin.

## Quick Deploy Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Update `ios/appstack_plugin.podspec` version
- [ ] Ensure iOS xcframework is up to date
- [ ] Run tests: `flutter test`
- [ ] Format code: `dart format .`
- [ ] Analyze: `flutter analyze`
- [ ] Dry run: `flutter pub publish --dry-run`
- [ ] Commit changes
- [ ] Create and push tag: `git tag v0.0.X && git push origin v0.0.X`

## Step-by-Step Process

### 1. Update Version Numbers

Update in **three places**:

**pubspec.yaml:**
```yaml
version: 0.0.2  # Update this
```

**ios/appstack_plugin.podspec:**
```ruby
s.version = '0.0.2'  # Update this
```

**CHANGELOG.md:**
```markdown
## [0.0.2] - 2025-10-XX

### Added
- New feature

### Fixed
- Bug fix
```

### 2. Verify Package Quality

```bash
# Navigate to plugin directory
cd appstack_plugin

# Install dependencies
flutter pub get

# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Dry run publish
flutter pub publish --dry-run
```

### 3. Commit and Tag

```bash
# Commit version changes
git add pubspec.yaml ios/appstack_plugin.podspec CHANGELOG.md
git commit -m "Bump version to 0.0.2"

# Create tag
git tag v0.0.2

# Push changes and tag
git push origin main  # or master
git push origin v0.0.2
```

### 4. Automatic Publishing

GitHub Actions will automatically:
1. Run all tests
2. Verify package
3. Publish to pub.dev

Monitor progress at: https://github.com/appstack-tech/appstack-flutter-sdk/actions

### 5. Verify Publication

After ~5 minutes:
1. Check pub.dev: https://pub.dev/packages/appstack_plugin
2. Verify version appears
3. Check package score
4. Test installation in a new project

## Manual Publishing (If Needed)

If automatic publishing fails:

```bash
cd appstack_plugin
flutter pub publish
```

Enter 'y' when prompted.

## Updating iOS SDK

If the iOS AppstackSDK needs updating:

```bash
# Copy latest xcframework
cp -R ../ios-appstack-sdk/AppstackSDK.xcframework ios/

# Commit the update
git add ios/AppstackSDK.xcframework
git commit -m "Update iOS AppstackSDK to version X.X.X"
```

## Rollback

If you need to unpublish a version (within 7 days):

```bash
flutter pub unpublish appstack_plugin --version 0.0.2
```

**Note:** This should only be done for critical issues. Consider publishing a patch version instead.

## Troubleshooting

### "Version already exists"
- Increment version number and try again
- Cannot republish the same version

### "Package validation failed"
- Run `flutter pub publish --dry-run`
- Fix all reported issues
- Ensure all required files exist (README.md, CHANGELOG.md, LICENSE)

### "Credentials invalid"
- Check `PUB_DEV_CREDENTIALS` secret in GitHub
- Regenerate credentials: `flutter pub publish --dry-run`
- Update GitHub secret with new credentials

### GitHub Actions fails
- Check workflow logs in Actions tab
- Common fixes:
  - Format code: `dart format .`
  - Fix analysis issues: `flutter analyze`
  - Fix failing tests: `flutter test`

## Version Strategy

- **0.0.x**: Initial development, breaking changes allowed
- **0.x.0**: Pre-release, API stabilizing
- **1.0.0**: First stable release
- **1.x.0**: New features, backward compatible
- **x.0.0**: Breaking changes

## Post-Release

After successful publication:

1. **Announce the release:**
   - Create GitHub Release with changelog
   - Update documentation if needed
   - Notify users of breaking changes

2. **Monitor:**
   - Watch for issues on GitHub
   - Check pub.dev package score
   - Monitor download statistics

3. **Update sample app:**
   - Test with new version
   - Update sample app if needed

## Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
