import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import './session.dart';
import './conversation.dart';
import './user.dart';
import './predicate.dart';
import './chatbox.dart';
import './webview_common.dart';

typedef SelectConversationHandler = void Function(SelectConversationEvent event);

class SelectConversationEvent {
  final ConversationData conversation;
  final UserData me;
  final List<UserData> others;

  SelectConversationEvent.fromJson(Map<String, dynamic> json)
    : conversation = ConversationData.fromJson(json['conversation']),
    me = UserData.fromJson(json['me']),
    others = json['others'].map<UserData>((user) => UserData.fromJson(user)).toList();
}

class ConversationListOptions {
  /// Controls if the feed header containing the toggle to enable desktop notifications is shown.
  /// Defaults to true.
  final bool? showFeedHeader;

  /// Controls whether the user navigating between conversation should count
  /// as steps in the browser history. Defaults to true, which means that if the user
  /// clicks the browser's back button, they go back to the previous conversation
  /// (if any).
  ///
  /// NOT NEEDED FOR FLUTTER?
  //bool? useBrowserHistory;

  /// Whether to show a "Back" button at the top of the chat screen on mobile devices.
  ///
  /// NOT NEEDED FOR FLUTTER?
  //bool? showMobileBackButton;

  /// Overrides the theme used for this chat UI.
  final String? theme;

  const ConversationListOptions({this.showFeedHeader, this.theme});

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// This method is used instead of toJson for coherence with ChatBoxOptions.
  /// The toJson method is intentionally omitted, to produce an error if
  /// someone tries to convert this object to JSON instead of using the
  /// getJsonString method.
  String getJsonString(ConversationListState conversationList) {
    final result = <String, dynamic>{};

    if (showFeedHeader != null) {
      result['showFeedHeader'] = showFeedHeader;
    }

    if (theme != null) {
      result['theme'] = theme;
    }

    conversationList.setExtraOptions(result);

    return json.encode(result);
  }
}

class ConversationList extends StatefulWidget {
  final Session session;

  final bool? showFeedHeader;

  final String? theme;

  final ConversationPredicate feedFilter;

  final SelectConversationHandler? onSelectConversation;
  final LoadingStateHandler? onLoadingStateChanged;

  const ConversationList({
    Key? key,
    required this.session,
    this.showFeedHeader,
    this.theme,
    this.feedFilter = const ConversationPredicate(),
    this.onSelectConversation,
    this.onLoadingStateChanged,
  }) : super(key: key);

  @override
  State<ConversationList> createState() => ConversationListState();
}

class ConversationListState extends State<ConversationList> {
  /// Used to control the underlying WebView
  InAppWebViewController? _webViewController;
  bool _webViewCreated = false;

  /// List of JavaScript statements that haven't been executed.
  final _pending = <String>[];

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  final _users = <String, String>{};

