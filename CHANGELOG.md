- Add `token` and `tokenFetcher` properties to Session. This part of our efforts at [impoving identity verification and authentication](https://talkjs.com/docs/Features/Security_Settings/Authentication/).

[See the reference documentation](https://talkjs.com/docs/Features/Security_Settings/Advanced_Authentication/#token-reference) for full details on the technical requirements for the JSON Web Token(JWT).

## 0.11.0

- Add `enableZoom` property to Chatbox.
- Add `sendMessage` method to Conversation.

## 0.10.2

- Fix push notifications not working on Android when app has been terminated.
- Fix `MessageFieldOptions` not working.
- Update dependencies' versions.

## 0.10.1

- Relaxed version requirements for the Dart SDK and http packages

## 0.10.0

- Add support for Firebase push notifications on iOS.
- Add compound predicates to Chatbox and ConversationList.
- Add missing `themeOptions` property in ConversationList.
- Fix push notification error when sender's photoUrl is invalid.
- Fix build issue on Android Gradle Plugin (AGP) 8.0+

## 0.9.3

- Fix links in Android not opening in the external browser by default.

## 0.9.2

- Fix build issue on Xcode 15.
- Fix runtime error on iOS.
- Update dependencies' versions.

## 0.9.1

- Fix messages getting marked as read only after clicking the message field.
  Now they should get marked after the Chatbox has loaded.

## 0.9.0

- Add `setPushRegistration`, `unsetPushRegistration`, and `clearPushRegistrations` to the Session.
- Add `destroy` and `hasValidCredentials` to the Session.
- Add `onMessage` to the Session.
- Add `unreads` to the Session.
- Update dependencies' versions.

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
