import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:talkjs_flutter_inappwebview/talkjs_flutter_inappwebview.dart';

import './user.dart';
import './conversation.dart';
import './webview_common.dart';

// The base problem is that the HeadlessInAppWebView docs state:
//
// caution
//
// Remember to dispose it when you don't need it anymore using the HeadlessInAppWebView.dispose method.
//
// So we need to call the HeadlessInAppWebView.dispose method when the Session gets garbage collected.
// In order to do so, we keep the WebViews in a Map, so that the Session doesn't directly depend on the WebView
// (or else the Session would never be garbage collected, if we passed directly the WebView to the Finalizer).

int _headlessWebViewId = 0;
final Map<int, HeadlessInAppWebView> _headlessWebViews =
    Map<int, HeadlessInAppWebView>();
final Map<int, InAppWebViewController> _webViewControllers =
    Map<int, InAppWebViewController>();

final Finalizer<int> _webViewFinalizer = Finalizer((index) {
  if (kDebugMode) {
    print('📗 session headlessWebView.dispose()');
  }

  _headlessWebViews[index]!.dispose();
  _headlessWebViews.remove(index);
  _webViewControllers.remove(index);
});

/// A session represents a currently active user.
class Session with ChangeNotifier {
  /// Your TalkJS AppId that can be found your TalkJS [dashboard](https://talkjs.com/dashboard).
  final String appId;

  /// The TalkJS [User] associated with the current user in your application.
  User? _me;

  User get me {
    if (_me == null) {
      throw StateError('Set the me property before using the Session object');
    } else {
      return _me!;
    }
  }

  // We have the following moving parts:
  // - We need a `me` User before being able to create the session in the WebView
  // - The `enablePushNotifications` property can change before the WebView is loaded
  // - When the WebView loads or when the `me` user is passed, whichever comes last,
  //   the session is created, and _sessionInitialized gets set to true.
  //   At this point, any change to enablePushNotifications triggers setting or unsetting
  //   the push notifications

  set me(User user) {
    if (_me != null) {
      throw StateError(
          'The me property has already been set for the Session object');
    } else {
      _me = user;

      // If the WebView has loaded the page, but didn't initialize the session because of
      // the missing `me` property, now is the time to initialize the session.
      if ((_webViewControllers[_webViewIndex] != null) &&
          (!_sessionInitialized)) {
        _sessionInitialized = true;
        _completer.complete();
        _execute('const me = new Talk.User(${me.getJsonString()});');
        createSession(
          execute: _execute,
          session: this,
          variableName: 'me',
        );
        setOrUnsetPushRegistration(
            executeAsync: _executeAsync,
            enablePushNotifications: _enablePushNotifications);
      }
    }
  }

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  final String? signature;

  final _webViewIndex;
  bool _sessionInitialized;
  Completer<void> _completer;

  bool _enablePushNotifications;

  bool get enablePushNotifications {
    return _enablePushNotifications;
  }

  set enablePushNotifications(bool enable) {
    if (enable != _enablePushNotifications) {
      _enablePushNotifications = enable;

      if (_sessionInitialized) {
        setOrUnsetPushRegistration(
            executeAsync: _executeAsync, enablePushNotifications: enable);
      }
    }
  }

  void _onWebViewCreated(InAppWebViewController controller) async {
    if (kDebugMode) {
      print('📗 session._onWebViewCreated');
    }

    String htmlData = await rootBundle
        .loadString('packages/talkjs_flutter/assets/index.html');
    controller.loadData(
        data: htmlData, baseUrl: WebUri("https://app.talkjs.com"));
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (kDebugMode) {
      print('📗 session._onLoadStop ($url)');
    }

    if (_webViewControllers[_webViewIndex] == null) {
      _webViewControllers[_webViewIndex] = controller;

      // Wait for TalkJS to be ready
      final js = 'await Talk.ready;';

      if (kDebugMode) {
        print('📗 session callAsyncJavaScript: $js');
      }

      await controller.callAsyncJavaScript(functionBody: js);

      _execute('let futures = []');

      // If the `me` property has already been initialized, then create the user and the session
      if ((_me != null) && (!_sessionInitialized)) {
        _execute('const me = new Talk.User(${me.getJsonString()});');
        createSession(
          execute: _execute,
          session: this,
          variableName: 'me',
        );

        await setOrUnsetPushRegistration(
            executeAsync: _executeAsync,
            enablePushNotifications: _enablePushNotifications);

        _sessionInitialized = true;
        _completer.complete();
      }
    }
  }

