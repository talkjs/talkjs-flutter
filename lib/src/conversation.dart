import 'dart:convert';

import 'package:collection/collection.dart';

import './session.dart';
import './user.dart';

/// Possible values for participants' permissions
enum ParticipantAccess { Read, ReadWrite }

/// Possible values for participants' notifications
enum ParticipantNotification {
  Off,
  On,
  MentionsOnly;

  /// Converts this enum's values to String.
  dynamic getValue() => switch (this) {
    .Off => false,
    .On => true,
    .MentionsOnly => 'MentionsOnly',
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

  static const _mapEquality = MapEquality<String, String?>();
  static const _listEquality = ListEquality<String>();
  static const _unorderedIterableEquality =
      UnorderedIterableEquality<dynamic>();

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
        id == other.id &&
        photoUrl == other.photoUrl &&
        subject == other.subject &&
        _mapEquality.equals(custom, other.custom) &&
        _listEquality.equals(welcomeMessages, other.welcomeMessages) &&
        _unorderedIterableEquality.equals(participants, other.participants);
  }

  @override
  int get hashCode => Object.hash(
    _session,
    id,
    photoUrl,
    subject,
    _mapEquality.hash(custom),
    _listEquality.hash(welcomeMessages),
    _unorderedIterableEquality.hash(participants),
  );
}

class ConversationData extends _BaseConversation {
  final Map<String, ParticipantAccess> participants;

  ConversationData.fromJson(Map<String, dynamic> json)
    : participants = _participantAccessFromJson(json['participants']),
      super(
        id: json['id'],
        photoUrl: json['photoUrl'],
        subject: json['subject'],
        custom: (json['custom'] != null ? Map.from(json['custom']) : null),
        welcomeMessages: (json['welcomeMessages'] != null
            ? List.from(json['welcomeMessages'])
            : null),
      );
}

Map<String, ParticipantAccess> _participantAccessFromJson(Map<String, dynamic> json) => json.map(
  (key, value) => MapEntry(key, ParticipantAccess.values.byName(value['access']!)),
);
