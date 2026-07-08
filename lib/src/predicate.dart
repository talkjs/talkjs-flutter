import 'dart:convert';

import 'package:flutter/foundation.dart';

import './types.dart';

class FieldPredicate<T> {
  final String _operand;
  String? _value;
  List<String?>? _values;
  bool _useValue;

  FieldPredicate.equals(T value)
    : _operand = '==',
      _value = value?.toString(),
      _useValue = true;
  FieldPredicate.notEquals(T value)
    : _operand = '!=',
      _value = value?.toString(),
      _useValue = true;
  FieldPredicate.oneOf(List<T> values)
    : _operand = 'oneOf',
      _values = values.map((value) => value?.toString()).toList(),
      _useValue = false;
  FieldPredicate.notOneOf(List<T> values)
    : _operand = '!oneOf',
      _values = values.map((value) => value?.toString()).toList(),
      _useValue = false;

  FieldPredicate.of(FieldPredicate<T> other)
    : _operand = other._operand,
      _value = other._value,
      _values = (other._values != null ? List.of(other._values!) : null),
      _useValue = other._useValue;

  @override
  String toString() => json.encode(this);

  dynamic toJson() => [_operand, if (_useValue) _value, ?_values];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FieldPredicate<T> &&
        _operand == other._operand &&
        _value == other._value &&
        listEquals(_values, other._values) &&
        _useValue == other._useValue;
  }

  @override
  int get hashCode => Object.hash(
    _operand,
    _value,
    (_values != null ? Object.hashAllUnordered(_values!) : _values),
    _useValue,
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

  CustomFieldPredicate.of(CustomFieldPredicate other)
    : _exists = other._exists,
      super.of(other);

  @override
  dynamic toJson() => switch (_exists) {
    null => super.toJson(),
    true => 'exists',
    false => '!exists',
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CustomFieldPredicate &&
        _operand == other._operand &&
        _value == other._value &&
        listEquals(_values, other._values) &&
        _useValue == other._useValue &&
        _exists == other._exists;
  }

  @override
  int get hashCode => Object.hash(
    _operand,
    _value,
    (_values != null ? Object.hashAllUnordered(_values!) : _values),
    _useValue,
    _exists,
  );
}

class NumberPredicate {
  final String _operand;
  double? _value;
  List<double>? _values;

  NumberPredicate.greaterThan(double value) : _operand = '>', _value = value;
  NumberPredicate.lessThan(double value) : _operand = '<', _value = value;
  NumberPredicate.greaterOrEquals(double value)
    : _operand = '>=',
      _value = value;
  NumberPredicate.lessOrEquals(double value) : _operand = '<=', _value = value;
  NumberPredicate.between(List<double> values)
    : _operand = 'between',
      _values = List.of(values);
  NumberPredicate.notBetween(List<double> values)
    : _operand = '!between',
      _values = List.of(values);

  NumberPredicate.of(NumberPredicate other)
    : _operand = other._operand,
      _value = other._value,
      _values = (other._values != null ? List.of(other._values!) : null);

  @override
  String toString() => json.encode(this);

  dynamic toJson() => [_operand, ?_value, ?_values];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NumberPredicate &&
        _operand == other._operand &&
        _value == other._value &&
        listEquals(_values, other._values);
  }

  @override
  int get hashCode => Object.hash(
    _operand,
    _value,
    (_values != null ? Object.hashAllUnordered(_values!) : _values),
  );
}

class ConversationAccessLevel {
  final String _value;

  const ConversationAccessLevel._(this._value);

  static const ConversationAccessLevel none = ConversationAccessLevel._('None');
  static const ConversationAccessLevel read = ConversationAccessLevel._('Read');
  static const ConversationAccessLevel readWrite = ConversationAccessLevel._(
    'ReadWrite',
  );

  @override
  String toString() => _value;
}

abstract class BaseConversationPredicate {
  const BaseConversationPredicate();
  String toString();
  dynamic toJson();
  BaseConversationPredicate clone();
  bool operator ==(Object other);
  int get hashCode;
}

class ConversationPredicate extends BaseConversationPredicate {
  /// Only select conversations that the current user as specific access to.
  final FieldPredicate<ConversationAccessLevel>? access;

  /// Only select conversations that have particular custom fields set to particular values.
  final Map<String, CustomFieldPredicate>? custom;

  /// Set this field to only select conversations that have, or don't have any, unread messages.
  final bool? hasUnreadMessages;

  /// Only select conversations that have the last message sent in a particular time interval.
  final NumberPredicate? lastMessageTs;

  /// Only select conversations that have the subject set to particular values.
  final FieldPredicate<String?>? subject;

  const ConversationPredicate({
    this.access,
    this.custom,
    this.hasUnreadMessages,
    this.lastMessageTs,
    this.subject,
  });

