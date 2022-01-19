import 'dart:ui';

import 'package:flutter/foundation.dart';

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

// Participants are users + options relative to this conversation
class Participant {
  final User user;

  final ParticipantAccess? access;

  final bool? notify;

  const Participant(this.user, {this.access, this.notify});

  Participant.of(Participant other)
    : user = User.of(other.user),
    access = other.access,
    notify = other.notify;

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is Participant)) {
      return false;
    }

    if (user != other.user) {
      return false;
    }

    if (access != other.access) {
      return false;
    }

    if (notify != other.notify) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(user, access, notify);
}

/// This represents a conversation that is about to be created, fetched, or
/// updated.
///
/// You can use this object to set up or modify a conversation before showing it.
/// Note: any changes you make here will not be sent to TalkJS immediately.
/// Instead, instantiate a TalkJS UI using methods such as [Session.createInbox].
class _BaseConversation {
  /// The unique conversation identifier.
  final String id;

  /// Custom metadata for this conversation
  final Map<String, String?>? custom;

  /// Messages sent at the beginning of a chat.
  ///
  /// The messages will appear as system messages.
  final List<String>? welcomeMessages;

  /// The URL to a photo which will be shown as the photo for the conversation.
  final String? photoUrl;

  /// The conversation subject which will be displayed in the chat header.
  final String? subject;

  const _BaseConversation({
    required this.id,
    this.custom,
    this.welcomeMessages,
    this.photoUrl,
    this.subject,
  });
}

class Conversation extends _BaseConversation {
  // The participants for this conversation
  final Set<Participant> participants;

  // To tie the conversation to a session
  final Session _session;

  const Conversation({
    required Session session,
    required String id,
    Map<String, String?>? custom,
    List<String>? welcomeMessages,
    String? photoUrl,
    String? subject,
    required this.participants,
  })
    : _session = session,
    super(
      id: id,
      custom: custom,
      welcomeMessages: welcomeMessages,
      photoUrl: photoUrl,
      subject: subject,
    );

  Conversation.of(Conversation other)
    : _session = other._session,
    participants = Set<Participant>.of(other.participants.map((participant) => Participant.of(participant))),
    super(
      id: other.id,
      custom: other.custom != null ? Map<String, String?>.of(other.custom!) : null,
      welcomeMessages: other.welcomeMessages != null ? List<String>.of(other.welcomeMessages!) : null,
      photoUrl: other.photoUrl,
      subject: other.subject
    );

/* TODO: conversation.sendMessage is to be rewritten so that it works when we don't show the WebView
  /// Sends a text message in a given conversation.
  void sendMessage(String text, {Map<String, String>? custom}) {
    final result = <String, dynamic>{};

    if (custom != null) {
      result['custom'] = custom;
    }

    session.execute('$variableName.sendMessage("$text", ${json.encode(result)});');
  }
  */

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is Conversation)) {
      return false;
    }

    if (_session != other._session) {
      return false;
    }

    if (!setEquals(participants, other.participants)) {
      return false;
    }

    if (id != other.id) {
      return false;
    }

    if (!mapEquals(custom, other.custom)) {
      return false;
    }

    if (!listEquals(welcomeMessages, other.welcomeMessages)) {
      return false;
    }

    if (photoUrl != other.photoUrl) {
      return false;
    }

    if (subject != other.subject) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(_session, participants, id, custom, welcomeMessages, photoUrl, subject);
}

class ConversationData extends _BaseConversation {
  ConversationData.fromJson(Map<String, dynamic> json)
    : super(id: json['id'],
    custom: json['custom'] != null ? Map<String, String?>.from(json['custom']) : null,
    welcomeMessages: json['welcomeMessages'] != null ? List<String>.from(json['welcomeMessages']) : null,
    photoUrl: json['photoUrl'],
    subject: json['subject']);
}

