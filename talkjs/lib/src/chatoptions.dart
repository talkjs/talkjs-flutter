import 'package:talkjs/src/ui.dart';

/// The possible values for the Chat modes
enum ChatMode { subject, participants }

extension ChatModeString on ChatMode {
  /// Converts this enum's values to String.
  String getValue() {
    late String result;
    switch (this) {
      case ChatMode.participants:
        result = 'participants';
        break;
      case ChatMode.subject:
        result = 'subject';
        break;
    }

    return result;
  }
}

/// The values that dictate the chat direction.
enum TextDirection {
  /// right-to-left
  rtl,
  /// left-to-right
  ltr
}

extension TextDirectionString on TextDirection {
  /// Converts this enum's values to String.
  String getValue() {
    late String result;
    switch (this) {
      case TextDirection.rtl:
        result = 'rtl';
        break;
      case TextDirection.ltr:
        result = 'ltr';
        break;
    }

    return result;
  }
}

/// Settings that affect the behavior of the message field
class MessageFieldOptions {
  /// Determines whether the message field should automatically focus when the
  /// user navigates.
  ///
  /// Defaults to "smart", which means that the message field gets focused
  /// whenever a conversation is selected, if possible without negative side
  /// effects.
  /// If you need more control, consider setting [autofocus] to false and
  /// calling focus() at appropriate times.
  bool autofocus; // Convert to "smart"

  /// If set to true, pressing the enter key sends the message
  /// (if there is text in the message field).
  ///
  /// When set to false, the only way to send a message is by clicking or
  /// touching the "Send" button.
  /// Defaults to true.
  bool enterSendsMessage;

  /// The text displayed in the message field when the user hasn't started
  /// typing anything.
  String? placeholder;

  /// This enables spell checking.
  ///
  /// Note that setting this to true may also enable autocorrect on some mobile
  /// devices.
  /// Defaults to false
  bool spellcheck;

  MessageFieldOptions({this.autofocus = true, this.enterSendsMessage = true,
    this.placeholder, this.spellcheck = false
  });

  Map<String, dynamic> toJson() {
    final result = {
      'enterSendsMessage': enterSendsMessage,
      'placeholder': placeholder,
      'spellcheck': spellcheck
    };

    if (autofocus == true) {
      result['autofocus'] = 'smart';
    } else {
      result['autofocus'] = autofocus;
    }

    return result;
  }
}

/// This class represents the various configuration options used to finetune the
/// behaviour of UI elements.
abstract class _ChatOptions {
  /// Controls what text appears in the chat subtitle, right below the chat title.
  ///
  /// Defaults to [ChatMode.subject].
  ChatMode chatSubtitleMode;

  /// Controls what text appears in the chat title, in the header above the messages.
  ///
  /// Defaults to [ChatMode.participants].
  ChatMode chatTitleMode;

  /// Controls the text direction (for supporting right-to-left languages such
  /// as Arabic and Hebrew).
  ///
  /// Defaults to [TextDirection.rtl].
  TextDirection dir;

  /// Used to control if the Chat Header is displayed in the UI.
  ///
  /// Defaults to true.
  bool showChatHeader;

  /// Settings that affect the behavior of the message field
  MessageFieldOptions? messageField;

  _ChatOptions({this.chatSubtitleMode = ChatMode.subject,
    this.chatTitleMode = ChatMode.participants, this.dir = TextDirection.rtl,
    this.showChatHeader = true, this.messageField
  });

  Map<String, dynamic> toJson() => {
    'chatSubtitleMode': chatSubtitleMode.getValue(),
    'chatTitleMode': chatTitleMode.getValue(),
    'dir': dir.getValue(),
    'showChatHeader': showChatHeader,
    'messageField': messageField ?? {}
  };
}

/// Options to configure the behaviour of the [ChatBox] UI.
class ChatBoxOptions extends _ChatOptions{
  ChatBoxOptions({chatSubtitleMode, chatTitleMode, dir, showChatHeader,
    messageField})
      : super(chatSubtitleMode: chatSubtitleMode, chatTitleMode: chatTitleMode,
              dir: dir, showChatHeader: showChatHeader,
              messageField: messageField);
}

/// Options to configure the behaviour of the [Inbox].
class InboxOptions extends _ChatOptions {
  InboxOptions({chatSubtitleMode, chatTitleMode, dir, showChatHeader,
    messageField})
      : super(chatSubtitleMode: chatSubtitleMode, chatTitleMode: chatTitleMode,
              dir: dir, showChatHeader: showChatHeader,
              messageField: messageField);
}

/// Options to configure the behaviour of the [Popup].
class PopupOptions extends _ChatOptions {
  bool keepOpen;

  PopupOptions({this.keepOpen = false, chatSubtitleMode, chatTitleMode, dir,
    showChatHeader, messageField})
      : super(chatSubtitleMode: chatSubtitleMode, chatTitleMode: chatTitleMode,
      dir: dir, showChatHeader: showChatHeader,
      messageField: messageField);
}