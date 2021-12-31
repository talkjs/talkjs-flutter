import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;

import './chatoptions.dart';
import './conversation.dart';
import './ui.dart';
import './user.dart';

/// A session represents a currently active user.
class Session {
  /// Your TalkJS AppId that can be found your TalkJS [dashboard](https://talkjs.com/dashboard).
  String appId;

  /// The TalkJS [User] associated with the current user in your application.
  User me;

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  String? signature;

  /// List of JavaScript statements that haven't been executed.
  final _pending = <String>[];

  /// A mapping of user ids to the variable name of the respective JavaScript
  /// Talk.User object.
  final _users = <String, String>{};

  // A counter to ensure that IDs are unique
  int _idCounter = 0;

  ChatBox? chatbox;

  Session({required this.appId, required this.me, this.signature}) {
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
    if (kDebugMode) {
      print('📘 session.execute: $statement');
    }

    this._pending.add(statement);
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

    final chatbox = ChatBox(session: this, variableName: variableName);

    // STEP 1: Tell the WebView of the ChatBox to do all that needs to be done
    for (var statement in _pending) {
      chatbox.execute(statement);
    }

    // STEP 2: Tell the WebView of the ChatBox to create the ChatBox
    chatbox.execute('const $variableName = session.createChatbox(${options.getJsonString()});');

    return chatbox;
  }
}

