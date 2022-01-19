import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import './session.dart';

/// A user of your app.
///
/// TalkJS uses the [id] to uniquely identify this user. All other fields of a
/// [User] are allowed to vary over time and the TalkJS database will update its
/// fields accordingly.
class _BaseUser {
  /// The default message a user sees when starting a chat with this person.
  ///
  /// This acts similarly to [welcomeMessage] with the difference being that
  /// this appears as a system message.
  final String? availabilityText;

  /// Custom metadata for this user.
  final Map<String, String?>? custom;

  /// One or more email address belonging to this user.
  ///
  /// The email addresses will be used for [Email Notifications](https://talkjs.com/docs/Features/Notifications/Email_Notifications/index.html)
  /// if they are enabled.
  final List<String>? email;

  /// One or more phone numbers belonging to this user.
  ///
  /// The phone numbers will be used for [SMS Notifications](https://talkjs.com/docs/Features/Notifications/SMS_Notifications.html).
  /// This feature requires standard plan and up.
  final List<String>? phone;

  /// The unique user identifier.
  final String id;

  /// This user's name which will be displayed on the TalkJS UI
  final String name;

  /// The language on the UI.
  ///
  /// This field expects an [IETF language tag](https://www.w3.org/International/articles/language-tags/).
  final String? locale;

  /// An optional URL to a photo which will be displayed as this user's avatar
  final String? photoUrl;

  /// This user's role which allows you to change the behaviour of TalkJS for
  /// different users.
  final String? role;

  /// The default message a user sees when starting a chat with this person.
  final String? welcomeMessage;

  const _BaseUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.availabilityText,
    this.locale,
    this.photoUrl,
    this.role,
    this.custom,
    this.welcomeMessage,
  });
}

class User extends _BaseUser {
  // To support creating users with only an id
  final bool _idOnly;

  // To tie the user to a session
  final Session _session;

  const User({
    required Session session,
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
  })
    : _session = session,
    _idOnly = false,
    super(
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

  const User.fromId(String id, Session session) : _session = session, _idOnly = true, super(id: id, name: '');

  User.of(User other)
    : _session = other._session,
    _idOnly = other._idOnly,
    super(
      id: other.id,
      name: other.name,
      email: other.email != null ? List<String>.of(other.email!) : null,
      phone: other.phone != null ? List<String>.of(other.phone!) : null,
      availabilityText: other.availabilityText,
      locale: other.locale,
      photoUrl: other.photoUrl,
      role: other.role,
      custom: other.custom != null ? Map<String, String?>.of(other.custom!): null,
      welcomeMessage: other.welcomeMessage,
    );

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// This method is used instead of toJson, as we need to output valid JS
  /// that is not valid JSON.
  /// The toJson method is intentionally omitted, to produce an error if
  /// someone tries to convert this object to JSON instead of using the
  /// getJsonString method.
  String getJsonString() {
    if (this._idOnly) {
      return '"$id"';
    } else {
      final result = <String, dynamic>{};

      result['id'] = id;
      result['name'] = name;

      if (email != null) {
        result['email'] = email;
      }

      if (phone != null) {
        result['phone'] = phone;
      }

      if (availabilityText != null) {
        result['availabilityText'] = availabilityText;
      }

      if (locale != null) {
        result['locale'] = locale;
      }

      if (photoUrl != null) {
        result['photoUrl'] = photoUrl;
      }

      if (role != null) {
        result['role'] = role;
      }

      if (welcomeMessage != null) {
        result['welcomeMessage'] = welcomeMessage;
      }

      if (custom != null) {
        result['custom'] = custom;
      }

      return json.encode(result);
    }
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is User)) {
      return false;
    }

    if (_session != other._session) {
      return false;
    }

    if (_idOnly != other._idOnly) {
      return false;
    }

    if (availabilityText != other.availabilityText) {
      return false;
    }

    if (!mapEquals(custom, other.custom)) {
      return false;
    }

    if (!listEquals(email, other.email)) {
      return false;
    }

    if (!listEquals(phone, other.phone)) {
      return false;
    }

    if (id != other.id) {
      return false;
    }

    if (name != other.name) {
      return false;
    }

    if (locale != other.locale) {
      return false;
    }

    if (photoUrl != other.photoUrl) {
      return false;
    }

    if (role != other.role) {
      return false;
    }

    if (welcomeMessage != other.welcomeMessage) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(
    _session,
    _idOnly,
    availabilityText,
    custom,
    email,
    phone,
    id,
    name,
    locale,
    photoUrl,
    role,
    welcomeMessage,
  );
}

class UserData extends _BaseUser {
  UserData.fromJson(Map<String, dynamic> json)
    : super(availabilityText: json['availabilityText'],
      custom: json['custom'] != null ? Map<String, String?>.from(json['custom']) : null,
      email: json['email'] != null ? (json['email'] is String ? <String>[json['email']] : List<String>.from(json['email'])) : null,
      phone: json['phone'] != null ? (json['phone'] is String ? <String>[json['phone']] : List<String>.from(json['phone'])) : null,
      id: json['id'],
      name: json['name'],
      locale: json['locale'],
      photoUrl: json['photoUrl'],
      role: json['role'],
      welcomeMessage: json['welcomeMessage'],
    );
}

