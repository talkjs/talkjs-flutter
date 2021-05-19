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

enum ChatMode { subject, participants }

extension ChatModeString on ChatMode {
  String getValue() {
    late String result;
    switch (this) {
      case ChatMode.participants:
        result = 'participants';
        break;
      case ChatMode.subject:
        result = 'subject';
        break;
    }

    return result;
  }
}

enum TextDirection { rtl, ltr }

extension TextDirectionString on TextDirection {
  String getValue() {
    late String result;
    switch (this) {
      case TextDirection.rtl:
        result = 'rtl';
        break;
      case TextDirection.ltr:
        result = 'ltr';
        break;
    }

    return result;
  }
}

class MessageFieldOptions {
  bool autofocus; // Convert to "smart"
  bool enterSendsMessage;

  String? placeholder;
  bool spellcheck;

  MessageFieldOptions({this.autofocus = true, this.enterSendsMessage = true,
    this.placeholder, this.spellcheck = false
  });

  Map<String, dynamic> toJson() {
    final result = {
      'enterSendsMessage': enterSendsMessage,
      'placeholder': placeholder,
      'spellcheck': spellcheck
    };

    if (autofocus == true) {
      result['autofocus'] = 'smart';
    } else {
      result['autofocus'] = autofocus;
    }

    return result;
  }
}

class ChatBoxOptions {
  ChatMode chatSubtitleMode;
  ChatMode chatTitleMode;

  TextDirection dir;
  bool showChatHeader;

  MessageFieldOptions? messageField;

  ChatBoxOptions({this.chatSubtitleMode = ChatMode.subject,
    this.chatTitleMode = ChatMode.participants, this.dir = TextDirection.rtl,
    this.showChatHeader = true, this.messageField
  });

  Map<String, dynamic> toJson() => {
    'chatSubtitleMode': chatSubtitleMode.getValue(),
    'chatTitleMode': chatTitleMode.getValue(),
    'dir': dir.getValue(),
    'showChatHeader': showChatHeader,
    'messageField': messageField ?? {}
  };
}