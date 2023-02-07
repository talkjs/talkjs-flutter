## 0.6.1

- Updated version of flutter-apns lib for fix crash on iOS side when you try to initialize FirebaseCore in your project. This may require you to update if you wanna use Firebase separatly.

## 0.6.0

- BREAKING CHANGE: Updated version numbers for Firebase dependencies. This may require you to update
    your build versions on Android and iOS.
- Fix audio messages not working.

## 0.5.0

- Added the `onUrlNavigation` callback to the ChatBox

## 0.4.0

- BREAKING CHANGE: Changed the `notify` property of the `Participant` to allow for mentions only

## 0.3.1

- Added explicit support for Android and iOS in pubspec.yaml

## 0.3.0

- Add support for push notification on both Android and iOS.
- Fix file upload on Android.

## 0.2.1

- Fixed vertical scrolling when the ChatBox is in a bottom sheet

## 0.2.0

- Implemented the `onLoadingStateChanged` callback
- Implemented the `onCustomMessageAction` callbacks

## 0.1.0

- Initial version.

