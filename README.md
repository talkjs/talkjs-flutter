# TalkJS Flutter SDK

Official TalkJS SDK for Flutter

**What is TalkJS?**

TalkJS lets you add user-to-user chat to your marketplace, on-demand app, or
social platform.
For more information, visit
[talkjs.com](https://talkjs.com/?ref=flutter-pub-readme).

![Screenshots of TalkJS running on various devices](https://talkjs.com/images/talkjs_header.png?v=060423-1)

Don't hesitate to
[let us know](https://talkjs.com/?chat)
if you have any questions about TalkJS.

## Requirements

- Dart sdk: ">=3.8.0 <4.0.0"
- Flutter: ">=3.32.0"
- Android: `minSDKVersion 23`

## Installation

Edit the dependencies section of your project's `pubspec.yaml` file in your
Flutter project as follows:

```yaml
dependencies:
  talkjs_flutter: ^0.1.0
```

Run the command: `flutter pub get` on the command line or through Android
Studio's **Get dependencies** button.

## Usage

Import TalkJS in your project source files.

```dart
import 'package:talkjs_flutter/talkjs_flutter.dart';
```

Then follow our
[Flutter guide](https://talkjs.com/docs/Getting_Started/Frameworks/Flutter/)
to start using TalkJS in your project.

## TalkJS is fully forward compatible

We promise to never break API compatibility.
We may at times deprecate methods or fields, but we will never remove them.
If something that used to work stops working, then that's a bug.
Please [report it](https://talkjs.com/?chat) and we'll fix it asap.

The package is being released in a beta state.
The reason for this is that there are things that one can do with the TalkJS
JavaScript SDK that aren't possible with the Flutter SDK.
We will release v1.0.0 of this package once the two SDKs are similar in terms
of features.
This however does not take away from our commitment to always maintain backward
compatibility.
So you can be assured that the package is stable for production use.
