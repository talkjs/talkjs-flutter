import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:webview_flutter/webview_flutter.dart';

import './session.dart';
import './conversation.dart';
import './user.dart';
import './predicate.dart';
import './chatbox.dart';
import './notification.dart';

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
  WebViewController? _webViewController;
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

      // Here a Timer is needed, as we can't change the widget's state while the widget
      // is being constructed, and the callback may very possibly change the state
      Timer.run(() => widget.onLoadingStateChanged?.call(LoadingState.loading));

      _createSession();
      _createConversationList();
      // feedFilter is set as an option for the inbox

      execute('conversationList.mount(document.getElementById("talkjs-container")).then(() => JSCLoadingState.postMessage("loaded"));');
    } else {
      // If it's not the first time that the widget is built,
      // then check what needs to be rebuilt

      // TODO: If something has changed in the Session we should do something
      _checkFeedFilter();
    }

    return WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      debuggingEnabled: kDebugMode,
      onWebViewCreated: _webViewCreatedCallback,
      onPageFinished: _onPageFinished,
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(name: 'JSCSelectConversation', onMessageReceived: _jscSelectConversation),
        JavascriptChannel(name: 'JSCLoadingState', onMessageReceived: _jscLoadingState),
      },
      gestureRecognizers: {
        // We need only the VerticalDragGestureRecognizer in order to be able to scroll through the conversations
        Factory(() => VerticalDragGestureRecognizer()),
      },
    );
  }

  void _createSession() {
    // Initialize Session object
    final options = <String, dynamic>{};

    options['appId'] = widget.session.appId;

    if (widget.session.signature != null) {
      options["signature"] = widget.session.signature;
    }

    execute('const options = ${json.encode(options)};');

    final variableName = getUserVariableName(widget.session.me);
    execute('options["me"] = $variableName;');

    execute('const session = new Talk.Session(options);');

    // TODO: This part has to be moved in the Session once we have the data layer SDK ready
    if (widget.session.enablePushNotifications) {
      if (fcmToken != null) {
        execute('session.setPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
      }

      if (apnsToken != null) {
        execute('session.setPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
      }
    } else {
      if (fcmToken != null) {
        execute('session.unsetPushRegistration({provider: "fcm", pushRegistrationId: "$fcmToken"});');
      }

      if (apnsToken != null) {
        execute('session.unsetPushRegistration({provider: "apns", pushRegistrationId: "$apnsToken"});');
      }
    }
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
      JSCSelectConversation.postMessage(JSON.stringify(event));
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

  void _webViewCreatedCallback(WebViewController webViewController) async {
    if (kDebugMode) {
      print('📗 conversationlist._webViewCreatedCallback');
    }

    String htmlData = await rootBundle.loadString('packages/talkjs_flutter/assets/index.html');
    Uri uri = Uri.dataFromString(htmlData, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    webViewController.loadUrl(uri.toString());

    _webViewController = webViewController;
  }

  void _onPageFinished(String url) {
    if (kDebugMode) {
      print('📗 conversationlist._onPageFinished');
    }

    if (url != 'about:blank') {
      // Wait for TalkJS to be ready
      // Not all WebViews support top level await, so it's better to use an
      // async IIFE
      final js = '(async function () { await Talk.ready; }());';

      if (kDebugMode) {
        print('📗 conversationlist._onPageFinished: $js');
      }

      _webViewController!.runJavascript(js);

      // Execute any pending instructions
      for (var statement in _pending) {
        if (kDebugMode) {
          print('📗 conversationlist._onPageFinished _pending: $statement');
        }

        _webViewController!.runJavascript(statement);
      }
    }
  }

  void _jscSelectConversation(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 conversationlist._jscSelectConversation: ${message.message}');
    }

    widget.onSelectConversation?.call(SelectConversationEvent.fromJson(json.decode(message.message)));
  }

  void _jscLoadingState(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 conversationlist._jscLoadingState: ${message.message}');
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
      controller.runJavascript(statement);
    } else {
      this._pending.add(statement);
    }
  }

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    execute('conversationList.destroy();');
  }
}

