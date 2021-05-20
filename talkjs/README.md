# TalkJS

Flutter SDK for [TalkJS](https://talkjs.com)

## Requirements

- Dart sdk: ">=2.12.0 <3.0.0"
- Flutter: ">=1.17.0"
- Android: `minSDKVersion 19`

## Installation

Assumption: You have an existing Flutter Project. You can follow this [guide](https://flutter.dev/docs/get-started/test-drive#create-app)
on how to create a new Flutter Project.

First, clone this repository on your computer.
```sh
git clone https://github.com/talkjs/flutter-sdk-victor.git
```

To add the package as a dependency, edit the dependencies section of  
your project's **pubspec.yaml** file in your Flutter project as follows:

```yaml
dependencies:
  talkjs:
    path: {path to directory containing this repository}/flutter-sdk-victor/talkjs
```

The path specified should be an absolute path from the root directory of
your system.

Run the command: ```flutter pub get``` on the command line or through
Android Studio's **Get dependencies** button.

## Getting Started

If you used the [guide](https://flutter.dev/docs/get-started/test-drive#create-app)
mentioned above to create a new Flutter project, replace everything in
**lib/main.dart** with the following code:

```dart
import 'package:flutter/material.dart';
import 'package:talkjs/talkjs.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalkJS Demo',
      home: Scaffold(
        body: initChat()
      )
    );
  }

  Widget initChat() {
    final me = User(id: '123456', name: 'Alice');
    final other = User(id: '654321', name: 'Sebastian');

    final session = Session(appId: 'YOUR_APP_ID', me: me);
    final conversation = session.getOrCreateConversation(
        Talk.oneOnOneId(me.id, other.id)
    );

    conversation.setParticipant(me);
    conversation.setParticipant(other);

    final chatBox = session.createChatbox(conversation);
    return chatBox.mount();
  }
}
```

Replace ```YOUR_APP_ID``` with the App ID on the TalkJS [Dashboard](https://talkjs.com/dashboard/login.)

For users with an existing Flutter project, you can use the ```Widget``` returned
by the ```initChat``` function in the example above as part of an existing
```Widget``` definition or a navigation route

## Documentation

The SDK API reference can be found in **doc/api**. 