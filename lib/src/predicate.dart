import 'dart:convert';

class FieldPredicate<T> {
  final String _operand;
  String? _value;
  List<String>? _values;

  FieldPredicate.equals(T value) : _operand = '==', _value = value.toString();
  FieldPredicate.notEquals(T value) : _operand = '!=', _value = value.toString();
  FieldPredicate.oneOf(List<T> values) : _operand = 'oneOf', _values = values.map((value) => value.toString()).toList();
  FieldPredicate.notOneOf(List<T> values) : _operand = '!oneOf', _values = values.map((value) => value.toString()).toList();

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
}

class CustomFieldPredicate extends FieldPredicate<String> {
  bool? _exists;

  CustomFieldPredicate.equals(String value) : super.equals(value);
  CustomFieldPredicate.notEquals(String value) : super.notEquals(value);
  CustomFieldPredicate.oneOf(List<String> values) : super.oneOf(values);
  CustomFieldPredicate.notOneOf(List<String> values) : super.notOneOf(values);
  CustomFieldPredicate.exists() : _exists = true, super.equals('');
  CustomFieldPredicate.notExists() : _exists = false, super.notEquals('');

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
}

