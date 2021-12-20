import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../talkjs.dart';

import './chatoptions.dart';
import './conversation.dart';
import './ui.dart';
import './user.dart';
import './webview.dart';

/// A session represents a currently active user.
class Session {
  /// Your TalkJS AppId that can be found your TalkJS [dashboard](https://talkjs.com/dashboard).
  String appId;

  /// The TalkJS [User] associated with the current user in your application.
  User me;

  /// The widget for showing the various chat UI elements.
  late Widget chatUI;

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  String? signature;

  /// List of JavaScript statements that haven't been executed.
  final List<String> _pending = [];

  /// Used to control the underlying WebView
  WebViewController? _webViewController;

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  Map<String, String> _users = {};

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  Session({required this.appId, required this.me, this.signature}) {
    this.chatUI = ChatWebView(_webViewCreatedCallback, _onPageFinished);

    // Initialize Session object
    final options = <String, dynamic>{};

    options['appId'] = appId;

    if (signature != null) {
      options["signature"] = signature;
    }

    execute('const options = ${json.encode(options)};');

    final variableName = getUserVariableName(this.me);
    execute('options["me"] = $variableName;');

    execute('const session = new Talk.Session(options);');
  }

  void _webViewCreatedCallback(WebViewController webViewController) async {
    String htmlData = await rootBundle.loadString(
        'packages/talkjs/assets/index.html');
    Uri uri = Uri.dataFromString(htmlData, mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'));
    webViewController.loadUrl(uri.toString());

    this._webViewController = webViewController;
  }

  void _onPageFinished(String url) {
    if (url != 'about:blank') {
      // Wait for TalkJS to be ready
      // Not all WebViews support top level await, so it's better to use an
      // async IIFE
      final js = '(async function () { await Talk.ready; }());';

      if (kDebugMode) {
        print('📗 WebView DEBUG: $js');
      }

      this._webViewController!.evaluateJavascript(js);

      // Execute any pending instructions
      for (var statement in this._pending) {
        this._webViewController!.evaluateJavascript(statement);
      }
    }
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Return a string with a unique ID
  String getUniqueId() {
    final id = _idCounter;

    _idCounter += 1;

    return '_$id';
  }

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

  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = this._webViewController;

    if (kDebugMode) {
      print('📘 WebView DEBUG: $statement');
    }

    if (controller != null) {
      controller.evaluateJavascript(statement);
    } else {
      this._pending.add(statement);
    }
  }

  /// Disconnects all websockets, removes all UIs, and invalidates this session
  ///
  /// You cannot use any objects that were created in this session after you
  /// destroy it. If you want to use TalkJS after having called [destroy()]
  /// you must instantiate a new [Session] instance.
  void destroy() => execute('session.destroy();');

  /// Fetches an existing conversation or creates a new one.
  ///
  /// The [conversationId] is a unique identifier for this conversation,
  /// such as a channel name or topic ID. Any user with access to this ID can
  /// join this conversation.
  ///
  /// [Read about how to choose a good conversation ID for your use case.](https://talkjs.com/docs/Reference/Concepts/Conversations.html)
  /// If you want to make a simple one-on-one conversation, consider using
  /// [Talk.oneOnOneId] to generate one.
  ///
  /// Returns a [ConversationBuilder] that encapsulates a conversation between
  /// me (given in the constructor) and zero or more other participants.
  ConversationBuilder getOrCreateConversation(String conversationId) {
    // Generate unique variable name
    final variableName = 'conversation${getUniqueId()}';

    execute('const $variableName = session.getOrCreateConversation("$conversationId")');

    return ConversationBuilder(session: this, variableName: variableName);
  }

  /// Creates a [ChatBox] UI which shows a single conversation, without means to
  /// switch between conversations.
  ///
  /// Call [createChatbox] on any page you want to show a [ChatBox] of a single
  /// conversation.
  ChatBox createChatbox({ChatMode? chatSubtitleMode,
      ChatMode? chatTitleMode,
      TextDirection? dir,
      MessageFieldOptions? messageField,
      bool? showChatHeader,
      TranslationToggle? showTranslationToggle,
      String? theme,
      TranslateConversations? translateConversations,
      List<ConversationBuilder>? conversationsToTranslate,
      List<String>? conversationIdsToTranslate,
      }) {
    final options = ChatBoxOptions(chatSubtitleMode: chatSubtitleMode,
      chatTitleMode: chatTitleMode,
      dir: dir,
      messageField: messageField,
      showChatHeader: showChatHeader,
      showTranslationToggle: showTranslationToggle,
      theme: theme,
      translateConversations: translateConversations,
      conversationsToTranslate: conversationsToTranslate,
      conversationIdsToTranslate: conversationIdsToTranslate,
    );

    final variableName = 'chatBox${getUniqueId()}';

    execute('const $variableName = session.createChatbox(${options.getJsonString()});');

    return ChatBox(session: this, variableName: variableName);
  }

  /// Creates an [Inbox] which aside from providing a conversation UI, it can
  /// also show a user's other converations and switch between them.
  ///
  /// You typically want to call the [Inbox.mount] method after creating the
  /// [Inbox] to retrive the Widget needed to make it visible on your app.
  Inbox createInbox({InboxOptions? inboxOptions}) {
    final options = inboxOptions!; // TODO: change this to match the ChatBox

    final variableName = 'inbox${getUniqueId()}';

    execute('const $variableName = session.createInbox(${options.getJsonString()});');

    return Inbox(session: this, variableName: variableName);
  }
}

