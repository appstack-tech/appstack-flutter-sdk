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

    try {
      if (!_runtimeValidationEnabled || _runtimeProxyUrl.isEmpty) {
        throw StateError(
          'Run this probe through tool/run_runtime_validation.sh so the native '
          'loopback proxy is configured.',
        );
      }

      await AppstackPlugin.configure(
        _apiKey,
        logLevel: 0,
        customerUserId: _customerUserId,
      );
      configured = true;

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
  });
}
