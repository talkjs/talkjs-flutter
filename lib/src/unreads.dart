import './conversation.dart';
import './message.dart';

typedef UnreadsChangeHandler = void Function(
    List<UnreadConversation> unreadConversations);

class Unreads {
  final UnreadsChangeHandler? onChange;

  const Unreads({
    this.onChange,
  });

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Unreads) {
      return false;
    }

    if (onChange != other.onChange) {
      return false;
    }

    return true;
  }

  int get hashCode => onChange.hashCode;
}

class UnreadConversation {
  /// The ConversationData of the unread conversation.
  final ConversationData conversation;

  /// Contains the last Message for this conversation.
  final Message lastMessage;

  /// The number of unread messages in this conversation.
  final int unreadMessageCount;

  UnreadConversation.fromJson(Map<String, dynamic> json)
      : conversation = ConversationData.fromJson(json['conversation']),
        lastMessage = Message.fromJson(json['lastMessage']),
        unreadMessageCount = json['unreadMessageCount'];
}
