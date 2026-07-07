import 'dart:convert';

import './types.dart';

/// Options to configure the behaviour of the [ChatBox] UI.
class ChatBoxOptions {
  /// Controls the text direction (for supporting right-to-left languages such
  /// as Arabic and Hebrew).
  ///
  /// Defaults to [TextDirection.rtl].
  final TextDirection? dir;

  ///Allows users to send and receive custom emojis.
  ///
  ///This adds a set of custom emoji images to the emoji picker, the emoji autocompleter, and emoji reactions.
  ///
  ///Every emoji name *must* start and end with a colon, for example :lol:. Emoji names can be up to 50 characters long, including the colons.
  ///
  ///Make sure you always specify a consistent, backward-compatible set of custom emojis. If an existing message contains a custom emoji that is not specified in customEmojis here, then the emoji cannot be displayed and the textual name will be displayed instead (including colons).
  ///
  ///If you want to allow an emoji to be displayed if it's used in existing data, but not let users select it in new messages/reactions, set the hidden option to true for that emoji.
  final CustomEmojis? customEmojis;

  /// Settings that affect the behavior of the message field
  final MessageFieldOptions? messageField;

  /// TODO: messageFilter

  /// Used to control if the Chat Header is displayed in the UI.
  ///
  /// Defaults to true.
  final bool? showChatHeader;

  /// Set this to on to show a translation toggle in all conversations.
  /// Set this to auto to show a translation toggle in conversations where there are participants with different locales.
  final TranslationToggle? showTranslationToggle;

  /// Overrides the theme used for this chat UI.
  final String? theme;

  final ThemeOptions? themeOptions;

  /// TODO: thirdparties

  /// Enables conversation translation with Google Translate.
  final TranslateConversations? translateConversations;

  const ChatBoxOptions({
    this.dir,
    this.customEmojis,
    this.messageField,
    this.showChatHeader,
    this.showTranslationToggle,
    this.theme,
    this.themeOptions,
    this.translateConversations,
  });

  @override
  String toString() {
    final Map<String, dynamic> result = {
      'dir': ?dir?.name,
      'messageField': ?messageField,
      'showChatHeader': ?showChatHeader,
      'customEmojis': ?customEmojis,
      // 'auto' gets the priority over the boolean value
      'showTranslationToggle': ?showTranslationToggle?.getValue(),
      'translateConversations': ?translateConversations?.getValue(),
    };

    if (themeOptions != null) {
      result['theme'] = themeOptions?.toJson();
    } else if (theme != null) {
      result['theme'] = theme;
    }

    return json.encode(result);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! ChatBoxOptions) {
      return false;
    }

    if (dir != other.dir) {
      return false;
    }

    if (customEmojis != other.customEmojis) {
      return false;
    }

    if (messageField != other.messageField) {
      return false;
    }

    if (showChatHeader != other.showChatHeader) {
      return false;
    }

    if (showTranslationToggle != other.showTranslationToggle) {
      return false;
    }

    if (theme != other.theme) {
      return false;
    }

    if (translateConversations != other.translateConversations) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    dir,
    customEmojis,
    messageField,
    showChatHeader,
    showTranslationToggle,
    theme,
    translateConversations,
  );
}