  /// Objects stored for comparing changes
  ConversationPredicate _oldFeedFilter = const ConversationPredicate();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('📗 conversationlist.build (_webViewCreated: $_webViewCreated)');
    }

    if (!_webViewCreated) {
      _webViewCreated = true;

      if (Platform.isAndroid) {
        AndroidInAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
      }

      // Here a Timer is needed, as we can't change the widget's state while the widget
      // is being constructed, and the callback may very possibly change the state
      Timer.run(() => widget.onLoadingStateChanged?.call(LoadingState.loading));

      createSession(execute: execute, session: widget.session, variableName: getUserVariableName(widget.session.me));
      _createConversationList();
      // feedFilter is set as an option for the inbox

      execute('conversationList.mount(document.getElementById("talkjs-container")).then(() => window.flutter_inappwebview.callHandler("JSCLoadingState", "loaded"));');
    } else {
      // If it's not the first time that the widget is built,
      // then check what needs to be rebuilt

      // TODO: If something has changed in the Session we should do something
      _checkFeedFilter();
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(url: null),
      onWebViewCreated: _onWebViewCreated,
      onLoadStop: _onLoadStop,
      onConsoleMessage: (InAppWebViewController controller, ConsoleMessage message) {
        print("conversationlist [${message.messageLevel}] ${message.message}");
      },
      gestureRecognizers: {
        // We need only the VerticalDragGestureRecognizer in order to be able to scroll through the conversations
        Factory(() => VerticalDragGestureRecognizer()),
      },
    );
  }

  void _createConversationList() {
    final options = ConversationListOptions(
      showFeedHeader: widget.showFeedHeader,
      theme: widget.theme,
    );

    _oldFeedFilter = ConversationPredicate.of(widget.feedFilter);

    execute('const conversationList = session.createInbox(${options.getJsonString(this)});');

    execute('''conversationList.onSelectConversation((event) => {
      event.preventDefault();
      window.flutter_inappwebview.callHandler("JSCSelectConversation", JSON.stringify(event));
    }); ''');
  }

  void _setFeedFilter() {
      _oldFeedFilter = ConversationPredicate.of(widget.feedFilter);

      execute('conversationList.setFeedFilter(${json.encode(_oldFeedFilter)});');
  }

  bool _checkFeedFilter() {
    if (widget.feedFilter != _oldFeedFilter) {
      _setFeedFilter();

      return true;
    }

    return false;
  }

  void _onWebViewCreated(InAppWebViewController controller) async {
    if (kDebugMode) {
      print('📗 conversationlist._onWebViewCreated');
    }

    controller.addJavaScriptHandler(handlerName: 'JSCSelectConversation', callback: _jscSelectConversation);
    controller.addJavaScriptHandler(handlerName: 'JSCLoadingState', callback: _jscLoadingState);

    String htmlData = await rootBundle.loadString('packages/talkjs_flutter/assets/index.html');
    Uri uri = Uri.dataFromString(htmlData, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    controller.loadUrl(urlRequest: URLRequest(url: uri));
  }

  void _onLoadStop(InAppWebViewController controller, Uri? url) async {
    if (kDebugMode) {
      print('📗 conversationlist._onLoadStop ($url)');
    }

    if ((url.toString() != 'about:blank') && (_webViewController == null)) {
      _webViewController = controller;

      // Wait for TalkJS to be ready
      final js = 'await Talk.ready;';

      if (kDebugMode) {
        print('📗 conversationlist._onLoadStop: $js');
      }

      await controller.callAsyncJavaScript(functionBody: js);

      // Execute any pending instructions
      for (var statement in _pending) {
        if (kDebugMode) {
          print('📗 conversationlist._onLoadStop _pending: $statement');
        }

        controller.evaluateJavascript(source: statement);
      }
    }
  }

  void _jscSelectConversation(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 conversationlist._jscSelectConversation: $message');
    }

    widget.onSelectConversation?.call(SelectConversationEvent.fromJson(json.decode(message)));
  }

  void _jscLoadingState(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 conversationlist._jscLoadingState: $message');
    }

    widget.onLoadingStateChanged?.call(LoadingState.loaded);
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Return a string with a unique ID
  String getUniqueId() {
    final id = _idCounter;

    _idCounter += 1;

    return '_$id';
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Returns the JavaScript variable name of the Talk.User object associated
  /// with the given [User]
  String getUserVariableName(User user) {
    if (_users[user.id] == null) {
      // Generate unique variable name
      final variableName = 'user${getUniqueId()}';

      execute('const $variableName = new Talk.User(${user.getJsonString()});');
      _users[user.id] = variableName;
    }

    return _users[user.id]!;
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Sets the options for ConversationListOptions for the properties where there exists
  /// both a declarative option and an imperative method
  void setExtraOptions(Map<String, dynamic> result) {
    result['feedFilter'] = widget.feedFilter;
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = _webViewController;

    if (kDebugMode) {
      print('📘 conversationlist.execute: $statement');
    }

    if (controller != null) {
      controller.evaluateJavascript(source: statement);
    } else {
      this._pending.add(statement);
    }
  }

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    execute('conversationList.destroy();');
  }
}