  Future<dynamic> _execute(String statement) {
    if (kDebugMode) {
      print('📗 session.execute: $statement');
    }

    // We're sure that _execute only gets called with a valid InAppWebViewController
    return _webViewControllers[_webViewIndex]!
        .evaluateJavascript(source: statement);
  }

  Future<dynamic> _executeAsync(String statement) {
    if (kDebugMode) {
      print('📗 session.executeAsync: $statement');
    }

    // We're sure that _execute only gets called with a valid InAppWebViewController
    return _webViewControllers[_webViewIndex]!
        .callAsyncJavaScript(functionBody: statement);
  }

  Session(
      {required this.appId, this.signature, enablePushNotifications = false})
      : _enablePushNotifications = enablePushNotifications,
        _webViewIndex = _headlessWebViewId,
        _sessionInitialized = false,
        _completer = new Completer() {
    _headlessWebViewId += 1;

    _headlessWebViews[_webViewIndex] = new HeadlessInAppWebView(
        onWebViewCreated: _onWebViewCreated,
        onLoadStop: _onLoadStop,
        onConsoleMessage:
            (InAppWebViewController controller, ConsoleMessage message) {
          print("session [${message.messageLevel}] ${message.message}");
        });

    // Call _headlessWebView.dispose() when the session gets garbage collected
    _webViewFinalizer.attach(this, _webViewIndex);

    // Runs the headless WebView
    _headlessWebViews[_webViewIndex]!.run();
  }

  User getUser({
    required String id,
    required String name,
    List<String>? email,
    List<String>? phone,
    String? availabilityText,
    String? locale,
    String? photoUrl,
    String? role,
    Map<String, String?>? custom,
    String? welcomeMessage,
  }) =>
      User(
        id: id,
        name: name,
        email: email,
        phone: phone,
        availabilityText: availabilityText,
        locale: locale,
        photoUrl: photoUrl,
        role: role,
        custom: custom,
        welcomeMessage: welcomeMessage,
      );

  User getUserById(String id) => User.fromId(id);

  Conversation getConversation({
    required String id,
    Map<String, String?>? custom,
    List<String>? welcomeMessages,
    String? photoUrl,
    String? subject,
    Set<Participant> participants = const <Participant>{},
  }) =>
      Conversation(
        id: id,
        custom: custom,
        welcomeMessages: welcomeMessages,
        photoUrl: photoUrl,
        subject: subject,
        participants: participants,
      );

  Future<void> setPushRegistration() async {
    if (_enablePushNotifications) {
      // no-op
      if (kDebugMode) {
        print(
            '📗 session setPushRegistration: Push notifications are already enabled');
      }
      return;
    }

    if (!_sessionInitialized) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling setPushRegistration');
      }

      if (kDebugMode) {
        print(
            '📗 session setPushRegistration: !_sessionInitialized, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session setPushRegistration: Enabling push notifications');
    }
    _enablePushNotifications = true;

    await setOrUnsetPushRegistration(
        executeAsync: _executeAsync,
        enablePushNotifications: _enablePushNotifications);
  }

  Future<void> unsetPushRegistration() async {
    if (!_enablePushNotifications) {
      // no-op
      if (kDebugMode) {
        print(
            '📗 session unsetPushRegistration: Push notifications are already disabled');
      }
      return;
    }

    if (!_sessionInitialized) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling unsetPushRegistration');
      }

      if (kDebugMode) {
        print(
            '📗 session unsetPushRegistration: !_sessionInitialized, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session unsetPushRegistration: Disabling push notifications');
    }
    _enablePushNotifications = false;

    await setOrUnsetPushRegistration(
        executeAsync: _executeAsync,
        enablePushNotifications: _enablePushNotifications);
  }
}
