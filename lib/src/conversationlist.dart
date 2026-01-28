import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:talkjs_flutter_inappwebview/talkjs_flutter_inappwebview.dart';

import './session.dart';
import './conversation.dart';
import './user.dart';
import './predicate.dart';
import './chatbox.dart';
import './webview_common.dart';
import './themeoptions.dart';

typedef SelectConversationHandler =
    void Function(SelectConversationEvent event);

class SelectConversationEvent {
  final ConversationData conversation;
  final UserData me;
  final List<UserData> others;

  SelectConversationEvent.fromJson(Map<String, dynamic> json)
    : conversation = ConversationData.fromJson(json['conversation']),
      me = UserData.fromJson(json['me']),
      others = json['others'].map(UserData.fromJson).toList();
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
  final ThemeOptions? themeOptions;

  const ConversationListOptions({
    this.showFeedHeader,
    this.theme,
    this.themeOptions,
  });

  @override
  String toString() {
    final Map<String, dynamic> result = {'showFeedHeader': ?showFeedHeader};

    if (themeOptions != null) {
      result['theme'] = themeOptions?.toJson();
    } else if (theme != null) {
      result['theme'] = theme;
    }

    return json.encode(result);
  }
}

class ConversationList extends StatefulWidget {
  final Session session;

  final bool enableZoom;

  final bool? showFeedHeader;

  final String? theme;
  final ThemeOptions? themeOptions;

  final BaseConversationPredicate? feedFilter;

  final SelectConversationHandler? onSelectConversation;
  final LoadingStateHandler? onLoadingStateChanged;
  final ErrorHandler? onError;

  const ConversationList({
    super.key,
    required this.session,
    this.enableZoom = false,
    this.showFeedHeader,
    this.theme,
    this.themeOptions,
    this.feedFilter,
    this.onSelectConversation,
    this.onLoadingStateChanged,
    this.onError,
  });

  @override
  State<ConversationList> createState() => ConversationListState();
}

class ConversationListState extends State<ConversationList> {
  /// Used to control the underlying WebView
  InAppWebViewController? _webViewController;
  bool _webViewCreated = false;

  /// List of JavaScript statements that haven't been executed.
  final List<String> _pending = [];

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  final Map<String, String> _users = {};

  /// Objects stored for comparing changes
  BaseConversationPredicate? _oldFeedFilter;
  bool _oldEnableZoom = true;

  late Future<String> userAgentFuture;

