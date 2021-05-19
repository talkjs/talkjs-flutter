import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import './chatoptions.dart';
import './conversation.dart';
import './ui.dart';
import './user.dart';
import './webview.dart';

const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';

class Session {
  String appId;
  User me;
  late Widget chatUI;

  String? signature;

  final List<String> _pending = [];
  WebViewController? _webViewController;

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

  void execute(String statement) {
    final controller = this._webViewController;
    if (controller != null) {
      controller.evaluateJavascript(statement);
    } else {
      this._pending.add(statement);
    }
  }

  void destroy() => execute('session.destroy();');

  ConversationBuilder getOrCreateConversation(String conversationId) {
    execute(
        'const conversation = session.getOrCreateConversation("$conversationId")');
    return ConversationBuilder(session: this, variableName: 'conversation');
  }

  ChatBox createChatbox(
      ConversationBuilder selectedConversation,
      {ChatBoxOptions? chatBoxOptions}) {
    final options = chatBoxOptions ?? {};
    execute('const chatBox = session.createChatbox('
        '${selectedConversation.variableName}, ${json.encode(options)});');

    return ChatBox(session: this, variableName: 'chatBox');
  }

  Inbox createInbox({InboxOptions? inboxOptions}) {
    final options = inboxOptions ?? {};
    execute('const inbox = session.createInbox(${json.encode(options)});');

    return Inbox(session: this, variableName: 'inbox');
  }

  Popup createPopup(
      ConversationBuilder conversation, {PopupOptions? popupOptions}) {
    final options = popupOptions ?? {};
    final variableName = 'popup';

    execute('const $variableName = session.createPopup('
      '${conversation.variableName}, ${json.encode(options)});');

    return Popup(session: this, variableName: variableName);
  }
}