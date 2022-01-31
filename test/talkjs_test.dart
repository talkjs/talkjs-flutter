import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:talkjs/talkjs.dart';

void main() {
  test('test oneOnOneId', () {
    expect(Talk.oneOnOneId('1234', 'abcd'), '35ec37e6e0ca43ac8ccc');
    expect(Talk.oneOnOneId('abcd', '1234'), '35ec37e6e0ca43ac8ccc');
  });

  test('test FieldPredicate ==', () {
    expect(FieldPredicate<ConversationAccessLevel>.equals(ConversationAccessLevel.readWrite) == FieldPredicate<ConversationAccessLevel>.equals(ConversationAccessLevel.readWrite), true);
    expect(FieldPredicate<String>.notOneOf(['it', 'fr']) == FieldPredicate<String>.notOneOf(['it', 'fr']), true);
  });

  test('test CustomFieldPredicate ==', () {
    expect(CustomFieldPredicate.exists() == CustomFieldPredicate.exists(), true);
    expect(CustomFieldPredicate.equals('it') == CustomFieldPredicate.equals('it'), true);
    expect(CustomFieldPredicate.oneOf(['it', 'fr']) == CustomFieldPredicate.oneOf(['it', 'fr']), true);
  });

  test('test ConversationPredicate ==', () {
    expect(
      ConversationPredicate(
        access: FieldPredicate.notEquals(ConversationAccessLevel.none),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        hasUnreadMessages: false,
      ) == ConversationPredicate(
        access: FieldPredicate.notEquals(ConversationAccessLevel.none),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        hasUnreadMessages: false,
      )
    , true);
  });

  test('test SenderPredicate ==', () {
    expect(
      SenderPredicate(
        id: FieldPredicate.notEquals('INVALID_ID'),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        locale: FieldPredicate.notOneOf(['it', 'fr']),
        role: FieldPredicate.notEquals('admin'),
      ) == SenderPredicate(
        id: FieldPredicate.notEquals('INVALID_ID'),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        locale: FieldPredicate.notOneOf(['it', 'fr']),
        role: FieldPredicate.notEquals('admin'),
      )
    , true);
  });

  test('test MessagePredicate ==', () {
    expect(
      MessagePredicate(
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        origin: FieldPredicate.equals(MessageOrigin.web),
        sender: SenderPredicate(
          id: FieldPredicate.notEquals('INVALID_ID'),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          locale: FieldPredicate.notOneOf(['it', 'fr']),
          role: FieldPredicate.notEquals('admin'),
        ),
        type: FieldPredicate.notEquals(MessageType.systemMessage),
      ) == MessagePredicate(
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        origin: FieldPredicate.equals(MessageOrigin.web),
        sender: SenderPredicate(
          id: FieldPredicate.notEquals('INVALID_ID'),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          locale: FieldPredicate.notOneOf(['it', 'fr']),
          role: FieldPredicate.notEquals('admin'),
        ),
        type: FieldPredicate.notEquals(MessageType.systemMessage),
      )
    , true);
  });

  test('test FieldPredicate.of', () {
    expect(FieldPredicate<ConversationAccessLevel>.of(FieldPredicate<ConversationAccessLevel>.equals(ConversationAccessLevel.readWrite)) == FieldPredicate<ConversationAccessLevel>.equals(ConversationAccessLevel.readWrite), true);
    expect(FieldPredicate<String>.of(FieldPredicate<String>.notOneOf(['it', 'fr'])) == FieldPredicate<String>.notOneOf(['it', 'fr']), true);
  });

  test('test CustomFieldPredicate of', () {
    expect(CustomFieldPredicate.of(CustomFieldPredicate.exists()) == CustomFieldPredicate.exists(), true);
    expect(CustomFieldPredicate.of(CustomFieldPredicate.equals('it')) == CustomFieldPredicate.equals('it'), true);
    expect(CustomFieldPredicate.of(CustomFieldPredicate.oneOf(['it', 'fr'])) == CustomFieldPredicate.oneOf(['it', 'fr']), true);
  });

  test('test ConversationPredicate of', () {
    expect(
      ConversationPredicate.of(ConversationPredicate(
        access: FieldPredicate.notEquals(ConversationAccessLevel.none),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        hasUnreadMessages: false,
      )) == ConversationPredicate(
        access: FieldPredicate.notEquals(ConversationAccessLevel.none),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        hasUnreadMessages: false,
      )
    , true);
  });

  test('test SenderPredicate of', () {
    expect(
      SenderPredicate.of(SenderPredicate(
        id: FieldPredicate.notEquals('INVALID_ID'),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        locale: FieldPredicate.notOneOf(['it', 'fr']),
        role: FieldPredicate.notEquals('admin'),
      )) == SenderPredicate(
        id: FieldPredicate.notEquals('INVALID_ID'),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        locale: FieldPredicate.notOneOf(['it', 'fr']),
        role: FieldPredicate.notEquals('admin'),
      )
    , true);
  });

  test('test MessagePredicate of', () {
    expect(
      MessagePredicate.of(MessagePredicate(
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        origin: FieldPredicate.equals(MessageOrigin.web),
        sender: SenderPredicate(
          id: FieldPredicate.notEquals('INVALID_ID'),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          locale: FieldPredicate.notOneOf(['it', 'fr']),
          role: FieldPredicate.notEquals('admin'),
        ),
        type: FieldPredicate.notEquals(MessageType.systemMessage),
      )) == MessagePredicate(
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        origin: FieldPredicate.equals(MessageOrigin.web),
        sender: SenderPredicate(
          id: FieldPredicate.notEquals('INVALID_ID'),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          locale: FieldPredicate.notOneOf(['it', 'fr']),
          role: FieldPredicate.notEquals('admin'),
        ),
        type: FieldPredicate.notEquals(MessageType.systemMessage),
      )
    , true);
  });

  test('test ConversationPredicate string', () {
    expect(
      json.encode(ConversationPredicate(
        access: FieldPredicate.notEquals(ConversationAccessLevel.none),
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        hasUnreadMessages: false,
      )),
      '{"access":["!=","None"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"hasUnreadMessages":false}'
    );
  });

  test('test MessagePredicate string', () {
    expect(
      json.encode(MessagePredicate(
        custom: {
          'seller': CustomFieldPredicate.exists(),
          'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
          'visibility': CustomFieldPredicate.equals('visible'),
        },
        origin: FieldPredicate.equals(MessageOrigin.web),
        sender: SenderPredicate(
          id: FieldPredicate.notEquals('INVALID_ID'),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          locale: FieldPredicate.notOneOf(['it', 'fr']),
          role: FieldPredicate.notEquals('admin'),
        ),
        type: FieldPredicate.notEquals(MessageType.systemMessage),
      )),
      '{"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"origin":["==","web"],"sender":{"id":["!=","INVALID_ID"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"locale":["!oneOf",["it","fr"]],"role":["!=","admin"]},"type":["!=","SystemMessage"]}'
    );
  });
}

