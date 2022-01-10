import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:webview_flutter/webview_flutter.dart';

import 'package:provider/provider.dart';

import './session.dart';
import './conversation.dart';
import './user.dart';
import './chatbox.dart';

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

/// The possible values for the Chat modes
enum ConversationTitleMode { subject, participants, auto }

extension ConversationTitleModeString on ConversationTitleMode {
  /// Converts this enum's values to String.
  String getValue() {
    switch (this) {
      case ConversationTitleMode.participants:
        return 'participants';
      case ConversationTitleMode.subject:
        return 'subject';
      case ConversationTitleMode.auto:
        return 'auto';
    }
  }
}

class ConversationListOptions {
  /// Controls if the feed header containing the toggle to enable desktop notifications is shown.
  /// Defaults to true.
  bool? showFeedHeader;

  /// Controls how a chat is displayed in the feed of chats.
  ///
  /// Note: when set to `"subject"` but a conversation has no subject set, then
  /// TalkJS falls back to `"participants"`.
  ///
  /// When not set, defaults to `"auto"`, which means that in group conversations
  /// that have a subject set, the subject is displayed and otherwise the participants.
  ConversationTitleMode? feedConversationTitleMode;

  /// Controls whether the user navigating between conversation should count
  /// as steps in the browser history. Defaults to true, which means that if the user
  /// clicks the browser's back button, they go back to the previous conversation
  /// (if any).
  ///
  /// NOT NEEDED FOR FLUTTER?
  //bool? useBrowserHistory;

  /// Used to control which conversations are shown in the conversation feed, depending on access
  /// level, custom conversation attributes or message read status.
  ///
  /// See ConversationPredicate for all available options.
  ///
  /// You can also modify the filter on the fly using {@link Inbox.setFeedFilter}.
  ///
  /// TODO: NOT YET IMPLEMENTED FOR FLUTTER
  //ConversationPredicate? feedFilter;

  /// Whether to show a "Back" button at the top of the chat screen on mobile devices.
  ///
  /// NOT NEEDED FOR FLUTTER?
  //bool? showMobileBackButton;

  /// Overrides the theme used for this chat UI.
  String? theme;

  ConversationListOptions({this.showFeedHeader, this.feedConversationTitleMode, this.theme});

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

    if (feedConversationTitleMode != null) {
      result['feedConversationTitleMode'] = feedConversationTitleMode!.getValue();
    }

    if (theme != null) {
      result['theme'] = theme;
    }

    return json.encode(result);
  }
}

class ConversationList extends StatefulWidget {
  final bool? showFeedHeader;
  final ConversationTitleMode? feedConversationTitleMode;

  final String? theme;

  final BlurHandler? onBlur;
  final FocusHandler? onFocus;
  final SelectConversationHandler? onSelectConversation;

  const ConversationList({Key? key,
      this.showFeedHeader,
      this.feedConversationTitleMode,
      this.theme,
      this.onBlur,
      this.onFocus,
      this.onSelectConversation,
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

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('📗 conversationlist.build (_webViewCreated: $_webViewCreated)');
    }

    final sessionState = context.read<SessionState>();

    if (!_webViewCreated) {
      _webViewCreated = true;

      _createSession(sessionState);
      _createConversationList();

      execute('conversationList.mount(document.getElementById("talkjs-container"));');
    }

    return WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      debuggingEnabled: kDebugMode,
      onWebViewCreated: _webViewCreatedCallback,
      onPageFinished: _onPageFinished,
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(name: 'JSCBlur', onMessageReceived: _jscBlur),
        JavascriptChannel(name: 'JSCFocus', onMessageReceived: _jscFocus),
        JavascriptChannel(name: 'JSCSelectConversation', onMessageReceived: _jscSelectConversation),
    });
  }

  void _createSession(SessionState sessionState) {
    // Initialize Session object
    final options = <String, dynamic>{};

    options['appId'] = sessionState.appId;

    if (sessionState.signature != null) {
      options["signature"] = sessionState.signature;
    }

    execute('const options = ${json.encode(options)};');

    final variableName = getUserVariableName(sessionState.me);
    execute('options["me"] = $variableName;');

    execute('const session = new Talk.Session(options);');
  }

  void _createConversationList() {
    final options = ConversationListOptions(
      showFeedHeader: widget.showFeedHeader,
      feedConversationTitleMode: widget.feedConversationTitleMode,
      theme: widget.theme,
    );

    execute('const conversationList = session.createInbox(${options.getJsonString(this)});');

    execute('conversationList.on("blur", (event) => JSCBlur.postMessage(JSON.stringify(event)));');
    execute('conversationList.on("focus", (event) => JSCFocus.postMessage(JSON.stringify(event)));');
    execute('conversationList.on("selectConversation", (event) => JSCSelectConversation.postMessage(JSON.stringify(event)));');
  }

  void _webViewCreatedCallback(WebViewController webViewController) async {
    if (kDebugMode) {
      print('📗 conversationlist._webViewCreatedCallback');
    }

    String htmlData = await rootBundle.loadString('packages/talkjs/assets/index.html');
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

  void _jscBlur(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 conversationlist._jscBlur: ${message.message}');
    }

    widget.onBlur?.call();
  }

  void _jscFocus(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 conversationlist._jscFocus: ${message.message}');
    }

    widget.onFocus?.call();
  }

  void _jscSelectConversation(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 conversationlist._jscSelectConversation: ${message.message}');
    }

    execute('conversationList.select(null);');

    widget.onSelectConversation?.call(SelectConversationEvent.fromJson(json.decode(message.message)));
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

