import 'package:flutter/material.dart';

import './session.dart';

class ChatBox {
  late Session session;
  late String variableName;

  ChatBox({required this.session, required this.variableName});

  void destroy() {
    session.execute('$variableName.destroy();');
  }

  Widget mount() {
    session.execute(
        '$variableName.mount(document.getElementById("talkjs-container"));');
    return session.chatUI;
  }
}