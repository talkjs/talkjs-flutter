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

    if (!(other is Unreads)) {
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
  /// Contains the last Message for this conversation.
  final Message lastMessage;

  /// The number of unread messages in this conversation.
  final int unreadMessageCount;

  UnreadConversation.fromJson(Map<String, dynamic> json)
      : lastMessage = Message.fromJson(json['lastMessage']),
        unreadMessageCount = json['unreadMessageCount'];
}
