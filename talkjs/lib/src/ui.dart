import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:webview_flutter/webview_flutter.dart';

import './session.dart';
import './conversation.dart';
import './webview.dart';

/// A messaging UI for just a single conversation.
///
/// Create a Chatbox through [Session.createChatbox] and then call [mount] to show it.
/// There is no way for the user to switch between conversations
class ChatBox {
  /// Used to control the underlying WebView
  WebViewController? _webViewController;

  /// List of JavaScript statements that haven't been executed.
  final List<String> _pending = [];

  bool _mounted = false;

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// The current active TalkJS session.
  Session session;

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// The JavaScript variable name for this object.
  String variableName;

  /// Encapsulates the message entry field tied to the currently selected conversation.
  late MessageField messageField;

  ChatBox({required this.session, required this.variableName}) {
    // TODO: It wouldn't be a bad idea to break the ChatBox<->MessageField circular reference
    // at object destruction (if possible)
    this.messageField = MessageField(chatbox: this, variableName: "$variableName.messageField");
  }

  void _webViewCreatedCallback(WebViewController webViewController) async {
    String htmlData = await rootBundle.loadString('packages/talkjs/assets/index.html');
    Uri uri = Uri.dataFromString(htmlData, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));
    webViewController.loadUrl(uri.toString());

    _webViewController = webViewController;
  }

  void _onPageFinished(String url) {
    if (url != 'about:blank') {
      // Wait for TalkJS to be ready
      // Not all WebViews support top level await, so it's better to use an
      // async IIFE
      final js = '(async function () { await Talk.ready; }());';

      if (kDebugMode) {
        print('📗 chatbox._onPageFinished: $js');
      }

      _webViewController!.runJavascriptReturningResult(js);

      // Execute any pending instructions
      for (var statement in _pending) {
        if (kDebugMode) {
          print('📗 chatbox._onPageFinished _pending: $statement');
        }

        _webViewController!.runJavascriptReturningResult(statement);
      }
    }
  }

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// Evaluates the JavaScript statement given.
  void execute(String statement) {
    final controller = _webViewController;

    if (kDebugMode) {
      print('📘 chatbox.execute: $statement');
    }

    if (controller != null) {
      controller.runJavascriptReturningResult(statement);
    } else {
      this._pending.add(statement);
    }
  }

  void disposeWebView() {
    if (kDebugMode) {
      print('📘 chatbox.disposeWebView');
    }

    _webViewController = null;
  }

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    execute('$variableName.destroy();');
  }

  void select(ConversationBuilder? conversation, {bool? asGuest}) {
    final result = <String, dynamic>{};

    if (asGuest != null) {
      result['asGuest'] = asGuest;
    }

    if (conversation != null) {
      execute('$variableName.select(${conversation.variableName}, ${json.encode(result)});');
    } else {
      execute('$variableName.select(null, ${json.encode(result)});');
    }
  }

  void selectLatestConversation({bool? asGuest}) {
    final result = <String, dynamic>{};

    if (asGuest != null) {
      result['asGuest'] = asGuest;
    }

    execute('$variableName.select(undefined, ${json.encode(result)});');
  }

  /// Renders the UI and returns the Widget containing it.
  Widget mount() {
    assert(_webViewController == null);

    if (kDebugMode) {
      print('📘 chatbox.mount');
    }

    if (!_mounted) {
      execute('$variableName.mount(document.getElementById("talkjs-container"));');

      _mounted = true;
    }

    return ChatWebView(this, _webViewCreatedCallback, _onPageFinished);
  }
}

/// Encapsulates the message entry field tied to the currently selected conversation.
class MessageField {
  /// The ChatBox associated with this message field
  ChatBox chatbox;

  /// The JavaScript variable name for this object.
  String variableName;

  MessageField({required this.chatbox, required this.variableName});

  /// Focuses the message entry field.
  ///
  /// Note that on mobile devices, this will cause the on-screen keyboard to pop up, obscuring part
  /// of the screen.
  void focus() {
    chatbox.execute('$variableName.focus();');
  }

  /// Sets the message field to `text`.
  ///
  /// Useful if you want to guide your user with message suggestions. If you want to start a UI
  /// with a given text showing immediately, call this method before calling Inbox.mount
  void setText(String text) {
    chatbox.execute('$variableName.setText("$text");');
  }

  /// TODO: setVisible(visible: boolean | ConversationPredicate): void;
}

