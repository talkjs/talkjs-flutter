## 0.8.1
- Updated Firebase dependencies versions

## 0.8.0
- Add `lastMessageTs` and `subject` feedFilters.
- Re-enable support for `onUrlNavigation` callback on the ChatBox.
- Fix push notifications not working on Android in Flutter v3.3.0 and later.

## 0.7.0

- BREAKING CHANGE: To ensure that file uploads work correctly, you'll need to update your
  `AndroidManifest.xml` file as indicated in the [docs](https://talkjs.com/docs/Features/Customizations/File_Sharing/#enabling-file-upload-on-flutter)
- BREAKING CHANGE: Due to a change in the latest versions of iOS, to ensure that microphone
  permission is granted correctly for voice messages, update your `Podfile` as shown in
  the [docs](https://talkjs.com/docs/Features/Customizations/Voice_Messages/#ios)
- Updated dependencies versions

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
