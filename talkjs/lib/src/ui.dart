import 'package:flutter/material.dart';

import './session.dart';

/// This class represents the various UI elements that TalkJS supports and the
/// methods common to all.
abstract class _UI {
  /// The current active TalkJS session.
  Session session;

  /// The JavaScript variable name for this object.
  String variableName;

  _UI({required this.session, required this.variableName});

  /// Destroys this UI element and removes all event listeners it has running.
  void destroy() {
    session.execute('$variableName.destroy();');
  }

  /// Renders the UI and returns the Widget containing it.
  Widget mount() {
    session.execute(
        '$variableName.mount(document.getElementById("talkjs-container"));');
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

/// A messaging UI for just a single conversation.
///
/// Create a Popup through [Session.createPopup] and then call [mount] to show it.
/// There is no way for the user to switch between conversations
class Popup extends _UI {
  Popup({session, variableName})
      : super(session: session, variableName: variableName);
}