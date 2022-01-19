import 'package:flutter/material.dart';

import './user.dart';
import './conversation.dart';

/// A session represents a currently active user.
class Session with ChangeNotifier {
  /// Your TalkJS AppId that can be found your TalkJS [dashboard](https://talkjs.com/dashboard).
  final String appId;

  /// The TalkJS [User] associated with the current user in your application.
  User? _me;

  User get me {
    if (_me == null) {
      throw StateError('Set the me property before using the Session object');
    } else {
      return _me!;
    }
  }

  set me(User user) {
    if (_me != null) {
      throw StateError('The me property has already been set for the Session object');
    } else {
      _me = user;
    }
  }

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  final String? signature;

  Session({required this.appId, this.signature});

  User getOrCreateUser({
    required String id,
    required String name,
    List<String>? email,
    List<String>? phone,
    String? availabilityText,
    String? locale,
    String? photoUrl,
    String? role,
    Map<String, String?>? custom,
    String? welcomeMessage,
  }) => User(
    session: this,
    id: id,
    name: name,
    email: email,
    phone: phone,
    availabilityText: availabilityText,
    locale: locale,
    photoUrl: photoUrl,
    role: role,
    custom: custom,
    welcomeMessage: welcomeMessage,
  );

  User getUserById(String id) => User.fromId(id, this);

  Conversation getOrCreateConversation({
    required String id,
    Map<String, String?>? custom,
    List<String>? welcomeMessages,
    String? photoUrl,
    String? subject,
    Set<Participant> participants = const <Participant>{},
  }) => Conversation(
    session: this,
    id: id,
    custom: custom,
    welcomeMessages: welcomeMessages,
    photoUrl: photoUrl,
    subject: subject,
    participants: participants,
  );
}

