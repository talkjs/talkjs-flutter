import 'dart:convert';
import 'package:flutter/material.dart';

import './session.dart';
import './conversation.dart';

/// Encapsulates the message entry field tied to the currently selected conversation.
class MessageField {
  /// The current active TalkJS session.
  Session session;

  /// The JavaScript variable name for this object.
  String variableName;

  MessageField({required this.session, required this.variableName});

  /// Focuses the message entry field.
  ///
  /// Note that on mobile devices, this will cause the on-screen keyboard to pop up, obscuring part
  /// of the screen.
  void focus() {
    session.execute('$variableName.focus();');
  }

  /// Sets the message field to `text`.
  ///
  /// Useful if you want to guide your user with message suggestions. If you want to start a UI
  /// with a given text showing immediately, call this method before calling Inbox.mount
  void setText(String text) {
    session.execute('$variableName.setText("$text");');
  }

  /// TODO: setVisible(visible: boolean | ConversationPredicate): void;
}

/// This class represents the various UI elements that TalkJS supports and the
/// methods common to all.
abstract class _UI {
  /// The current active TalkJS session.
  Session session;

  /// The JavaScript variable name for this object.
  String variableName;

  /// Encapsulates the message entry field tied to the currently selected conversation.
  MessageField messageField;

  _UI({required this.session, required this.variableName})
    : this.messageField = MessageField(session: session, variableName: "$variableName.messageField");

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    session.execute('$variableName.destroy();');
  }

  void select(ConversationBuilder? conversation, {bool? asGuest}) {
    final result = <String, dynamic>{};

    if (asGuest != null) {
      result['asGuest'] = asGuest;
    }

    if (conversation != null) {
      session.execute('$variableName.select(${conversation.variableName}, ${json.encode(result)});');
    } else {
      session.execute('$variableName.select(null, ${json.encode(result)});');
    }
  }

  void selectLatestConversation({bool? asGuest}) {
    final result = <String, dynamic>{};

    if (asGuest != null) {
      result['asGuest'] = asGuest;
    }

    session.execute('$variableName.select(undefined, ${json.encode(result)});');
  }

  /// Renders the UI and returns the Widget containing it.
  Widget mount() {
    session.execute('$variableName.mount(document.getElementById("talkjs-container"));');

    return session.chatUI;
  }
}

/// A messaging UI for just a single conversation.
///
/// Create a Chatbox through [Session.createChatbox] and then call [mount] to show it.
/// There is no way for the user to switch between conversations
class ChatBox extends _UI {
  ChatBox({session, variableName})
      : super(session: session, variableName: variableName);
}

/// The main messaging UI component of TalkJS.
///
/// It shows a user's conversation history and it allows them to write messages.
/// Create an Inbox through [Session.createInbox] and then call [mount] to show it.
class Inbox extends _UI {
  Inbox({session, variableName})
      : super(session: session, variableName: variableName);
}

