import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:webview_flutter/webview_flutter.dart';

import 'package:provider/provider.dart';

import './session.dart';
import './conversation.dart';
import './webview.dart';
import './chatoptions.dart';
import './user.dart';

/// A messaging UI for just a single conversation.
///
/// Create a Chatbox through [Session.createChatbox] and then call [mount] to show it.
/// There is no way for the user to switch between conversations
class ChatBox extends StatefulWidget {
  final ChatMode? chatSubtitleMode;
  final ChatMode? chatTitleMode;
  final TextDirection? dir;
  final MessageFieldOptions? messageField;
  final bool? showChatHeader;
  final TranslationToggle? showTranslationToggle;
  final String? theme;
  final TranslateConversations? translateConversations;
  final List<Conversation>? conversationsToTranslate;
  final List<String>? conversationIdsToTranslate;

  final Conversation? conversation;
  final bool? asGuest;

  const ChatBox({Key? key,
      this.chatSubtitleMode,
      this.chatTitleMode,
      this.dir,
      this.messageField,
      this.showChatHeader,
      this.showTranslationToggle,
      this.theme,
      this.translateConversations,
      this.conversationsToTranslate,
      this.conversationIdsToTranslate,
      this.conversation,
      this.asGuest,
    }) : super(key: key);

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  /// Used to control the underlying WebView
  WebViewController? _webViewController;

  /// List of JavaScript statements that haven't been executed.
  final List<String> _pending = [];

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  final _users = <String, String>{};

  /// A mapping of conversation ids to the variable name of the respective JavaScript
  /// Talk.ConversationBuilder object.
  final _conversations = <String, String>{};

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  /// Encapsulates the message entry field tied to the currently selected conversation.
  // TODO: messageField still needs to be refactored
  //late MessageField messageField;

  @override
  Widget build(BuildContext context) {
    final sessionState = context.read<SessionState>();

    _createSession(sessionState);
    _createChatBox();
    _createConversation();

    execute('chatBox.mount(document.getElementById("talkjs-container"));');

    return ChatWebView(_webViewCreatedCallback, _onPageFinished);
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

  void _createChatBox() {
    final options = ChatBoxOptions(
      chatSubtitleMode: widget.chatSubtitleMode,
      chatTitleMode: widget.chatTitleMode,
      dir: widget.dir,
      messageField: widget.messageField,
      showChatHeader: widget.showChatHeader,
      showTranslationToggle: widget.showTranslationToggle,
      theme: widget.theme,
      translateConversations: widget.translateConversations,
      conversationsToTranslate: widget.conversationsToTranslate,
      conversationIdsToTranslate: widget.conversationIdsToTranslate,
    );

    execute('const chatBox = session.createChatbox(${options.getJsonString()});');
  }

  void _createConversation() {
      final result = <String, dynamic>{};

      if (widget.asGuest != null) {
        result['asGuest'] = widget.asGuest;
      }

      if (widget.conversation != null) {
        execute('chatBox.select(${getConversationVariableName(widget.conversation!)}, ${json.encode(result)});');
      } else {
        // TODO: null or undefined?
        execute('chatBox.select(null, ${json.encode(result)});');
      }
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

  String getConversationVariableName(Conversation conversation) {
    if (_conversations[conversation.id] == null) {
      // STEP 1: Generate unique variable name
      final variableName = 'conversation${getUniqueId()}';

      execute('const $variableName = session.getOrCreateConversation("${conversation.id}")');

      // STEP 2: Attributes
      final attributes = <String, dynamic>{};

      if (conversation.custom != null) {
        attributes['custom'] = conversation.custom;
      }

      if (conversation.welcomeMessages != null) {
        attributes['welcomeMessages'] = conversation.welcomeMessages;
      }

      if (conversation.photoUrl != null) {
        attributes['photoUrl'] = conversation.photoUrl;
      }

      if (conversation.subject != null) {
        attributes['subject'] = conversation.subject;
      }

      if (attributes.isNotEmpty) {
        execute('$variableName.setAttributes(${json.encode(attributes)});');
      }

      // STEP 3: Participants
      for (var participant in conversation.participants) {
        final userVariableName = getUserVariableName(participant.user);
        final result = <String, dynamic>{};

        if (participant.access != null) {
          result['access'] = participant.access!.getValue();
        }

        if (participant.notify != null) {
          result['notify'] = participant.notify;
        }

        execute('$variableName.setParticipant($userVariableName, ${json.encode(result)});');
      }

      _conversations[conversation.id] = variableName;
    }

    return _conversations[conversation.id]!;
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

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    execute('chatBox.destroy();');
  }

/*
  void select(ConversationBuilder? conversation, {bool? asGuest}) {
    final result = <String, dynamic>{};

    if (asGuest != null) {
      result['asGuest'] = asGuest;
    }

    if (conversation != null) {
      execute('chatBox.select(${conversation.variableName}, ${json.encode(result)});');
    } else {
      execute('chatBox.select(null, ${json.encode(result)});');
    }
  }

  void selectLatestConversation({bool? asGuest}) {
    final result = <String, dynamic>{};

    if (asGuest != null) {
      result['asGuest'] = asGuest;
    }

    execute('chatBox.select(undefined, ${json.encode(result)});');
  }
*/
}

/// Encapsulates the message entry field tied to the currently selected conversation.
class MessageField {
  /// The ChatBox associated with this message field
  _ChatBoxState chatbox;

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

