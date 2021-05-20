import 'dart:convert';

import './session.dart';
import './user.dart';

/// This represents a conversation that is about to be created, fetched, or
/// updated.
///
/// You can use this object to set up or modify a conversation before showing it.
/// Note: any changes you make here will not be sent to TalkJS immediately.
/// Instead, instantiate a TalkJS UI using methods such as [Session.createInbox].
class ConversationBuilder {
  /// Custom metadata for this conversation
  Map<String, String?>? custom;

  /// Messages sent at the beginning of a chat.
  ///
  /// The messages will appear as system messages.
  List<String>? welcomeMessages;

  /// The URL to a photo which will be shown as the photo for the conversation.
  String? photoUrl;

  /// The conversation subject which will be displayed in the chat header.
  String? subject;

  /// The current active TalkJS session.
  Session session;

  /// The JavaScript variable name for this object.
  String variableName;

  ConversationBuilder({required this.session, required this.variableName,
    this.custom, this.welcomeMessages, this.photoUrl, this.subject,
  });

  /// Sends a text message in a given conversation.
  void sendMessage(String text, MessageOptions options) {
    session.execute(
        '$variableName.sendMessage("$text", ${json.encode(options)});');
  }

  /// Used to set certain attributes for a specific conversation
  void setAttributes(ConversationAttributes attributes) {
    session.execute('$variableName.setAttributes(${json.encode(attributes)});');
  }

  /// Sets a participant of the conversation.
  void setParticipant(User user, {ParticipantSettings? participantSettings}) {
    final userName = session.getUserName(user);
    final settings = participantSettings ?? {};
    session.execute(
        '$variableName.setParticipant($userName, ${json.encode(settings)});');
  }
}

class MessageOptions {
  /// Custom data that you may wish to associate with a message.
  ///
  /// The custom data is sent back to you via webhooks and the REST API.
  Map<String, String?>? custom;

  MessageOptions({this.custom});

  Map<String, dynamic> toJson() => {
    'custom': custom ?? {}
  };
}

/// Conversation attributes that can be set using
/// [ConversationBuilder.setAttributes]
class ConversationAttributes {
  /// Custom metadata for a conversation.
  Map<String, String?>? custom;

  /// Messages sent at the beginning of a chat.
  ///
  /// The messages will appear as system messages.
  List<String>? welcomeMessages;

  /// The URL to a photo which will be shown as the photo for the conversation.
  String? photoUrl;

  /// The conversation subject which will be displayed in the chat header.
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

/// Possible values for participants' permissions
enum Access { read, readWrite }

extension StringConversion on Access {
  /// Converts this enum's values to String.
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
  /// Specifies the participant's access permission for a conversation.
  final Access? access;

  /// Specifies the participants's notification settings.
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