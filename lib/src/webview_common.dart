import 'dart:convert';

import './session.dart';
import './notification.dart';

typedef FnExecute = void Function(String statement);

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

  setOrUnsetPushRegistration(
      execute: execute,
      enablePushNotifications: session.enablePushNotifications);
}

void setOrUnsetPushRegistration(
    {required FnExecute execute, required bool enablePushNotifications}) {
  if (enablePushNotifications) {
    if (fcmToken != null) {
      execute(
          'session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
    }

    if (apnsToken != null) {
      execute(
          'session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
    }
  } else {
    if (fcmToken != null) {
      execute(
          'session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
    }

    if (apnsToken != null) {
      execute(
          'session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
    }
  }
}
