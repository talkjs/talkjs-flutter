import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:webview_flutter/webview_flutter.dart';

import './session.dart';
import './conversation.dart';
import './user.dart';

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

    return json.encode(result);
  }
}

class ConversationList extends StatefulWidget {
  final Session session;

  final bool? showFeedHeader;

  final String? theme;

  final SelectConversationHandler? onSelectConversation;

  const ConversationList({
    Key? key,
    required this.session,
    this.showFeedHeader,
    this.theme,
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

    if (!_webViewCreated) {
      _webViewCreated = true;

      _createSession();
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
        JavascriptChannel(name: 'JSCSelectConversation', onMessageReceived: _jscSelectConversation),
    });
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
  }

  void _createConversationList() {
    final options = ConversationListOptions(
      showFeedHeader: widget.showFeedHeader,
      theme: widget.theme,
    );

    execute('const conversationList = session.createInbox(${options.getJsonString(this)});');

    execute('''conversationList.on("selectConversation", (event) => {
      event.preventDefault();
      JSCSelectConversation.postMessage(JSON.stringify(event));
    }); ''');
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

  void _jscSelectConversation(JavascriptMessage message) {
    if (kDebugMode) {
      print('📗 conversationlist._jscSelectConversation: ${message.message}');
    }

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

