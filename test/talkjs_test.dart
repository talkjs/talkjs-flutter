import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:talkjs_flutter/talkjs_flutter.dart';

void main() {
  test('test oneOnOneId', () {
    expect(Talk.oneOnOneId('1234', 'abcd'), '35ec37e6e0ca43ac8ccc');
    expect(Talk.oneOnOneId('abcd', '1234'), '35ec37e6e0ca43ac8ccc');
  });

  test('test SelectConversationEvent.fromJson', () {
    // Decode JSON first so `others` is List<dynamic>, matching the WebView payload.
    final event = SelectConversationEvent.fromJson(
      json.decode('''
      {
        "conversation": {
          "id": "conversation",
          "participants": {
            "me": {"access": "ReadWrite"},
            "other": {"access": "ReadWrite"}
          }
        },
        "me": {"id": "me", "name": "Me"},
        "others": [
          {"id": "other", "name": "Other"}
        ]
      }
      ''') as Map<String, dynamic>,
    );

    expect(event.others, hasLength(1));
    expect(event.others.single.id, 'other');
  });

  test('test FieldPredicate ==', () {
    expect(
        FieldPredicate<ConversationAccessLevel>.equals(
                ConversationAccessLevel.ReadWrite) ==
            FieldPredicate<ConversationAccessLevel>.equals(
                ConversationAccessLevel.ReadWrite),
        true);
    expect(
        FieldPredicate<String>.notOneOf(['it', 'fr']) ==
            FieldPredicate<String>.notOneOf(['it', 'fr']),
        true);
  });

  test('test CustomFieldPredicate ==', () {
    expect(
        CustomFieldPredicate.exists() == CustomFieldPredicate.exists(), true);
    expect(
        CustomFieldPredicate.equals('it') == CustomFieldPredicate.equals('it'),
        true);
    expect(
        CustomFieldPredicate.oneOf(['it', 'fr']) ==
            CustomFieldPredicate.oneOf(['it', 'fr']),
        true);
  });

  test('test ConversationPredicate ==', () {
    expect(
        SimpleConversationPredicate(
              access: FieldPredicate.notEquals(ConversationAccessLevel.None),
              custom: {
                'seller': CustomFieldPredicate.exists(),
                'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
                'visibility': CustomFieldPredicate.equals('visible'),
              },
              hasUnreadMessages: false,
              lastMessageTs: NumberPredicate.greaterThan(1679298371586),
              subject: FieldPredicate.equals(null),
            ) ==
            SimpleConversationPredicate(
              access: FieldPredicate.notEquals(ConversationAccessLevel.None),
              custom: {
                'seller': CustomFieldPredicate.exists(),
                'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
                'visibility': CustomFieldPredicate.equals('visible'),
              },
              hasUnreadMessages: false,
              lastMessageTs: NumberPredicate.greaterThan(1679298371586),
              subject: FieldPredicate.equals(null),
            ),
        true);
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
            ) ==
            SenderPredicate(
              id: FieldPredicate.notEquals('INVALID_ID'),
              custom: {
                'seller': CustomFieldPredicate.exists(),
                'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
                'visibility': CustomFieldPredicate.equals('visible'),
              },
              locale: FieldPredicate.notOneOf(['it', 'fr']),
              role: FieldPredicate.notEquals('admin'),
            ),
        true);
  });

  test('test MessagePredicate ==', () {
    expect(
        SimpleMessagePredicate(
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
              type: FieldPredicate.notEquals(MessageType.SystemMessage),
            ) ==
            SimpleMessagePredicate(
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
              type: FieldPredicate.notEquals(MessageType.SystemMessage),
            ),
        true);
  });

  test('test FieldPredicate.of', () {
    expect(
        FieldPredicate<ConversationAccessLevel>.of(
                FieldPredicate<ConversationAccessLevel>.equals(
                    ConversationAccessLevel.ReadWrite)) ==
            FieldPredicate<ConversationAccessLevel>.equals(
                ConversationAccessLevel.ReadWrite),
        true);
    expect(
        FieldPredicate<String>.of(
                FieldPredicate<String>.notOneOf(['it', 'fr'])) ==
            FieldPredicate<String>.notOneOf(['it', 'fr']),
        true);
  });

  test('test CustomFieldPredicate of', () {
    expect(
        CustomFieldPredicate.of(CustomFieldPredicate.exists()) ==
            CustomFieldPredicate.exists(),
        true);
    expect(
        CustomFieldPredicate.of(CustomFieldPredicate.equals('it')) ==
            CustomFieldPredicate.equals('it'),
        true);
    expect(
        CustomFieldPredicate.of(CustomFieldPredicate.oneOf(['it', 'fr'])) ==
            CustomFieldPredicate.oneOf(['it', 'fr']),
        true);
  });

  test('test NumberPredicate.of', () {
    expect(
        NumberPredicate.of(NumberPredicate.notBetween([100, 300])) ==
            NumberPredicate.notBetween([100, 300]),
        true);
  });

  test('test ConversationPredicate of', () {
    expect(
        SimpleConversationPredicate.of(SimpleConversationPredicate(
              access: FieldPredicate.notEquals(ConversationAccessLevel.None),
              custom: {
                'seller': CustomFieldPredicate.exists(),
                'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
                'visibility': CustomFieldPredicate.equals('visible'),
              },
              hasUnreadMessages: false,
              lastMessageTs: NumberPredicate.greaterThan(1679298371586),
              subject: FieldPredicate.notEquals('Pink shoes'),
            )) ==
            SimpleConversationPredicate(
              access: FieldPredicate.notEquals(ConversationAccessLevel.None),
              custom: {
                'seller': CustomFieldPredicate.exists(),
                'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
                'visibility': CustomFieldPredicate.equals('visible'),
              },
              hasUnreadMessages: false,
              lastMessageTs: NumberPredicate.greaterThan(1679298371586),
              subject: FieldPredicate.notEquals('Pink shoes'),
            ),
        true);
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
            )) ==
            SenderPredicate(
              id: FieldPredicate.notEquals('INVALID_ID'),
              custom: {
                'seller': CustomFieldPredicate.exists(),
                'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
                'visibility': CustomFieldPredicate.equals('visible'),
              },
              locale: FieldPredicate.notOneOf(['it', 'fr']),
              role: FieldPredicate.notEquals('admin'),
            ),
        true);
  });

  test('test MessagePredicate of', () {
    expect(
        SimpleMessagePredicate.of(SimpleMessagePredicate(
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
              type: FieldPredicate.notEquals(MessageType.SystemMessage),
            )) ==
            SimpleMessagePredicate(
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
              type: FieldPredicate.notEquals(MessageType.SystemMessage),
            ),
        true);
  });

  test('test ConversationPredicate string', () {
    expect(
        json.encode(SimpleConversationPredicate(
          access: FieldPredicate.notEquals(ConversationAccessLevel.None),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          hasUnreadMessages: false,
          lastMessageTs: NumberPredicate.greaterThan(1679298371586),
          subject: FieldPredicate.oneOf(['Pink shoes', null]),
        )),
        '{"access":["!=","None"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"hasUnreadMessages":false,"lastMessageTs":[">",1679298371586.0],"subject":["oneOf",["Pink shoes",null]]}');
  });

  test('test MessagePredicate string', () {
    expect(
        json.encode(SimpleMessagePredicate(
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
          type: FieldPredicate.notEquals(MessageType.SystemMessage),
        )),
        '{"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"origin":["==","web"],"sender":{"id":["!=","INVALID_ID"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"locale":["!oneOf",["it","fr"]],"role":["!=","admin"]},"type":["!=","SystemMessage"]}');
  });

  test('test CompoundConversationPredicate', () {
    expect(
      json.encode(CompoundConversationPredicate.any([
        SimpleConversationPredicate(
          access: FieldPredicate.notEquals(ConversationAccessLevel.None),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          hasUnreadMessages: false,
          lastMessageTs: NumberPredicate.greaterThan(1679298371586),
          subject: FieldPredicate.oneOf(['Pink shoes', null]),
        ),
        SimpleConversationPredicate(
          access: FieldPredicate.notEquals(ConversationAccessLevel.None),
          custom: {
            'seller': CustomFieldPredicate.exists(),
            'category': CustomFieldPredicate.oneOf(['shoes', 'sandals']),
            'visibility': CustomFieldPredicate.equals('visible'),
          },
          hasUnreadMessages: false,
          lastMessageTs: NumberPredicate.greaterThan(1679298371586),
          subject: FieldPredicate.equals(null),
        )
      ])),
      '["any",[{"access":["!=","None"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"hasUnreadMessages":false,"lastMessageTs":[">",1679298371586.0],"subject":["oneOf",["Pink shoes",null]]},{"access":["!=","None"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"hasUnreadMessages":false,"lastMessageTs":[">",1679298371586.0],"subject":["==",null]}]]',
    );
  });

  test('test CompoundMessagePredicate', () {
    expect(
      json.encode(CompoundMessagePredicate.any([
        SimpleMessagePredicate(
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
          type: FieldPredicate.notEquals(MessageType.SystemMessage),
        ),
        SimpleMessagePredicate(
          origin: FieldPredicate.notEquals(MessageOrigin.web),
          type: FieldPredicate.equals(MessageType.SystemMessage),
        ),
      ])),
      '["any",[{"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"origin":["==","web"],"sender":{"id":["!=","INVALID_ID"],"custom":{"seller":"exists","category":["oneOf",["shoes","sandals"]],"visibility":["==","visible"]},"locale":["!oneOf",["it","fr"]],"role":["!=","admin"]},"type":["!=","SystemMessage"]},{"origin":["!=","web"],"type":["==","SystemMessage"]}]]',
    );
  });
}
