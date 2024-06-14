import 'dart:convert';
import 'dart:async';
import 'dart:core';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:talkjs_flutter_inappwebview/talkjs_flutter_inappwebview.dart';

import './user.dart';
import './conversation.dart';
import './webview_common.dart';
import './message.dart';
import './unreads.dart';
import './notification.dart';

typedef MessageHandler = void Function(Message message);
typedef TokenFetcherHandler = Future<String> Function();

enum Provider { fcm, apns }

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
  //   the session is created, and _completer.isCompleted gets set to true.
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
      if ((_webViewController != null) && (!_completer.isCompleted)) {
        _execute('const me = new Talk.User(${me.getJsonString()});');
        createSession(
          execute: _execute,
          session: this,
          variableName: 'me',
        );

        if (onMessage != null) {
          _execute(
              'session.onMessage((event) => window.flutter_inappwebview.callHandler("JSCOnMessage", JSON.stringify(event)));');
        }

        if ((unreads != null) && (unreads!.onChange != null)) {
          _execute(
              'session.unreads.onChange((event) => window.flutter_inappwebview.callHandler("JSCOnUnreadsChange", JSON.stringify(event)));');
        }

        if (enablePushNotifications != null) {
          _setOrUnsetPushRegistration(enablePushNotifications!);
        }

        _execute('const conversations = {};');

        // Execute any pending instructions
        for (var statement in _pending) {
          final controller = _webViewController!;

          if (kDebugMode) {
            print('📗 session.me _pending: $statement');
          }

          controller.evaluateJavascript(source: statement);
        }

        _completer.complete();
      }
    }
  }

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  @Deprecated('Use [token] or [tokenFetcher] instead')
  final String? signature;

  /// An initial JWT authentication token.
  final String? token;
  final TokenFetcherHandler? tokenFetcher;

  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webViewController;
  Completer<void> _completer;

  /// List of JavaScript statements that haven't been executed.
  final _pending = <String>[];

  final bool? enablePushNotifications;

  final MessageHandler? onMessage;
  final Unreads? unreads;

  void _onWebViewCreated(InAppWebViewController controller) async {
    if (kDebugMode) {
      print('📗 session._onWebViewCreated');
    }

    if (onMessage != null) {
      controller.addJavaScriptHandler(
        handlerName: 'JSCOnMessage',
        callback: _jscOnMessage,
      );
    }

    if ((unreads != null) && (unreads!.onChange != null)) {
      controller.addJavaScriptHandler(
        handlerName: 'JSCOnUnreadsChange',
        callback: _jscOnUnreadsChange,
      );
    }

    if (tokenFetcher != null) {
      controller.addJavaScriptHandler(
        handlerName: 'JSCTokenFetcher',
        callback: _jscTokenFetcher,
      );
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

    if (_webViewController == null) {
      _webViewController = controller;

      // Wait for TalkJS to be ready
      final js = 'await Talk.ready;';

      if (kDebugMode) {
        print('📗 session callAsyncJavaScript: $js');
      }

      await controller.callAsyncJavaScript(functionBody: js);

      // If the `me` property has already been initialized, then create the user and the session
      if ((_me != null) && (!_completer.isCompleted)) {
        _execute('const me = new Talk.User(${me.getJsonString()});');
        createSession(
          execute: _execute,
          session: this,
          variableName: 'me',
        );

        if (onMessage != null) {
          _execute(
              'session.onMessage((event) => window.flutter_inappwebview.callHandler("JSCOnMessage", JSON.stringify(event)));');
        }

        if ((unreads != null) && (unreads!.onChange != null)) {
          _execute(
              'session.unreads.onChange((event) => window.flutter_inappwebview.callHandler("JSCOnUnreadsChange", JSON.stringify(event)));');
        }

        if (enablePushNotifications != null) {
          await _setOrUnsetPushRegistration(enablePushNotifications!);
        }

        _execute('const conversations = {};');

        // Execute any pending instructions
        for (var statement in _pending) {
          if (kDebugMode) {
            print('📗 session._onLoadStop _pending: $statement');
          }

          controller.evaluateJavascript(source: statement);
        }

        _completer.complete();
      }
    }
  }

  Future<dynamic> _execute(String statement) {
    if (kDebugMode) {
      print('📗 session._execute: $statement');
    }

    // We're sure that _execute only gets called with a valid _webViewController
    return _webViewController!.evaluateJavascript(source: statement);
  }

  Future<dynamic> _executeAsync(String statement) async {
    if (kDebugMode) {
      print('📗 session._executeAsync: $statement');
    }

    // We're sure that _execute only gets called with a valid _webViewController
    final result =
        await _webViewController!.callAsyncJavaScript(functionBody: statement);
    return result?.value;
  }

  void _jscOnMessage(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 session._jscOnMessage: $message');
    }

    onMessage?.call(Message.fromJson(json.decode(message)));
  }

  void _jscOnUnreadsChange(List<dynamic> arguments) {
    final List<dynamic> unreadsJson = json.decode(arguments[0]);

    if (kDebugMode) {
      print('📗 session._jscOnUnreadsChange: $unreadsJson');
    }

    unreads?.onChange?.call(
      unreadsJson.map((unread) => UnreadConversation.fromJson(unread)).toList(),
    );
  }

  Future<String> _jscTokenFetcher(List<dynamic> arguments) {
    if (kDebugMode) {
      print('📗 session._jscTokenFetcher');
    }

    return tokenFetcher!();
  }

  Future<dynamic> _setOrUnsetPushRegistration(bool enable) {
    String statement = "";

    if (enable) {
      if (fcmToken != null) {
        statement =
            'await session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});';
      } else if (apnsToken != null) {
        statement =
            'await session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});';
      }
    } else {
      if (fcmToken != null) {
        statement =
            'await session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});';
      } else if (apnsToken != null) {
        statement =
            'await session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});';
      }
    }

    if (statement != "") {
      return _executeAsync(statement);
    }

    return Future.value(false);
  }

  Session({
    required this.appId,
    @Deprecated("Use [token] or [tokenFetcher] instead") this.signature,
    this.token,
    this.tokenFetcher,
    this.enablePushNotifications = false,
    this.onMessage,
    this.unreads,
  }) : _completer = new Completer() {
    _headlessWebView = new HeadlessInAppWebView(
        onWebViewCreated: _onWebViewCreated,
        onLoadStop: _onLoadStop,
        onConsoleMessage:
            (InAppWebViewController controller, ConsoleMessage message) {
          print("session [${message.messageLevel}] ${message.message}");
        });

    // Runs the headless WebView
    _headlessWebView!.run();
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
  // - The webview might not have loaded yet, in which case _completer.isCompleted is false, and you can await for the _completer.future

  /// Registers a single mobile device, as one user can be connected to multiple mobile devices.
  ///
  /// If the `provider` and `pushRegistrationId` parameters are not passed, it registers the default Firebase token
  /// for Android, or the default Apns token for iOS, for this device.
  ///
  /// If passing parameters to this function, both `provider` and `pushRegistrationId` must not be null
  Future<void> setPushRegistration({
    Provider? provider,
    String? pushRegistrationId,
  }) async {
    if ((provider == null && pushRegistrationId != null) ||
        (provider != null && pushRegistrationId == null)) {
      throw StateError('provider and pushRegistrationId must both be non-null');
    }

    if (_headlessWebView == null) {
      throw StateError(
          'The setPushRegistration method cannot be called after destroying the session');
    }

    if (!_completer.isCompleted) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling setPushRegistration');
      }

      if (kDebugMode) {
        print(
            '📗 session setPushRegistration: !_completer.isCompleted, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session setPushRegistration: Enabling push notifications');
    }

    if (provider == null && pushRegistrationId == null) {
      await _setOrUnsetPushRegistration(true);
    } else {
      await _executeAsync(
          'await session.setPushRegistration({provider: "${provider!.name}", pushRegistrationId: "$pushRegistrationId"});');
    }
  }

  /// Unregisters a single mobile device, as one user can be connected to multiple mobile devices.
  ///
  /// If the `provider` and `pushRegistrationId` parameters are not passed, it unregisters the default Firebase token
  /// for Android, or the default Apns token for iOS, for this device.
  ///
  /// If passing parameters to this function, both `provider` and `pushRegistrationId` must not be null
  Future<void> unsetPushRegistration({
    Provider? provider,
    String? pushRegistrationId,
  }) async {
    if ((provider == null && pushRegistrationId != null) ||
        (provider != null && pushRegistrationId == null)) {
      throw StateError('provider and pushRegistrationId must both be non-null');
    }

    if (_headlessWebView == null) {
      throw StateError(
          'The unsetPushRegistration method cannot be called after destroying the session');
    }

    if (!_completer.isCompleted) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling unsetPushRegistration');
      }

      if (kDebugMode) {
        print(
            '📗 session unsetPushRegistration: !_completer.isCompleted, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session unsetPushRegistration: Disabling push notifications');
    }

    if (provider == null && pushRegistrationId == null) {
      await _setOrUnsetPushRegistration(false);
    } else {
      await _executeAsync(
          'await session.unsetPushRegistration({provider: "${provider!.name}", pushRegistrationId: "$pushRegistrationId"});');
    }
  }

  /// Unregisters all the mobile devices for the user.
  Future<void> clearPushRegistrations() async {
    if (_headlessWebView == null) {
      throw StateError(
          'The clearPushRegistrations method cannot be called after destroying the session');
    }

    if (!_completer.isCompleted) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling clearPushRegistrations');
      }

      if (kDebugMode) {
        print(
            '📗 session clearPushRegistrations: !_completer.isCompleted, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session clearPushRegistrations: Clearing push notifications');
    }

    await _executeAsync('await session.clearPushRegistrations();');
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = _webViewController;

    if (_completer.isCompleted) {
      if (kDebugMode) {
        print('📗 session.execute: $statement');
      }

      controller!.evaluateJavascript(source: statement);
    } else {
      if (kDebugMode) {
        print('📘 session.execute: $statement');
      }

      this._pending.add(statement);
    }
  }

  /// Invalidates this session
  ///
  /// You cannot use any objects that were created in this session after you destroy it.
  ///
  /// If you want to use TalkJS after having called `destroy()` you must instantiate a new Session instance.
  Future<void> destroy() async {
    if (_headlessWebView == null) {
      // no-op
      if (kDebugMode) {
        print('📗 session destroy: Session already destroyed');
      }
      return;
    }

    // We await for the completer only if the `me` property has been set
    if ((!_completer.isCompleted) && (_me != null)) {
      if (kDebugMode) {
        print(
            '📗 session destroy: !_completer.isCompleted, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session destroy: Destroying session');
    }

    // If the `me` property has not been set, it means that nothing has been done
    // in the WebView. As a matter of fact we don't even know if the WebView has finished initializing.
    if (_me != null) {
      await _execute('session.destroy()');
    }

    _headlessWebView!.dispose();
    _headlessWebView = null;
    _webViewController = null;

    // _completer.isCompleted could be false if we're calling `session.destroy()` beofre setting the `me` property
    if (!_completer.isCompleted) {
      _completer.completeError(StateError("The session has been destroyed"));
    }
  }

  /// Verifies whether the appId is valid
  Future<bool> hasValidCredentials() async {
    if (_headlessWebView == null) {
      throw StateError(
          'The hasValidCredentials method cannot be called after destroying the session');
    }

    if (!_completer.isCompleted) {
      if (_me == null) {
        throw StateError(
            'The me property needs to be set for the Session object before calling hasValidCredentials');
      }

      if (kDebugMode) {
        print(
            '📗 session hasValidCredentials: !_completer.isCompleted, awaiting for _completer.future');
      }
      await _completer.future;
    }

    if (kDebugMode) {
      print('📗 session hasValidCredentials: execute');
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

    if (token != other.token) {
      return false;
    }

    if (tokenFetcher != other.tokenFetcher) {
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
        token,
        tokenFetcher,
        onMessage,
        unreads,
      );

  // TODO:
  // conversation.leave
}
