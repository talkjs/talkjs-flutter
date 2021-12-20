import 'dart:convert';

import './session.dart';
import './user.dart';

/// Possible values for participants' permissions
enum ParticipantAccess { read, readWrite }

extension ParticipantAccessString on ParticipantAccess {
  /// Converts this enum's values to String.
  String getValue() {
    switch (this) {
      case ParticipantAccess.read:
        return 'Read';
      case ParticipantAccess.readWrite:
        return 'ReadWrite';
    }
  }
}

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

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// The current active TalkJS session.
  Session session;

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// The JavaScript variable name for this object.
  String variableName;

  /// Don't use the ConversationBuilder constructor directly.
  // use session.getOrCreateConversation instead.
  ConversationBuilder({required this.session, required this.variableName,
    this.custom, this.welcomeMessages, this.photoUrl, this.subject,
  });

  /// Sends a text message in a given conversation.
  void sendMessage(String text, {Map<String, String>? custom}) {
    final result = <String, dynamic>{};

    if (custom != null) {
      result['custom'] = custom;
    }

    session.execute('$variableName.sendMessage("$text", ${json.encode(result)});');
  }

  /// Used to set certain attributes for a specific conversation
  void setAttributes({Map<String, String?>? custom, List<String>? welcomeMessages, String? photoUrl, String? subject}) {
    final result = <String, dynamic>{};

    if (custom != null) {
      result['custom'] = custom;
      this.custom = custom;
    }

    if (welcomeMessages != null) {
      result['welcomeMessages'] = welcomeMessages;
      this.welcomeMessages = welcomeMessages;
    }

    if (photoUrl != null) {
      result['photoUrl'] = photoUrl;
      this.photoUrl = photoUrl;
    }

    if (subject != null) {
      result['subject'] = subject;
      this.subject = subject;
    }

    session.execute('$variableName.setAttributes(${json.encode(result)});');
  }

  /// Sets a participant of the conversation.
  void setParticipant(User user, {ParticipantAccess? access, bool? notify}) {
    final userVariableName = session.getUserVariableName(user);
    final result = <String, dynamic>{};

    if (access != null) {
      result['access'] = access.getValue();
    }

    if (notify != null) {
      result['notify'] = notify;
    }

    session.execute('$variableName.setParticipant($userVariableName, ${json.encode(result)});');
  }
}

