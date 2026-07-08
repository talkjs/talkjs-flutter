import 'dart:convert';

import 'package:flutter/foundation.dart';

import './session.dart';
import './user.dart';

/// Possible values for participants' permissions
enum ParticipantAccess {
  read,
  readWrite;

  /// Converts this enum's values to String.
  String getValue() => switch (this) {
    .read => 'Read',
    .readWrite => 'ReadWrite',
  };
}

/// Possible values for participants' notifications
enum ParticipantNotification {
  off,
  on,
  mentionsOnly;

  /// Converts this enum's values to String.
  dynamic getValue() => switch (this) {
    .off => false,
    .on => true,
    .mentionsOnly => 'MentionsOnly',
  };
}

// Participants are users + options relative to this conversation
class Participant {
  final User user;

  final ParticipantAccess? access;

  final ParticipantNotification? notify;

  const Participant(this.user, {this.access, this.notify});

  Participant.of(Participant other)
    : user = User.of(other.user),
      access = other.access,
      notify = other.notify;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Participant &&
        user == other.user &&
        access == other.access &&
        notify == other.notify;
  }

  @override
  int get hashCode => Object.hash(user, access, notify);
}

class SendMessageOptions {
  final Map<String, String?> custom;

  const SendMessageOptions({required this.custom});

  Map<String, dynamic> toJson() => {'custom': custom};
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

  bool _conversationCreated = false;

  Conversation({
    required Session session,
    required this.participants,
    required super.id,
    super.custom,
    super.welcomeMessages,
    super.photoUrl,
    super.subject,
  }) : _session = session;

  Conversation.of(Conversation other)
    : _session = other._session,
      participants = Set.of(other.participants.map(Participant.of)),
      super(
        id: other.id,
        custom: (other.custom != null ? Map.of(other.custom!) : null),
        welcomeMessages: (other.welcomeMessages != null
            ? List.of(other.welcomeMessages!)
            : null),
        photoUrl: other.photoUrl,
        subject: other.subject,
      );

  void _createConversation() {
    if (!_conversationCreated) {
      _session.execute(
        'conversations["${id}"] = session.getOrCreateConversation("${id}")',
      );

      _conversationCreated = true;
    }
  }

  /// Sends a text message in a given conversation.
  Future<void> sendMessage(String text, {SendMessageOptions? options}) {
    _createConversation();

    if (options != null) {
      _session.execute(
        'conversations["${id}"].sendMessage("$text", ${json.encode(options)});',
      );
    } else {
      _session.execute('conversations["${id}"].sendMessage("$text");');
    }

    // We return a Future, because we expect to refactor this code to use the Data Layer,
    // and handle failures as well.
    return Future<void>.value();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Conversation &&
        _session == other._session &&
        setEquals(participants, other.participants) &&
        id == other.id &&
        mapEquals(custom, other.custom) &&
        listEquals(welcomeMessages, other.welcomeMessages) &&
        photoUrl == other.photoUrl &&
        subject == other.subject;
  }

  @override
  int get hashCode => Object.hash(
    _session,
    Object.hashAllUnordered(participants),
    id,
    (custom != null ? Object.hashAllUnordered(custom!.entries) : custom),
    (welcomeMessages != null
        ? Object.hashAllUnordered(welcomeMessages!)
        : welcomeMessages),
    photoUrl,
    subject,
  );
}

class ConversationData extends _BaseConversation {
  ConversationData.fromJson(Map<String, dynamic> json)
    : super(
        id: json['id'],
        custom: (json['custom'] != null ? Map.from(json['custom']) : null),
        welcomeMessages: (json['welcomeMessages'] != null
            ? List.from(json['welcomeMessages'])
            : null),
        photoUrl: json['photoUrl'],
        subject: json['subject'],
      );
}
