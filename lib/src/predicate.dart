import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

class FieldPredicate<T> {
  final String _operand;
  String? _value;
  List<String>? _values;

  FieldPredicate.equals(T value) : _operand = '==', _value = value.toString();
  FieldPredicate.notEquals(T value) : _operand = '!=', _value = value.toString();
  FieldPredicate.oneOf(List<T> values) : _operand = 'oneOf', _values = values.map((value) => value.toString()).toList();
  FieldPredicate.notOneOf(List<T> values) : _operand = '!oneOf', _values = values.map((value) => value.toString()).toList();

  FieldPredicate.of(FieldPredicate<T> other)
    : _operand = other._operand,
    _value = other._value,
    _values = (other._values != null ? List<String>.of(other._values!) : null);

  @override
  String toString() {
    return json.encode(this);
  }

  dynamic toJson() {
    final result = <dynamic>[];

    result.add(_operand);

    if (_value != null) {
      result.add(_value);
    }

    if (_values != null) {
      result.add(_values);
    }

    return result;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is FieldPredicate<T>)) {
      return false;
    }

    if (_operand != other._operand) {
      return false;
    }

    if (_value != other._value) {
      return false;
    }

    if (!listEquals(_values, other._values)) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(
    _operand,
    _value,
    (_values != null ? hashList(_values) : _values),
  );
}

class CustomFieldPredicate extends FieldPredicate<String> {
  bool? _exists;

  CustomFieldPredicate.equals(String value) : super.equals(value);
  CustomFieldPredicate.notEquals(String value) : super.notEquals(value);
  CustomFieldPredicate.oneOf(List<String> values) : super.oneOf(values);
  CustomFieldPredicate.notOneOf(List<String> values) : super.notOneOf(values);
  CustomFieldPredicate.exists() : _exists = true, super.equals('');
  CustomFieldPredicate.notExists() : _exists = false, super.notEquals('');

  CustomFieldPredicate.of(CustomFieldPredicate other) : _exists = other._exists, super.of(other);

  @override
  String toString() {
    if (_exists == null) {
      return super.toString();
    } else if (_exists!) {
      return 'exists';
    } else {
      return '!exists';
    }
  }

  @override
  dynamic toJson() {
    if (_exists == null) {
      return super.toJson();
    } else if (_exists!) {
      return 'exists';
    } else {
      return '!exists';
    }
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is CustomFieldPredicate)) {
      return false;
    }

    if (_operand != other._operand) {
      return false;
    }

    if (_value != other._value) {
      return false;
    }

    if (!listEquals(_values, other._values)) {
      return false;
    }

    if (_exists != other._exists) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(
    _operand,
    _value,
    (_values != null ? hashList(_values) : _values),
    _exists,
  );
}

class ConversationAccessLevel {
  final String _value;

  const ConversationAccessLevel._(this._value);

  static const ConversationAccessLevel none = ConversationAccessLevel._('None');
  static const ConversationAccessLevel read = ConversationAccessLevel._('Read');
  static const ConversationAccessLevel readWrite = ConversationAccessLevel._('ReadWrite');

  @override
  String toString() => _value;
}

class ConversationPredicate {
  /// Only select conversations that the current user as specific access to.
  final FieldPredicate<ConversationAccessLevel>? access;

  /// Only select conversations that have particular custom fields set to particular values.
  final Map<String, CustomFieldPredicate>? custom;

  /// Set this field to only select conversations that have, or don't have any, unread messages.
  final bool? hasUnreadMessages;

  const ConversationPredicate({this.access, this.custom, this.hasUnreadMessages});

  ConversationPredicate.of(ConversationPredicate other)
    : access = (other.access != null ? FieldPredicate<ConversationAccessLevel>.of(other.access!) : null),
    custom = (other.custom != null ? Map<String, CustomFieldPredicate>.of(other.custom!) : null),
    hasUnreadMessages = other.hasUnreadMessages;

