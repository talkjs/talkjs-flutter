import 'package:flutter/material.dart';

import './session.dart';

abstract class UI {
  Session session;
  String variableName;

  UI({required this.session, required this.variableName});

  void destroy() {
    session.execute('$variableName.destroy();');
  }

  Widget mount() {
    session.execute(
        '$variableName.mount(document.getElementById("talkjs-container"));');
    return session.chatUI;
  }
}

class ChatBox extends UI {
  ChatBox({session, variableName})
      : super(session: session, variableName: variableName);
}

class Inbox extends UI {
  Inbox({session, variableName})
      : super(session: session, variableName: variableName);
}

class Popup extends UI {
  Popup({session, variableName})
      : super(session: session, variableName: variableName);
}