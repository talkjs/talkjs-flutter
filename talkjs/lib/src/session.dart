import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../talkjs.dart';

import './chatoptions.dart';
import './conversation.dart';
import './ui.dart';
import './user.dart';
import './webview.dart';

const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';

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

  Session({required this.appId, required this.me, this.signature}) {
    this.chatUI = ChatWebView(_webViewCreatedCallback, _onPageFinished);

    // Initialize Session object
    final options = {'appId': appId};
    execute('const options = ${json.encode(options)};');

    final variableName = getUserName(this.me);
    execute('options["me"] = $variableName;');

    if (signature != null) {
      execute('options["signature"] = "$signature";');
    }

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
      // Execute any pending instructions
      for (var statement in this._pending) {
        this._webViewController!.evaluateJavascript(statement);
      }
    }
  }

  /// Returns the JavaScript variable name of the Talk.User object associated
  /// with the given [User]
  String getUserName(User user) {
    if (_users[user.id] == null) {
      // Generate random variable name
      final rand = Random();
      final characters = List.generate(
          15, (index) => chars[rand.nextInt(chars.length)]);
      final variableName = characters.join();

      execute('const $variableName = new Talk.User(${json.encode(me)});');
      _users[user.id] = variableName;
    }

    return _users[user.id]!;
  }

  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = this._webViewController;
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
    execute(
        'const conversation = session.getOrCreateConversation("$conversationId")');
    return ConversationBuilder(session: this, variableName: 'conversation');
  }

  /// Creates a [ChatBox] UI which shows a single conversation, without means to
  /// switch between conversations.
  ///
  /// Call [createChatbox] on any page you want to show a [ChatBox] of a single
  /// conversation.
  ChatBox createChatbox(
      ConversationBuilder selectedConversation,
      {ChatBoxOptions? chatBoxOptions}) {
    final options = chatBoxOptions ?? {};
    execute('const chatBox = session.createChatbox('
        '${selectedConversation.variableName}, ${json.encode(options)});');

    return ChatBox(session: this, variableName: 'chatBox');
  }

  /// Creates an [Inbox] which aside from providing a conversation UI, it can
  /// also show a user's other converations and switch between them.
  ///
  /// You typically want to call the [Inbox.mount] method after creating the
  /// [Inbox] to retrive the Widget needed to make it visible on your app.
  Inbox createInbox({InboxOptions? inboxOptions}) {
    final options = inboxOptions ?? {};
    execute('const inbox = session.createInbox(${json.encode(options)});');

    return Inbox(session: this, variableName: 'inbox');
  }

  /// Creates a [Popup] which is a well positioned box containing a conversation.
  ///
  /// It shows a single conversation, without means to switch between
  /// conversations.
  Popup createPopup(
      ConversationBuilder conversation, {PopupOptions? popupOptions}) {
    final options = popupOptions ?? {};
    final variableName = 'popup';

    execute('const $variableName = session.createPopup('
      '${conversation.variableName}, ${json.encode(options)});');

    return Popup(session: this, variableName: variableName);
  }
}