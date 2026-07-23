import 'dart:convert';

import 'package:collection/collection.dart';

import './types.dart';

class FieldPredicate<T> {
  final String _operand;
  String? _value;
  List<String?>? _values;
  bool _useValue;

  static const _unorderedIterableEquality =
      UnorderedIterableEquality<String?>();

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
        _useValue == other._useValue &&
        _unorderedIterableEquality.equals(_values, other._values);
  }

  @override
  int get hashCode => Object.hash(
    _operand,
    _value,
    _useValue,
    _unorderedIterableEquality.hash(_values),
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
        _useValue == other._useValue &&
        _exists == other._exists &&
        FieldPredicate._unorderedIterableEquality.equals(
          _values,
          other._values,
        );
  }

  @override
  int get hashCode => Object.hash(
    _operand,
    _value,
    _useValue,
    _exists,
    FieldPredicate._unorderedIterableEquality.hash(_values),
  );
}

class NumberPredicate {
  final String _operand;
  double? _value;
  List<double>? _values;

  static const _unorderedIterableEquality = UnorderedIterableEquality<double>();

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
        _unorderedIterableEquality.equals(_values, other._values);
  }

  @override
  int get hashCode =>
      Object.hash(_operand, _value, _unorderedIterableEquality.hash(_values));
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

abstract class ConversationPredicate {
  const ConversationPredicate();

  dynamic toJson();
  ConversationPredicate clone();

  @override
  String toString() => json.encode(this);
}

class SimpleConversationPredicate extends ConversationPredicate {
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

  static const _mapEquality = MapEquality<String, CustomFieldPredicate>();

  const SimpleConversationPredicate({
    this.access,
    this.custom,
    this.hasUnreadMessages,
    this.lastMessageTs,
    this.subject,
  });

  SimpleConversationPredicate.of(SimpleConversationPredicate other)
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
  ConversationPredicate clone() => SimpleConversationPredicate.of(this);

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

    return other is SimpleConversationPredicate &&
        access == other.access &&
        hasUnreadMessages == other.hasUnreadMessages &&
        lastMessageTs == other.lastMessageTs &&
        subject == other.subject &&
        _mapEquality.equals(custom, other.custom);
  }

  @override
  int get hashCode => Object.hash(
    access,
    hasUnreadMessages,
    lastMessageTs,
    subject,
    _mapEquality.hash(custom),
  );
}

class CompoundConversationPredicate extends ConversationPredicate {
  final String _operand;
  List<SimpleConversationPredicate> _values;

  static const _unorderedIterableEquality =
      UnorderedIterableEquality<SimpleConversationPredicate>();

  CompoundConversationPredicate.any(List<SimpleConversationPredicate> predicates)
    : _operand = 'any',
      _values = predicates;

  CompoundConversationPredicate.of(CompoundConversationPredicate other)
    : _operand = other._operand,
      _values = List.of(other._values);

  @override
  ConversationPredicate clone() => CompoundConversationPredicate.of(this);

  @override
  dynamic toJson() => [_operand, _values];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CompoundConversationPredicate &&
        _operand == other._operand &&
        _unorderedIterableEquality.equals(_values, other._values);
  }

  @override
  int get hashCode =>
      Object.hash(_operand, _unorderedIterableEquality.hash(_values));
}

class SenderPredicate {
  final FieldPredicate<String>? id;
  final Map<String, CustomFieldPredicate>? custom;
  final FieldPredicate<String>? locale;
  final FieldPredicate<String>? role;

  static const _mapEquality = MapEquality<String, CustomFieldPredicate>();

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
        locale == other.locale &&
        role == other.role &&
        _mapEquality.equals(custom, other.custom);
  }

  @override
  int get hashCode => Object.hash(id, locale, role, _mapEquality.hash(custom));
}

abstract class MessagePredicate {
  const MessagePredicate();

  dynamic toJson();
  MessagePredicate clone();

  @override
  String toString() => json.encode(this);
}

class SimpleMessagePredicate extends MessagePredicate {
  /// Only select messages that have particular custom fields set to particular values.
  final Map<String, CustomFieldPredicate>? custom;

  /// Only show messages that were sent by users (web), through the REST API (rest), via
  /// reply-to-email (email) or via the import REST API (import).
  final FieldPredicate<MessageOrigin>? origin;

  /// Only show messages that are sent by a sender that has all of the given properties
  final SenderPredicate? sender;

  /// Only show messages of a given type
  final FieldPredicate<MessageType>? type;

  static const _mapEquality = MapEquality<String, CustomFieldPredicate>();

  const SimpleMessagePredicate({
    this.custom,
    this.origin,
    this.sender,
    this.type,
  });

  SimpleMessagePredicate.of(SimpleMessagePredicate other)
    : custom = (other.custom != null ? Map.of(other.custom!) : null),
      origin = (other.origin != null ? FieldPredicate.of(other.origin!) : null),
      sender = (other.sender != null
          ? SenderPredicate.of(other.sender!)
          : null),
      type = (other.type != null ? FieldPredicate.of(other.type!) : null);

  @override
  MessagePredicate clone() => SimpleMessagePredicate.of(this);

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

    return other is SimpleMessagePredicate &&
        _mapEquality.equals(custom, other.custom) &&
        origin == other.origin &&
        sender == other.sender &&
        type == other.type;
  }

  @override
  int get hashCode =>
      Object.hash(origin, sender, type, _mapEquality.hash(custom));
}

class CompoundMessagePredicate extends MessagePredicate {
  final String _operand;
  List<SimpleMessagePredicate> _values;

  static const _unorderedIterableEquality =
      UnorderedIterableEquality<SimpleMessagePredicate>();

  CompoundMessagePredicate.any(List<SimpleMessagePredicate> predicates)
    : _operand = 'any',
      _values = predicates;

  CompoundMessagePredicate.of(CompoundMessagePredicate other)
    : _operand = other._operand,
      _values = List.of(other._values);

  @override
  MessagePredicate clone() => CompoundMessagePredicate.of(this);

  @override
  dynamic toJson() => [_operand, _values];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CompoundMessagePredicate &&
        _operand == other._operand &&
        _unorderedIterableEquality.equals(_values, other._values);
  }

  @override
  int get hashCode =>
      Object.hash(_operand, _unorderedIterableEquality.hash(_values));
}
