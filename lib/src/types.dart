// Enums

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