  ConversationPredicate.of(ConversationPredicate other)
    : access = (other.access != null ? FieldPredicate.of(other.access!) : null),
      custom = (other.custom != null ? Map.of(other.custom!) : null),
      hasUnreadMessages = other.hasUnreadMessages,
      lastMessageTs = (other.lastMessageTs != null
          ? NumberPredicate.of(other.lastMessageTs!)
          : null),
      subject = (other.subject != null
          ? FieldPredicate.of(other.subject!)
          : null);

  @override
  BaseConversationPredicate clone() => ConversationPredicate.of(this);

  @override
  String toString() => json.encode(this);

  @override
  dynamic toJson() => {
    'access': ?access,
    'custom': ?custom,
    'hasUnreadMessages': ?hasUnreadMessages,
    'lastMessageTs': ?lastMessageTs,
    'subject': ?subject,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ConversationPredicate &&
        access == other.access &&
        mapEquals(custom, other.custom) &&
        hasUnreadMessages == other.hasUnreadMessages &&
        lastMessageTs == other.lastMessageTs &&
        subject == other.subject;
  }

  @override
  int get hashCode => Object.hash(
    access,
    (custom != null ? Object.hashAllUnordered(custom!.entries) : custom),
    hasUnreadMessages,
    lastMessageTs,
    subject,
  );
}

class CompoundConversationPredicate extends BaseConversationPredicate {
  final String _operand;
  List<ConversationPredicate> _values;

  CompoundConversationPredicate.any(List<ConversationPredicate> predicates)
    : _operand = 'any',
      _values = predicates;

  CompoundConversationPredicate.of(CompoundConversationPredicate other)
    : _operand = other._operand,
      _values = List.of(other._values);

  @override
  BaseConversationPredicate clone() => CompoundConversationPredicate.of(this);

  @override
  String toString() => json.encode(this);

  @override
  dynamic toJson() => [_operand, _values];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CompoundConversationPredicate &&
        _operand == other._operand &&
        listEquals(_values, other._values);
  }

  @override
  int get hashCode => Object.hash(_operand, Object.hashAllUnordered(_values));
}

class SenderPredicate {
  final FieldPredicate<String>? id;
  final Map<String, CustomFieldPredicate>? custom;
  final FieldPredicate<String>? locale;
  final FieldPredicate<String>? role;

  const SenderPredicate({this.id, this.custom, this.locale, this.role});

  SenderPredicate.of(SenderPredicate other)
    : id = (other.id != null ? FieldPredicate.of(other.id!) : null),
      custom = (other.custom != null ? Map.of(other.custom!) : null),
      locale = (other.locale != null ? FieldPredicate.of(other.locale!) : null),
      role = (other.role != null ? FieldPredicate.of(other.role!) : null);

  @override
  String toString() => json.encode(this);

  Map<String, dynamic> toJson() => {
    'id': ?id,
    'custom': ?custom,
    'locale': ?locale,
    'role': ?role,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SenderPredicate &&
        id == other.id &&
        mapEquals(custom, other.custom) &&
        locale == other.locale &&
        role == other.role;
  }

  @override
  int get hashCode => Object.hash(
    id,
    (custom != null ? Object.hashAllUnordered(custom!.entries) : custom),
    locale,
    role,
  );
}

abstract class BaseMessagePredicate {
  const BaseMessagePredicate();
  String toString();
  dynamic toJson();
  BaseMessagePredicate clone();
  bool operator ==(Object other);
  int get hashCode;
}

class MessagePredicate extends BaseMessagePredicate {
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
    : custom = (other.custom != null ? Map.of(other.custom!) : null),
      origin = (other.origin != null ? FieldPredicate.of(other.origin!) : null),
      sender = (other.sender != null
          ? SenderPredicate.of(other.sender!)
          : null),
      type = (other.type != null ? FieldPredicate.of(other.type!) : null);

  @override
  BaseMessagePredicate clone() => MessagePredicate.of(this);

  @override
  String toString() => json.encode(this);

  @override
  dynamic toJson() => {
    'custom': ?custom,
    'origin': ?origin,
    'sender': ?sender,
    'type': ?type,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MessagePredicate &&
        mapEquals(custom, other.custom) &&
        origin == other.origin &&
        sender == other.sender &&
        type == other.type;
  }

  @override
  int get hashCode => Object.hash(
    (custom != null ? Object.hashAllUnordered(custom!.entries) : custom),
    origin,
    sender,
    type,
  );
}

class CompoundMessagePredicate extends BaseMessagePredicate {
  final String _operand;
  List<MessagePredicate> _values;

  CompoundMessagePredicate.any(List<MessagePredicate> predicates)
    : _operand = 'any',
      _values = predicates;

  CompoundMessagePredicate.of(CompoundMessagePredicate other)
    : _operand = other._operand,
      _values = List.of(other._values);

  @override
  BaseMessagePredicate clone() => CompoundMessagePredicate.of(this);

  @override
  String toString() => json.encode(this);

  @override
  dynamic toJson() => [_operand, _values];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CompoundMessagePredicate &&
        _operand == other._operand &&
        listEquals(_values, other._values);
  }

  @override
  int get hashCode => Object.hash(_operand, Object.hashAllUnordered(_values));
}
