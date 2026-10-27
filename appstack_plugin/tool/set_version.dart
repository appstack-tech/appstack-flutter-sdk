// Keeps every copy of the plugin version in agreement:
//
//   pubspec.yaml                                  version: <version>
//   ios/appstack_plugin.podspec                   s.version = '<version>'
//   android/build.gradle                          version '<version>'
//   lib/src/method_channel_appstack_plugin.dart   _kWrapperVersion = 'flutter-<version>'
//   README.md, ../README.md                       appstack_plugin: ^<version>
//   CHANGELOG.md                                  first section below Unreleased: ## [<version>] - YYYY-MM-DD
//
// Run from appstack_plugin/:
//
//   dart run tool/set_version.dart 3.0.0         stamp every copy and cut the changelog section
//   dart run tool/set_version.dart 3.0.0-rc.1 --no-changelog
//                                                stamp the copies only (publish.yml, for RCs)
//   dart run tool/set_version.dart --check [3.0.0]
//                                                fail unless every copy agrees (and equals 3.0.0)
//
// A stable release is published byte-for-byte from the reviewed commit, so
// publish.yml only runs --check for it. RCs are stamped at publish time because
// their version is a dispatch input, not a commit.

import 'dart:io';

final _root = File(Platform.script.toFilePath()).parent.parent;

final _stable = RegExp(r'^\d+\.\d+\.\d+$');
final _any = RegExp(r'^\d+\.\d+\.\d+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$');
final _releasedHeader = RegExp(r'^## \[([^\]]+)\] - \d{4}-\d{2}-\d{2}$');

/// One place the version lives. [pattern] has three groups: the text before the
/// version, the version itself, and the text after it.
class _Copy {
  const _Copy(this.path, this.pattern, {this.all = false});

  final String path;
  final RegExp pattern;

  /// Whether every match in the file is a copy, not just the first.
  final bool all;

  File get file => File('${_root.path}/$path');
}

final _copies = [
  _Copy('pubspec.yaml', RegExp(r'^(version: )(\S+)()$', multiLine: true)),
  _Copy('ios/appstack_plugin.podspec',
      RegExp(r"^(  s\.version += ')([^']+)(')$", multiLine: true)),
  _Copy('android/build.gradle',
      RegExp(r"^(version ')([^']+)(')$", multiLine: true)),
  _Copy('lib/src/method_channel_appstack_plugin.dart',
      RegExp(r"(const _kWrapperVersion = 'flutter-)([^']+)(';)")),
  _Copy('README.md', RegExp(r'(appstack_plugin: \^)(\S+)()'), all: true),
  _Copy('../README.md', RegExp(r'(appstack_plugin: \^)(\S+)()'), all: true),
];

Never _fail(String message) {
  stderr.writeln('::error::$message');
  exit(1);
}

String _read(File file) {
  if (!file.existsSync()) _fail('Missing ${file.path}.');
  return file.readAsStringSync();
}

List<String> _versionsIn(_Copy copy) {
  final matches = copy.pattern.allMatches(_read(copy.file)).toList();
  if (matches.isEmpty) _fail('Could not find the version in ${copy.path}.');
  return [for (final m in copy.all ? matches : matches.take(1)) m.group(2)!];
}

File get _changelog => File('${_root.path}/CHANGELOG.md');

/// First "## [" heading that isn't [Unreleased].
String _latestHeader(List<String> lines) => lines.firstWhere(
      (line) => line.startsWith('## [') && line != '## [Unreleased]',
      orElse: () => '',
    );

/// The changelog with a new section cut from Unreleased, or null when that
/// section already exists.
String? _cutChangelog(String version) {
  final lines = _read(_changelog).split('\n');
  final unreleased = lines.indexOf('## [Unreleased]');
  if (unreleased == -1) _fail('CHANGELOG.md has no "## [Unreleased]" heading.');

  if (_latestHeader(lines).startsWith('## [$version]')) {
    stdout.writeln('CHANGELOG.md already has a $version section; leaving it.');
    return null;
  }

  final next =
      lines.indexWhere((line) => line.trim().isNotEmpty, unreleased + 1);
  if (next == -1 || lines[next].startsWith('## [')) {
    _fail(
        'Nothing under "## [Unreleased]" to release. Add the changes to CHANGELOG.md first.');
  }

  final date = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  lines.insertAll(unreleased + 1, ['', '## [$version] - $date']);
  return lines.join('\n');
}

void _set(String version, {required bool changelog}) {
  if (!_any.hasMatch(version)) _fail('"$version" is not a valid version.');
  if (changelog && !_stable.hasMatch(version)) {
    _fail(
        'Changelog sections are for stable versions; pass --no-changelog for "$version".');
  }

  // Everything is computed before anything is written, so a failure (say, an
  // empty Unreleased section) leaves every file as it was.
  final writes = <File, String>{};
  for (final copy in _copies) {
    final source = _read(copy.file);
    if (!copy.pattern.hasMatch(source)) {
      _fail('Could not find the version in ${copy.path}.');
    }
    String stamp(Match m) => '${m.group(1)}$version${m.group(3)}';
    writes[copy.file] = copy.all
        ? source.replaceAllMapped(copy.pattern, stamp)
        : source.replaceFirstMapped(copy.pattern, stamp);
  }
  final cut = changelog ? _cutChangelog(version) : null;
  if (cut != null) writes[_changelog] = cut;

  writes.forEach((file, content) => file.writeAsStringSync(content));
  stdout.writeln('Set version $version.');
}

void _check(String? expected) {
  final version = _versionsIn(_copies.first).single;
  final header = _latestHeader(_read(_changelog).split('\n'));
  final section = _releasedHeader.firstMatch(header);

  // [where, value] pairs. The package's SDK floor predates Dart records.
  final found = <List<String>>[
    for (final copy in _copies)
      for (final value in _versionsIn(copy)) [copy.path, value],
    [
      'CHANGELOG.md latest section',
      section?.group(1) ?? '(malformed: "$header")'
    ],
  ];

  final problems = <String>[
    if (!_stable.hasMatch(version))
      'pubspec.yaml version "$version" is not X.Y.Z.',
    if (expected != null && version != expected)
      'pubspec.yaml is at $version, expected $expected.',
    for (final f in found)
      if (f[1] != version)
        '${f[0]} has "${f[1]}", pubspec.yaml has "$version".',
  ];

  final width = found.map((f) => f[0].length).reduce((a, b) => a > b ? a : b);
  for (final f in found) {
    stdout.writeln('${f[0].padRight(width)}  ${f[1]}');
  }
  if (problems.isNotEmpty) {
    for (final p in problems) {
      stderr.writeln('::error::$p');
    }
    stderr
        .writeln('Run: dart run tool/set_version.dart ${expected ?? version}');
    exit(1);
  }
  stdout.writeln('All copies agree on $version.');
}

void main(List<String> args) {
  const usage =
      'Usage: set_version.dart <version> [--no-changelog] | --check [<version>]';
  if (args.isNotEmpty && args.first == '--check') {
    if (args.length > 2) _fail(usage);
    _check(args.length == 2 ? args[1] : null);
  } else if (args.length == 1 && !args.first.startsWith('--')) {
    _set(args.first, changelog: true);
  } else if (args.length == 2 && args[1] == '--no-changelog') {
    _set(args.first, changelog: false);
  } else {
    _fail(usage);
  }
}
