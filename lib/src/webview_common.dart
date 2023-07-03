import 'dart:convert';

import './notification.dart';
import './session.dart';

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

  if (session.enablePushNotifications) {
    if (fcmToken != null) {
      execute(
          'session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
    }
  } else {
    if (fcmToken != null) {
      execute(
          'session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
    }
  }
}
