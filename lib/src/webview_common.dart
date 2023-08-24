import 'dart:convert';

import './session.dart';
import './notification.dart';

typedef FnExecute = void Function(String statement);
typedef FnExecuteAsync = Future<dynamic> Function(String statement);

void createSession({
  required FnExecute execute,
  required Session session,
  required String variableName,
}) {
  // Initialize Session object
  final options = <String, dynamic>{};

  options['appId'] = session.appId;

  if (session.signature != null) {
    options["signature"] = session.signature;
  }

  execute('const options = ${json.encode(options)};');

  execute('options["me"] = $variableName;');

  execute('const session = new Talk.Session(options);');
}

Future<dynamic> setOrUnsetPushRegistration(
    {required FnExecuteAsync executeAsync,
    required bool enablePushNotifications}) {
  List<String> statements = [];

  if (enablePushNotifications) {
    if (fcmToken != null) {
      statements.add(
          'futures.push(session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"}));');
    }

    if (apnsToken != null) {
      statements.add(
          'futures.push(session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"}));');
    }
  } else {
    if (fcmToken != null) {
      statements.add(
          'futures.push(session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"}));');
    }

    if (apnsToken != null) {
      statements.add(
          'futures.push(session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"}));');
    }
  }

  if (statements.length != 0) {
    statements.insert(0, 'futures = [];');
    statements.add('await Promise.all(futures);');
    return executeAsync(statements.join('\n'));
  }

  return Future.value(false);
}