  @override
  void initState() {
    super.initState();

    userAgentFuture = Future.sync(() async {
      final version = await rootBundle.loadString(
        'packages/talkjs_flutter/assets/version.txt',
      );
      return 'TalkJS_Flutter/${version.trim().replaceAll('"', '')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('📗 conversationlist.build (_webViewCreated: $_webViewCreated)');
    }

    if (!_webViewCreated) {
      _webViewCreated = true;

      if (Platform.isAndroid) {
        InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
      }

      // Here a Timer is needed, as we can't change the widget's state while the widget
      // is being constructed, and the callback may very possibly change the state
      Timer.run(() => widget.onLoadingStateChanged?.call(LoadingState.loading));

      _updateEnableZoom();

      createSession(
        execute: execute,
        session: widget.session,
        variableName: getUserVariableName(widget.session.me),
      );
      _createConversationList();
      // feedFilter is set as an option for the inbox

      execute(
        'conversationList.mount(document.getElementById("talkjs-container")).then(() => window.flutter_inappwebview.callHandler("JSCLoadingState", "loaded"));',
      );
    } else {
      // If it's not the first time that the widget is built,
      // then check what needs to be rebuilt

      if (widget.enableZoom != _oldEnableZoom) {
        _updateEnableZoom();
      }

      // TODO: If something has changed in the Session we should do something
      _checkFeedFilter();
    }

    return FutureBuilder(
      future: userAgentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return InAppWebView(
            initialSettings: InAppWebViewSettings(
              useHybridComposition: true,
              disableInputAccessoryView: true,
              transparentBackground: true,
              applicationNameForUserAgent: snapshot.data,
              // Since iOS 16.4, this is required to enabled debugging the webview.
              isInspectable: kDebugMode,
            ),
            onWebViewCreated: _onWebViewCreated,
            onLoadStop: _onLoadStop,
            onConsoleMessage:
                (InAppWebViewController controller, ConsoleMessage message) {
                  if (kDebugMode) {
                    print(
                      "conversationlist [${message.messageLevel}] ${message.message}",
                    );
                  }

                  if (message.messageLevel == ConsoleMessageLevel.ERROR) {
                    widget.onError?.call(message.message);
                  }
                },
            gestureRecognizers: {
              // We need only the VerticalDragGestureRecognizer in order to be able to scroll through the conversations
              Factory(() => VerticalDragGestureRecognizer()),
            },
          );
        }

        // Return an empty widget otherwise
        return SizedBox.shrink();
      },
    );
  }

  void _updateEnableZoom() {
    var content = 'width=device-width, initial-scale=1.0';
    if (!widget.enableZoom) {
      content += ', user-scalable=no';
    }

    execute(
      '''document.querySelector('meta[name="viewport"]').setAttribute("content", "${content}");''',
    );

    _oldEnableZoom = widget.enableZoom;
  }

  void _createConversationList() {
    final options = ConversationListOptions(
      showFeedHeader: widget.showFeedHeader,
      theme: widget.theme,
      themeOptions: widget.themeOptions,
    );

    execute('const conversationList = session.createInbox(${options});');

    _setFeedFilter();

    execute('''conversationList.onSelectConversation((event) => {
      event.preventDefault();
      window.flutter_inappwebview.callHandler("JSCSelectConversation", JSON.stringify(event));
    }); ''');
  }

  void _setFeedFilter() {
    _oldFeedFilter = widget.feedFilter?.clone();

    if (_oldFeedFilter != null) {
      execute(
        'conversationList.setFeedFilter(${json.encode(_oldFeedFilter)});',
      );
    } else {
      execute('conversationList.setFeedFilter({});');
    }
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

    controller.addJavaScriptHandler(
      handlerName: 'JSCSelectConversation',
      callback: _jscSelectConversation,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCLoadingState',
      callback: _jscLoadingState,
    );
    controller.addJavaScriptHandler(
      handlerName: 'JSCTokenFetcher',
      callback: _jscTokenFetcher,
    );

    String htmlData = await rootBundle.loadString(
      'packages/talkjs_flutter/assets/index.html',
    );
    controller.loadData(
      data: htmlData,
      baseUrl: WebUri("https://app.talkjs.com"),
    );
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (kDebugMode) {
      print('📗 conversationlist._onLoadStop ($url)');
    }

    if (_webViewController == null) {
      _webViewController = controller;

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

    widget.onSelectConversation?.call(
      SelectConversationEvent.fromJson(json.decode(message)),
    );
  }

  void _jscLoadingState(List<dynamic> arguments) {
    final message = arguments[0];

    if (kDebugMode) {
      print('📗 conversationlist._jscLoadingState: $message');
    }

    widget.onLoadingStateChanged?.call(LoadingState.loaded);
  }

  Future<String> _jscTokenFetcher(List<dynamic> arguments) {
    if (kDebugMode) {
      print('📗 conversationlist._jscTokenFetcher');
    }

    return widget.session.tokenFetcher!();
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
  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = _webViewController;

    if (controller != null) {
      if (kDebugMode) {
        print('📗 conversationlist.execute: $statement');
      }

      controller.evaluateJavascript(source: statement);
    } else {
      if (kDebugMode) {
        print('📘 conversationlist.execute: $statement');
      }

      this._pending.add(statement);
    }
  }

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    execute('conversationList.destroy();');
  }
}