  @override
  String toString() {
    return json.encode(this);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    if (access != null) {
      result['access'] = access;
    }

    if (custom != null) {
      result['custom'] = custom;
    }

    if (hasUnreadMessages != null) {
      result['hasUnreadMessages'] = hasUnreadMessages;
    }

    return result;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is ConversationPredicate)) {
      return false;
    }

    if (access != other.access) {
      return false;
    }

    if (!mapEquals(custom, other.custom)) {
      return false;
    }

    if (hasUnreadMessages != other.hasUnreadMessages) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(
    access,
    (custom != null ? hashList(custom!.keys) : custom),
    (custom != null ? hashList(custom!.values) : custom),
    hasUnreadMessages,
  );
}

class MessageOrigin {
  final String _value;

  const MessageOrigin._(this._value);

  static const MessageOrigin web = MessageOrigin._('web');
  static const MessageOrigin rest = MessageOrigin._('rest');
  static const MessageOrigin email = MessageOrigin._('email');
  static const MessageOrigin import = MessageOrigin._('import');

  @override
  String toString() => _value;
}

class MessageType {
  final String _value;

  const MessageType._(this._value);

  static const MessageType userMessage = MessageType._('UserMessage');
  static const MessageType systemMessage = MessageType._('SystemMessage');

  @override
  String toString() => _value;
}

class SenderPredicate {
  final FieldPredicate<String>? id;
  final Map<String, CustomFieldPredicate>? custom;
  final FieldPredicate<String>? locale;
  final FieldPredicate<String>? role;

  const SenderPredicate({this.id, this.custom, this.locale, this.role});

  SenderPredicate.of(SenderPredicate other)
    : id = (other.id != null ? FieldPredicate<String>.of(other.id!) : null),
    custom = (other.custom != null ? Map<String, CustomFieldPredicate>.of(other.custom!) : null),
    locale = (other.locale != null ? FieldPredicate<String>.of(other.locale!) : null),
    role = (other.role != null ? FieldPredicate<String>.of(other.role!) : null);

  @override
  String toString() {
    return json.encode(this);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    if (id != null) {
      result['id'] = id;
    }

    if (custom != null) {
      result['custom'] = custom;
    }

    if (locale != null) {
      result['locale'] = locale;
    }

    if (role != null) {
      result['role'] = role;
    }

    return result;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is SenderPredicate)) {
      return false;
    }

    if (id != other.id) {
      return false;
    }

    if (!mapEquals(custom, other.custom)) {
      return false;
    }

    if (locale != other.locale) {
      return false;
    }

    if (role != other.role) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(
    id,
    (custom != null ? hashList(custom!.keys) : custom),
    (custom != null ? hashList(custom!.values) : custom),
    locale,
    role,
  );
}

class MessagePredicate {
  /// Only select messages that have particular custom fields set to particular values.
  final Map<String, CustomFieldPredicate>? custom;

  /// Only show messages that were sent by users (web), through the REST API (rest), via
  /// reply-to-email (email) or via the import REST API (import).
  final FieldPredicate<MessageOrigin>? origin;

  /// Only show messages that are sent by a sender that has all of the given properties
  final SenderPredicate? sender;

  /// Only show messages of a given type
  final FieldPredicate<MessageType>? type;

  const MessagePredicate({this.custom, this.origin, this.sender, this.type});

  MessagePredicate.of(MessagePredicate other)
    : custom = (other.custom != null ? Map<String, CustomFieldPredicate>.of(other.custom!) : null),
    origin = (other.origin != null ? FieldPredicate<MessageOrigin>.of(other.origin!) : null),
    sender = (other.sender != null ? SenderPredicate.of(other.sender!) : null),
    type = (other.type != null ? FieldPredicate<MessageType>.of(other.type!) : null);

  @override
  String toString() {
    return json.encode(this);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    if (custom != null) {
      result['custom'] = custom;
    }

    if (origin != null) {
      result['origin'] = origin;
    }

    if (sender != null) {
      result['sender'] = sender;
    }

    if (type != null) {
      result['type'] = type;
    }

    return result;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is MessagePredicate)) {
      return false;
    }

    if (!mapEquals(custom, other.custom)) {
      return false;
    }

    if (origin != other.origin) {
      return false;
    }

    if (sender != other.sender) {
      return false;
    }

    if (type != other.type) {
      return false;
    }

    return true;
  }

  int get hashCode => hashValues(
    (custom != null ? hashList(custom!.keys) : custom),
    (custom != null ? hashList(custom!.values) : custom),
    origin,
    sender,
    type,
  );
}

