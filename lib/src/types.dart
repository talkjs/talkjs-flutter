// Typedefs

typedef LoadingStateHandler = void Function(LoadingState state);
typedef CustomEmojis = Map<String, CustomEmojiDefinition>;

// Enums

enum LoadingState { loading, loaded }

/// The values that dictate the chat direction.
enum TextDirection {
  /// right-to-left
  rtl,

  /// left-to-right
  ltr,
}

/// The possible values for showTranslationToggle
enum TranslationToggle {
  off,
  on,
  auto;

  dynamic getValue() => switch (this) {
    .off => false,
    .on => true,
    .auto => 'auto',
  };
}

/// The possible values for translateConversations
enum TranslateConversations {
  off,
  on,
  auto;

  dynamic getValue() => switch (this) {
    .off => false,
    .on => true,
    .auto => 'auto',
  };
}

enum MessageOrigin {
  web,
  rest,
  email,
  import;

  factory MessageOrigin.fromString(String str) => switch (str) {
    'web' => .web,
    'rest' => .rest,
    'email' => .email,
    'import' => .import,
    _ => throw ArgumentError('Unknown MessageOrigin $str'),
  };

  String toString() => this.name;
}

enum MessageType {
  UserMessage,
  SystemMessage;

  factory MessageType.fromString(String str) => switch (str) {
    'UserMessage' => .UserMessage,
    'SystemMessage' => .SystemMessage,
    _ => throw ArgumentError('Unknown MessageType $str'),
  };

  String toString() => this.name;
}

// Classes

class CustomEmojiDefinition {
  final String url;
  final bool? hidden;

  const CustomEmojiDefinition({required this.url, this.hidden = null});

  Map<String, dynamic> toJson() => {'url': url, 'hidden': ?hidden};
}

class ThemeOptions {
  final String? name;
  final Map<String, dynamic>? custom;

  const ThemeOptions({this.name, this.custom});

  Map<String, dynamic> toJson() => {'name': ?name, 'custom': ?custom};
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

  const MessageFieldOptions({
    this.autofocus,
    this.enterSendsMessage,
    this.placeholder,
    this.spellcheck,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'enterSendsMessage': ?enterSendsMessage,
      'placeholder': ?placeholder,
      'spellcheck': ?spellcheck,
    };

    if (autofocus != null) {
      if (autofocus == true) {
        result['autofocus'] = 'smart';
      } else {
        result['autofocus'] = autofocus;
      }
    }

    return result;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! MessageFieldOptions) {
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

  int get hashCode =>
      Object.hash(autofocus, enterSendsMessage, placeholder, spellcheck);
}
