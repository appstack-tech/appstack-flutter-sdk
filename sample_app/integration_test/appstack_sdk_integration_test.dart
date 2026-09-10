// Hermetic runtime validation for the Appstack Flutter SDK.
//
// The host harness starts a local recording backend and injects its loopback URL
// into the native test application. This probe exercises only the public Dart
// API; the external validator checks both this terminal result and the native
// requests recorded by the backend.

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:appstack_plugin/appstack_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _resultPrefix = 'APPSTACK_RUNTIME_RESULT:';
const _apiKey = 'runtime-validation-local-key';
const _customerUserId = 'runtime-validation-user';
const _runtimeValidationEnabled = bool.fromEnvironment(
  'APPSTACK_RUNTIME_VALIDATION',
);
const _runtimeProxyUrl = String.fromEnvironment('APPSTACK_RUNTIME_PROXY_URL');

bool _validAttribution(Map<String, dynamic>? value) {
  return value?['runtime_validation'] == 'attributed' &&
      value?['unicode'] == 'café 🚀';
}

/// Drive `handleUniversalLink` against the real native parser and record what
/// came back. Failures are captured rather than thrown so one unsupported case
/// cannot hide the rest of the matrix.
Future<Map<String, Object?>> _probeLink(
  String label,
  String url, {
  Set<String>? allowedHosts,
}) async {
  try {
    final link = await AppstackPlugin.handleUniversalLink(
      Uri.parse(url),
      allowedHosts: allowedHosts,
    );
    return <String, Object?>{
      'label': label,
      'url': url,
      'allowedHosts': allowedHosts?.toList(),
      'supported': link != null,
      'deeplinkId': link?.deeplinkId,
      'queryParams': link?.queryParams,
      'resultUrl': link?.url.toString(),
    };
  } catch (error) {
    return <String, Object?>{
      'label': label,
      'url': url,
      'allowedHosts': allowedHosts?.toList(),
      'error': '$error',
    };
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('public API crosses the native wire boundary', (tester) async {
    final errors = <String>[];
    var configured = false;
    var appstackIdPresent = false;
    var sdkDisabled = true;
    var attributionCompleted = false;
    var attributionValidated = false;
    var customEventAccepted = false;
    var standardEventAccepted = false;
    Map<String, Object?> preConfigureLink = <String, Object?>{};
    final linkCases = <Map<String, Object?>>[];

    try {
      if (!_runtimeValidationEnabled || _runtimeProxyUrl.isEmpty) {
        throw StateError(
          'Run this probe through tool/run_runtime_validation.sh so the native '
          'loopback proxy is configured.',
        );
      }

      // Documented guarantee: the parser is usable before configure().
      preConfigureLink = await _probeLink(
        'preConfigure',
        'https://links.example.com/pre123?screen=offer',
        allowedHosts: {'links.example.com'},
      );

      await AppstackPlugin.configure(
        _apiKey,
        logLevel: 0,
        customerUserId: _customerUserId,
      );
      configured = true;

      // Universal/App Link parsing matrix, executed against the native parser.
      linkCases.addAll(<Map<String, Object?>>[
        // Supported: branded host, exactly one path segment.
        await _probeLink(
          'brandedSingleSegment',
          'https://links.example.com/abc123?screen=offer&utm_source=café%20🚀',
          allowedHosts: {'links.example.com'},
        ),
        // Ignored by design: the shared Appstack hosts.
        await _probeLink(
          'sharedHost',
          'https://appstack.link/abc123?screen=offer',
          allowedHosts: {'appstack.link'},
        ),
        await _probeLink(
          'sharedDevHost',
          'https://dev.appstack.link/abc123?screen=offer',
          allowedHosts: {'dev.appstack.link'},
        ),
        // Unsupported shapes.
        await _probeLink(
          'multiSegment',
          'https://links.example.com/a/b?screen=offer',
          allowedHosts: {'links.example.com'},
        ),
        await _probeLink(
          'noSegment',
          'https://links.example.com/?screen=offer',
          allowedHosts: {'links.example.com'},
        ),
        // Host outside the allowlist.
        await _probeLink(
          'hostNotAllowed',
          'https://evil.example.com/abc123?screen=offer',
          allowedHosts: {'links.example.com'},
        ),
        // Documented: with no allowlist every host but the shared ones parses.
        await _probeLink(
          'noAllowlistBranded',
          'https://links.example.com/abc123?screen=offer',
        ),
        await _probeLink(
          'noAllowlistShared',
          'https://appstack.link/abc123?screen=offer',
        ),
        // Documented: only https links are parsed.
        await _probeLink(
          'customScheme',
          'myapp://links.example.com/abc123?screen=offer',
          allowedHosts: {'links.example.com'},
        ),
      ]);

      final appstackId = await AppstackPlugin.getAppstackId();
      appstackIdPresent = appstackId != null && appstackId.isNotEmpty;

      // Remote configuration completes asynchronously in the native SDKs. The
      // mock's distinctive attribution payload is the observable readiness
      // boundary shared by iOS and Android.
      Map<String, dynamic>? directAttribution;
      for (var attempt = 0; attempt < 40; attempt++) {
        directAttribution = await AppstackPlugin.getAttributionParams();
        if (_validAttribution(directAttribution)) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
      }

      final streamedAttribution =
          await AppstackPlugin.getAttributionParamsWithCallback().first.timeout(
            const Duration(seconds: 10),
          );
      attributionCompleted =
          directAttribution != null && streamedAttribution != null;
      attributionValidated =
          _validAttribution(directAttribution) &&
          _validAttribution(streamedAttribution);

      sdkDisabled = await AppstackPlugin.isSdkDisabled();

      customEventAccepted = await AppstackPlugin.sendEvent(
        EventType.custom,
        eventName: 'runtime_validation_custom',
        parameters: {
          'number': 42,
          'boolean': true,
          'unicode': 'café 🚀',
          'items': ['one', 2, false],
          'nested': {'enabled': true, 'value': 7},
        },
      );
      standardEventAccepted = await AppstackPlugin.sendEvent(
        EventType.login,
        parameters: {'state': 'ready', 'sequence': 2},
      );

      // Event submission is fire-and-forget. The host validator polls the
      // recording backend, while this short window lets queued native work start
      // before the integration-test application begins teardown.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
    } catch (error, stackTrace) {
      errors.add('$error\n$stackTrace');
    }

    final result = <String, Object>{
      'platform': Platform.operatingSystem,
      'configured': configured,
      'appstackIdPresent': appstackIdPresent,
      'sdkDisabled': sdkDisabled,
      'attributionCompleted': attributionCompleted,
      'attributionValidated': attributionValidated,
      'customEventAccepted': customEventAccepted,
      'standardEventAccepted': standardEventAccepted,
      'preConfigureLink': preConfigureLink,
      'linkCases': linkCases,
      'errors': errors,
    };

    // Exactly one terminal result is emitted. The host validator searches by
    // prefix because flutter_test may add its own logging decoration.
    // ignore: avoid_print
    print('$_resultPrefix${jsonEncode(result)}');

    expect(errors, isEmpty);
    expect(configured, isTrue);
    expect(appstackIdPresent, isTrue);
    expect(sdkDisabled, isFalse);
    expect(attributionCompleted, isTrue);
    expect(attributionValidated, isTrue);
    expect(customEventAccepted, isTrue);
    expect(standardEventAccepted, isTrue);

    Map<String, Object?> linkCase(String label) => linkCases.firstWhere(
      (item) => item['label'] == label,
      orElse: () => throw StateError('missing link case: $label'),
    );

    // The parser must work before configure().
    expect(preConfigureLink['error'], isNull);
    expect(preConfigureLink['supported'], isTrue);
    expect(preConfigureLink['deeplinkId'], 'pre123');

    // A branded host with exactly one path segment is the supported shape.
    final branded = linkCase('brandedSingleSegment');
    expect(branded['error'], isNull);
    expect(branded['supported'], isTrue);
    expect(branded['deeplinkId'], 'abc123');
    expect(
      (branded['queryParams'] as Map?)?['screen'],
      'offer',
      reason: 'query parameters must survive the native bridge',
    );
    expect(
      (branded['queryParams'] as Map?)?['utm_source'],
      'café 🚀',
      reason: 'percent-encoded UTF-8 must survive the native bridge',
    );

    // With no allowlist, any host but the shared Appstack ones still parses.
    final openHost = linkCase('noAllowlistBranded');
    expect(openHost['error'], isNull);
    expect(openHost['supported'], isTrue);
    expect(openHost['deeplinkId'], 'abc123');

    // Everything the documented contract excludes must come back null.
    for (final label in const <String>[
      'sharedHost',
      'sharedDevHost',
      'multiSegment',
      'noSegment',
      'hostNotAllowed',
      'noAllowlistShared',
      'customScheme',
    ]) {
      final item = linkCase(label);
      expect(item['error'], isNull, reason: '$label threw');
      expect(item['supported'], isFalse, reason: '$label must be unsupported');
    }
  });
}
