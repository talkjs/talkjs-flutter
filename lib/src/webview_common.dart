import 'dart:convert';

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
    options['signature'] = session.signature;
  }

  if (session.token != null) {
    options['token'] = session.token;
  }

  execute('const options = ${json.encode(options)};');

  execute('options["me"] = $variableName;');

  if (session.tokenFetcher != null) {
    // callHandler returns a Promise that can be used to get the json result returned by the
    // callback. In this case "JSCTokenFetcher".
    execute(
        'options["tokenFetcher"] = () => window.flutter_inappwebview.callHandler("JSCTokenFetcher");');
  }

  execute('const session = new Talk.Session(options);');
}
