import './ui.dart';
import './conversation.dart';

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
  bool? autofocus; // Convert to "smart"

  /// If set to true, pressing the enter key sends the message
  /// (if there is text in the message field).
  ///
  /// When set to false, the only way to send a message is by clicking or
  /// touching the "Send" button.
  /// Defaults to true.
  bool? enterSendsMessage;

  /// The text displayed in the message field when the user hasn't started
  /// typing anything.
  String? placeholder;

  /// This enables spell checking.
  ///
  /// Note that setting this to true may also enable autocorrect on some mobile
  /// devices.
  /// Defaults to false
  bool? spellcheck;

  /// TODO: visible

  MessageFieldOptions({this.autofocus, this.enterSendsMessage, this.placeholder, this.spellcheck});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};

    if (autofocus != null) {
      if (autofocus == true) {
        result['autofocus'] = 'smart';
      } else {
        result['autofocus'] = autofocus;
      }
    }

    if (autofocus != null) {
      result['enterSendsMessage'] = enterSendsMessage;
    }

    if (autofocus != null) {
      result['placeholder'] = placeholder;
    }

    if (autofocus != null) {
      result['spellcheck'] = spellcheck;
    }

    return result;
  }
}

/// The possible values for showTranslationToggle
enum TranslationToggle { off, on, auto }

/// The possible values for translateConversations
enum TranslateConversations { off, on, auto }

/// This class represents the various configuration options used to finetune the
/// behaviour of UI elements.
abstract class _ChatOptions {
  /// Controls what text appears in the chat subtitle, right below the chat title.
  ///
  /// Defaults to [ChatMode.subject].
  ChatMode? chatSubtitleMode;

  /// Controls what text appears in the chat title, in the header above the messages.
  ///
  /// Defaults to [ChatMode.participants].
  ChatMode? chatTitleMode;

  /// Controls the text direction (for supporting right-to-left languages such
  /// as Arabic and Hebrew).
  ///
  /// Defaults to [TextDirection.rtl].
  TextDirection? dir;

  /// Settings that affect the behavior of the message field
  MessageFieldOptions? messageField;

  /// TODO: messageFilter

  /// Used to control if the Chat Header is displayed in the UI.
  ///
  /// Defaults to true.
  bool? showChatHeader;

  /// Set this to on to show a translation toggle in all conversations.
  /// Set this to auto to show a translation toggle in conversations where there are participants with different locales.
  TranslationToggle? showTranslationToggle;

  /// Overrides the theme used for this chat UI.
  String? theme;

  /// TODO: thirdparties

  /// Enables conversation translation with Google Translate.
  TranslateConversations? translateConversations;

  /// This option specifies which conversations should be translated in this UI.
  List<ConversationBuilder>? conversationsToTranslate;

  /// This option specifies which conversation Ids should be translated in this UI.
  List<String>? conversationIdsToTranslate;

  _ChatOptions({this.chatSubtitleMode,
    this.chatTitleMode,
    this.dir,
    this.messageField,
    this.showChatHeader,
    this.showTranslationToggle,
    this.theme,
    this.translateConversations,
    this.conversationsToTranslate,
    this.conversationIdsToTranslate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};

    if (chatSubtitleMode != null) {
      result['chatSubtitleMode'] = chatSubtitleMode!.getValue();
    }

    if (chatTitleMode != null) {
      result['chatTitleMode'] = chatTitleMode!.getValue();
    }

    if (dir != null) {
      result['dir'] = dir!.getValue();
    }

    if (messageField != null) {
      result['messageField'] = messageField;
    }

    if (showChatHeader != null) {
      result['showChatHeader'] = showChatHeader;
    }

    // 'auto' gets the priority over the boolean value
    if (showTranslationToggle != null) {
      switch (showTranslationToggle) {
        case TranslationToggle.off:
          result['showTranslationToggle'] = false;
          break;
        case TranslationToggle.on:
          result['showTranslationToggle'] = true;
          break;
        case TranslationToggle.auto:
          result['showTranslationToggle'] = 'auto';
          break;
      }
    }

    if (theme != null) {
      result['theme'] = theme;
    }

    if (conversationsToTranslate != null) {
      // Highest priority: TranslateConversations.off
      if (translateConversations != TranslateConversations.off) {
        // High priority: conversationsToTranslate
        // TODO -- This does not work yet, as it results in a string value enclosed by double quotes
        result['translateConversations'] ??= '[' + conversationsToTranslate
          !.map((conversation) => conversation.variableName)
          .join(', ')
          + ']';
      }
    }

    if (conversationIdsToTranslate != null) {
      // Highest priority: TranslateConversations.off
      if (translateConversations != TranslateConversations.off) {
        // Medium priority: conversationIdsToTranslate
        result['translateConversations'] ??= conversationIdsToTranslate;
      }
    }

    // Low priority: translateConversations
    if (translateConversations != null) {
      result['translateConversations'] ??= translateConversations;
    }

    return result;
  }
}

/// Options to configure the behaviour of the [ChatBox] UI.
class ChatBoxOptions extends _ChatOptions{
  ChatBoxOptions({chatSubtitleMode,
      chatTitleMode,
      dir,
      messageField,
      showChatHeader,
      showTranslationToggle,
      theme,
      translateConversations,
      conversationsToTranslate,
      conversationIdsToTranslate,
      })
      : super(chatSubtitleMode: chatSubtitleMode,
          chatTitleMode: chatTitleMode,
          dir: dir,
          messageField: messageField,
          showChatHeader: showChatHeader,
          showTranslationToggle: showTranslationToggle,
          theme: theme,
          translateConversations: translateConversations,
          conversationsToTranslate: conversationsToTranslate,
          conversationIdsToTranslate: conversationIdsToTranslate,
      );
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
