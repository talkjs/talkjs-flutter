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
  var signature = '';
  if (session.signature != null) {
    signature = '"signature": ${json.encode(session.signature)}';
  }

  execute('''
    const options = {
      "appId": "${session.appId}",
      "me": $variableName,
      $signature
    };

    const session = new Talk.Session(options);
  ''');

  if (session.enablePushNotifications) {
    if (fcmToken != null) {
      execute(
          'session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
    } else if (apnsToken != null) {
      execute(
          'session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
    }
  } else {
    if (fcmToken != null) {
      execute(
          'session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
    } else if (apnsToken != null) {
      execute(
          'session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
    }
  }
}
