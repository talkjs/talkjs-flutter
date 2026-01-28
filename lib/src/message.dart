import './conversation.dart';
import './predicate.dart';
import './user.dart';

enum MessageType { UserMessage, SystemMessage }

enum ContentType { media, text, location }

class Attachment {
  final String url;
  final int size;

  Attachment.fromJson(Map<String, dynamic> json)
    : url = json['url'],
      size = json['size'];
}

class SentMessage {
  /// The message ID of the message that was sent
  final String? id;

  /// The ID of the conversation that the message belongs to
  final String conversationId;

  /// Identifies the message as either a User message or System message
  final MessageType type;

  /// Contains an Array of User.id's that have read the message
  final List<String> readBy;

  /// Contains the user ID for the person that sent the message
  final String
  senderId; // redundant since the user is always me, but keeps it consistant

  /// Contains the message's text
  final String? text;

  /// Only given if the message contains a file. An object with the URL and filesize (in bytes) of the given file.
  final Attachment? attachment;

  /// Only given if the message contains a location. An array of two numbers which represent the longitude and latitude of this location, respectively. Only given if this message is a shared location.
  ///
  /// Example:
  /// [51.481083, -3.178306]
  final List<double>? location;

  SentMessage.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      conversationId = json['conversationId'],
      type = (json['type'] == 'UserMessage'
          ? MessageType.UserMessage
          : MessageType.SystemMessage),
      readBy = List.from(json['readBy']),
      senderId = json['senderId'],
      text = json['text'],
      attachment = (json['attachment'] != null
          ? Attachment.fromJson(json['attachment'])
          : null),
      location = (json['location'] != null
          ? List.from(json['location'])
          : null);
}

class Message {
  /// Only given if the message contains a file. An object with the URL and filesize (in bytes) of the given file.
  final Attachment? attachment;

  /// The message's content
  final String body;

  /// The ConversationData that the message belongs to
  final ConversationData conversation;

  /// Custom metadata for this conversation
  final Map<String, String?>? custom;

  /// The message ID of the message that was sent
  final String id;

  /// 'true' if the message was sent by the current user
  final bool isByMe;

  /// Only given if the message contains a location. An array of two numbers which represent the longitude and latitude of this location, respectively. Only given if this message is a shared location.
  ///
  /// Example:
  /// [51.481083, -3.178306]
  final List<double>? location;

  // Determines how this message was sent
  final MessageOrigin origin;

  /// 'true' if the message has been read, 'false' has not been seen yet
  final bool read;

  /// The User that sent the message
  final UserData? sender;

  /// Contains the user ID for the person that sent the message
  final String? senderId;

  /// UNIX timestamp specifying when the message was sent (UTC, in milliseconds)
  final double timestamp;

  /// Specifies if if the message is media (file), text or a shared location
  final ContentType type;

  Message.fromJson(Map<String, dynamic> json)
    : attachment = (json['attachment'] != null
          ? Attachment.fromJson(json['attachment'])
          : null),
      body = json['body'],
      conversation = ConversationData.fromJson(json['conversation']),
      custom = (json['custom'] != null ? Map.from(json['custom']) : null),
      id = json['id'],
      isByMe = json['isByMe'],
      location = (json['location'] != null
          ? List.from(json['location'])
          : null),
      origin = _originFromString(json['origin']),
      read = json['read'],
      sender = (json['sender'] != null
          ? UserData.fromJson(json['sender'])
          : null),
      senderId = json['senderId'],
      timestamp = json['timestamp'].toDouble(),
      type = _contentTypeFromString(json['type']);
}

MessageOrigin _originFromString(String str) => switch (str) {
  'web' => MessageOrigin.web,
  'rest' => MessageOrigin.rest,
  'email' => MessageOrigin.email,
  'import' => MessageOrigin.import,
  _ => throw ArgumentError('Unknown MessageOrigin $str'),
};

ContentType _contentTypeFromString(String str) => switch (str) {
  'media' => ContentType.media,
  'text' => ContentType.text,
  'location' => ContentType.location,
  _ => throw ArgumentError('Unknown ContentType $str'),
};
