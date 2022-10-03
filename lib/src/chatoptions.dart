import 'dart:convert';

import './chatbox.dart';

/// The values that dictate the chat direction.
enum TextDirection {
  /// right-to-left
  rtl,
  /// left-to-right
  ltr,
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
  final bool? autofocus; // Convert to "smart"

  /// If set to true, pressing the enter key sends the message
  /// (if there is text in the message field).
  ///
  /// When set to false, the only way to send a message is by clicking or
  /// touching the "Send" button.
  /// Defaults to true.
  final bool? enterSendsMessage;

  /// The text displayed in the message field when the user hasn't started
  /// typing anything.
  final String? placeholder;

  /// This enables spell checking.
  ///
  /// Note that setting this to true may also enable autocorrect on some mobile
  /// devices.
  /// Defaults to false
  final bool? spellcheck;

  /// TODO: visible

  const MessageFieldOptions({this.autofocus, this.enterSendsMessage, this.placeholder, this.spellcheck});

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

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

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is MessageFieldOptions)) {
      return false;
    }

    if (autofocus != other.autofocus) {
      return false;
    }

    if (enterSendsMessage != other.enterSendsMessage) {
      return false;
    }

    if (placeholder != other.placeholder) {
      return false;
    }

    if (spellcheck != other.spellcheck) {
      return false;
    }

    return true;
  }

  int get hashCode => Object.hash(autofocus, enterSendsMessage, placeholder, spellcheck);
}

/// The possible values for showTranslationToggle
enum TranslationToggle { off, on, auto }

extension TranslationToggleValue on TranslationToggle {
  /// Converts this enum's values to String.
  dynamic getValue() {
    switch (this) {
      case TranslationToggle.off:
        return false;
      case TranslationToggle.on:
        return true;
      case TranslationToggle.auto:
        return 'auto';
    }
  }
}

/// The possible values for translateConversations
enum TranslateConversations { off, on, auto }

extension TranslateConversationsValue on TranslateConversations {
  /// Converts this enum's values to String.
  dynamic getValue() {
    switch (this) {
      case TranslateConversations.off:
        return false;
      case TranslateConversations.on:
        return true;
      case TranslateConversations.auto:
        return 'auto';
    }
  }
}

/// Options to configure the behaviour of the [ChatBox] UI.
class ChatBoxOptions {
  /// Controls the text direction (for supporting right-to-left languages such
  /// as Arabic and Hebrew).
  ///
  /// Defaults to [TextDirection.rtl].
  final TextDirection? dir;

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

  /// TODO: thirdparties

  /// Enables conversation translation with Google Translate.
  final TranslateConversations? translateConversations;

  const ChatBoxOptions({
    this.dir,
    this.messageField,
    this.showChatHeader,
    this.showTranslationToggle,
    this.theme,
    this.translateConversations,
  });

  /// For internal use only. Implementation detail that may change anytime.
  ///
  /// This method is used instead of toJson, as we need to output valid JS
  /// that is not valid JSON.
  /// The toJson method is intentionally omitted, to produce an error if
  /// someone tries to convert this object to JSON instead of using the
  /// getJsonString method.
  String getJsonString(ChatBoxState chatBox) {
    final result = <String, dynamic>{};

    if (dir != null) {
      result['dir'] = dir!.name;
    }

    if (messageField != null) {
      result['messageField'] = messageField;
    }

    if (showChatHeader != null) {
      result['showChatHeader'] = showChatHeader;
    }

    // 'auto' gets the priority over the boolean value
    if (showTranslationToggle != null) {
      result['showTranslationToggle'] = showTranslationToggle!.getValue();
    }

    if (theme != null) {
      result['theme'] = theme;
    }

    if (translateConversations != null) {
      result['translateConversations'] = translateConversations!.getValue();
    }

    chatBox.setExtraOptions(result);

    return json.encode(result);
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (!(other is ChatBoxOptions)) {
      return false;
    }

    if (dir != other.dir) {
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

  int get hashCode => Object.hash(
    dir,
    messageField,
    showChatHeader,
    showTranslationToggle,
    theme,
    translateConversations,
  );
}

