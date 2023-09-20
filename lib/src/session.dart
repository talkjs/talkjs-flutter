import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:talkjs_flutter/src/notification.dart';

import 'package:talkjs_flutter_inappwebview/talkjs_flutter_inappwebview.dart';

import './user.dart';
import './conversation.dart';
import './webview_common.dart';
import './message.dart';
import './unreads.dart';

typedef MessageHandler = void Function(Message message);

/// A session represents a currently active user.
class Session {
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
      if (!_completer.isCompleted && _webViewController != null) {
        initializeSession();
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

  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webViewController;

  bool isHeadLess = true;

  Completer<void> _completer;

  bool _enablePushNotifications;

  // setter deliberately omitted, as the `enablePushNotifications` member is read-only
  bool get enablePushNotifications {
    return _enablePushNotifications;
  }

  final MessageHandler? onMessage;
  final Unreads? unreads;

  Session({
    required this.appId,
    this.signature,
    enablePushNotifications = false,
    this.onMessage,
    this.unreads,
  })  : _completer = new Completer(),
        _enablePushNotifications = enablePushNotifications {
    _headlessWebView = new HeadlessInAppWebView(
        initialData: InAppWebViewInitialData(
            data: html, baseUrl: WebUri("https://app.talkjs.com")),
        onWebViewCreated: _onWebViewCreated,
        onLoadStop: _onLoadStop,
        onConsoleMessage:
            (InAppWebViewController controller, ConsoleMessage message) {
          print("session [${message.messageLevel}] ${message.message}");
        });

    // Runs the headless WebView
    _headlessWebView!.run();
  }

  bool isInitialized() {
    return _me != null && _completer.isCompleted;
  }

  Future<void> initializeSession([InAppWebViewController? controller]) async {
    if (controller == null) {
      controller = _webViewController!;
    } else {
      _webViewController = controller;
    }

    // Wait for TalkJS to be ready
    final js = 'await Talk.ready;';

    if (kDebugMode) {
      print('📗 session callAsyncJavaScript: $js');
    }

    await controller.callAsyncJavaScript(functionBody: js);

    var _signature = '';
    if (signature != null) {
      _signature = '"signature": ${json.encode(signature)}';
    }

    _execute('''
      const me = new Talk.User(${_me!.getJsonString()});

      const options = {
        "me": me,
        "appId": "$appId",
        $_signature
      };

      const session = new Talk.Session(options);
    ''');

    if (enablePushNotifications) {
      if (fcmToken != null) {
        _execute(
            'session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
      } else if (apnsToken != null) {
        _execute(
            'session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
      }
    } else {
      if (fcmToken != null) {
        _execute(
            'session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
      } else if (apnsToken != null) {
        _execute(
            'session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
      }
    }

    if (onMessage != null) {
      _execute(
          'session.onMessage((event) => window.flutter_inappwebview.callHandler("JSCOnMessage", JSON.stringify(event)));');
    }

    if ((unreads != null) && (unreads!.onChange != null)) {
      _execute(
          'session.unreads.onChange((event) => window.flutter_inappwebview.callHandler("JSCOnUnreadsChange", JSON.stringify(event)));');
    }

    _completer.complete();
  }

  void _onWebViewCreated(InAppWebViewController controller) async {
    if (kDebugMode) {
      print('📗 session._onWebViewCreated');
    }

    if (onMessage != null) {
      controller.addJavaScriptHandler(
          handlerName: 'JSCOnMessage',
          callback: (List<dynamic> arguments) {
            final message = arguments[0];

            if (kDebugMode) {
              print('📗 session._jscOnMessage: $message');
            }

            onMessage?.call(Message.fromJson(json.decode(message)));
          });
    }

    if ((unreads != null) && (unreads!.onChange != null)) {
      controller.addJavaScriptHandler(
          handlerName: 'JSCOnUnreadsChange',
          callback: (List<dynamic> arguments) {
            final List<dynamic> unreadsJson = json.decode(arguments[0]);

            if (kDebugMode) {
              print('📗 session._jscOnUnreadsChange: $unreadsJson');
            }

            unreads?.onChange?.call(unreadsJson
                .map((unread) => UnreadConversation.fromJson(unread))
                .toList());
          });
    }

    _webViewController = controller;
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (kDebugMode) {
      print('📗 session._onLoadStop ($url)');
    }

    if (!isInitialized() && isHeadLess) {
      initializeSession();
    }
  }

  Future<dynamic> _execute(String statement) {
    if (kDebugMode) {
      print('📗 session.execute: $statement');
    }

    // We're sure that _execute only gets called with a valid _webViewController
    return _webViewController!.evaluateJavascript(source: statement);
  }

  Future<dynamic> _executeAsync(String statement) async {
    if (kDebugMode) {
      print('📗 session.executeAsync: $statement');
    }

    // We're sure that _execute only gets called with a valid _webViewController
    final result =
        await _webViewController!.callAsyncJavaScript(functionBody: statement);
    return result?.value;
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
        session: this,
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

  User getUserById(String id) => User.fromId(id, this);

  Conversation getConversation({
    required String id,
    Map<String, String?>? custom,
    List<String>? welcomeMessages,
    String? photoUrl,
    String? subject,
    Set<Participant> participants = const <Participant>{},
  }) =>
      Conversation(
        session: this,
        id: id,
        custom: custom,
        welcomeMessages: welcomeMessages,
        photoUrl: photoUrl,
        subject: subject,
        participants: participants,
      );

  // The functions that use the headless webview need to take into consideration the following things:
  // - The session could have been destroyed, in which case _headlessWebView is null
  // - The me user could not have been set, in which case _me is null
  // - The webview might not have loaded yet, in which case _sessionInitialized is false, and you can await for the _completer.future

  Future<void> setPushRegistration(
      Provider provider, String pushRegistrationId) async {
    if (_headlessWebView == null) {
      throw StateError(
          'The setPushRegistration method cannot be called after destroying the session');
    }

    if (!isInitialized()) {
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

    _execute(
        'session.setPushRegistration({provider: "${provider.name}", pushRegistrationId: "$pushRegistrationId"})');
  }

  Future<void> unsetPushRegistration(
      Provider provider, String pushRegistrationId) async {
    if (_headlessWebView == null) {
      throw StateError(
          'The unsetPushRegistration method cannot be called after destroying the session');
    }

    if (!isInitialized()) {
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

    _execute(
        'session.unsetPushRegistration({provider: "${provider.name}", pushRegistrationId: "$pushRegistrationId"})');
  }

  Future<void> destroy() async {
    if (_headlessWebView != null) {
      // We await for the completer only if the `me` property has been set
      if (!isInitialized()) {
        if (kDebugMode) {
          print(
              '📗 session destroy: !_sessionInitialized, awaiting for _completer.future');
        }
        await _completer.future;
      }

      await _execute('session.destroy()');

      _headlessWebView?.dispose();
      _headlessWebView = null;
    }
    _webViewController = null;

    // _completer.isCompleted could be false if we're calling `session.destroy()` before setting the `me` property
    if (!_completer.isCompleted) {
      _completer.completeError(StateError("The session has been destroyed"));
    }
  }

  Future<bool> hasValidCredentials() async {
    if (_headlessWebView == null) {
      throw StateError(
          'The hasValidCredentials method cannot be called after destroying the session');
    }

    if (!isInitialized()) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling hasValidCredentials');
      }

      if (kDebugMode) {
        print(
            '📗 session hasValidCredentials: !_sessionInitialized, awaiting for _completer.future');
      }
      await _completer.future;
    }

    final bool isValid =
        await _executeAsync('return await session.hasValidCredentials();');

    return isValid;
  }

  // enablePushNotifications is deliberately omitted, so that we can enable and disable push notifications at will,
  // without necessarily recreating the ChatBox
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is Session)) {
      return false;
    }

    if (appId != other.appId) {
      return false;
    }

    if (me != other.me) {
      return false;
    }

    if (signature != other.signature) {
      return false;
    }

    if (onMessage != other.onMessage) {
      return false;
    }

    if (unreads != other.unreads) {
      return false;
    }

    return true;
  }

  // me and enablePushNotifications are deliberately omitted, so that this object has the exact same hash regardless of its state
  int get hashCode => Object.hash(
        appId,
        signature,
        onMessage,
        unreads,
      );

  // TODO:
  // conversation.leave
  // conversation.sendMessage

  // MAYBE:
  // conversation.setAttributes
}
