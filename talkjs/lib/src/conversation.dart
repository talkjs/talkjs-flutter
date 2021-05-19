import 'dart:convert';

import './session.dart';
import './user.dart';

class ConversationBuilder {
  Map<String, String?>? custom;
  List<String>? welcomeMessages;

  String? photoUrl;
  String? subject;

  Session session;
  String variableName;

  ConversationBuilder({required this.session, required this.variableName,
    this.custom, this.welcomeMessages, this.photoUrl, this.subject,
  });

  void sendMessage(String text, MessageOptions options) {
    session.execute(
        '$variableName.sendMessage("$text", ${json.encode(options)});');
  }

  void setAttributes(ConversationAttributes attributes) {
    session.execute('$variableName.setAttributes(${json.encode(attributes)});');
  }

  void setParticipant(User user, {ParticipantSettings? participantSettings}) {
    final userName = session.getUserName(user);
    final settings = participantSettings ?? {};
    session.execute(
        '$variableName.setParticipant($userName, ${json.encode(settings)});');
  }
}

class MessageOptions {
  Map<String, String?>? custom;

  MessageOptions({this.custom});

  Map<String, dynamic> toJson() => {
    'custom': custom ?? {}
  };
}

class ConversationAttributes {
  Map<String, String?>? custom;
  List<String>? welcomeMessages;

  String? photoUrl;
  String? subject;

  ConversationAttributes({this.custom, this.welcomeMessages, this.photoUrl,
    this.subject
  });

  Map<String, dynamic> toJson() => {
    'custom': custom,
    'welcomeMessages': welcomeMessages,
    'photoUrl': photoUrl,
    'subject': subject
  };
}

enum Access { read, readWrite }

extension StringConversion on Access {
  String getValue() {
    late String result;
    switch (this) {
      case Access.read:
        result = 'Read';
        break;
      case Access.readWrite:
        result = 'ReadWrite';
        break;
    }
    return result;
  }
}

class ParticipantSettings {
  final Access? access;
  final bool? notify;

  const ParticipantSettings({this.access, this.notify});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};

    if (access != null) {
      result['access'] = access!.getValue();
    }

    if (notify != null) {
      result['notify'] = notify;
    }

    return result;
  }
}