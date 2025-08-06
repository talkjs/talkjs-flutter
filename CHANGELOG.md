## 0.16.0

- **Breaking change:** Updated version numbers for Firebase dependencies. This may require you to update
  your build versions on Android and iOS.

## 0.15.1

- Upgrade `talkjs_flutter_inappwebview` dependency.

## 0.15.0

- Add `registerBackgroundHandler` property to AndroidSettings passed to `registerPushNotificationHandlers()`
- Add `Talk.handleFCMBackgroundMessage` function
- Fix the SDK processing non-TalkJS related push notifications.

## 0.14.0

- Add `onUnreadsChange` property to Session
- Deprecate `unreads` property of Session

## 0.13.1

- Fix stack overflow when comparing sessions

## 0.13.0

- Add `scrollToMessage` property to Chatbox.
- Fix push notification device token registration not working in release builds.
- Fix `Session.hasValidCredentials` not working.

## 0.12.1

- Fix conflict with `flutter_inappwebview` package

## 0.12.0

- Add `token` and `tokenFetcher` properties to Session. This part of our efforts at [improving identity verification and authentication](https://talkjs.com/docs/Features/Security_Settings/Authentication/). [See the reference documentation](https://talkjs.com/docs/Features/Security_Settings/Advanced_Authentication/#token-reference) for full details on the technical requirements for the JSON Web Token (JWT).
- Deprecated the `signature` prop on the [Session](https://talkjs.com/docs/Reference/Flutter_SDK/Session/) component. Signature-based authentication will continue to be supported indefinitely, but [JWT-based authentication](https://talkjs.com/docs/Features/Security_Settings/Authentication/) is recommended for new projects.

## 0.11.0

- Added `enableZoom` property to Chatbox.
- Added `sendMessage` method to Conversation.

## 0.10.2

- Fixed push notifications not working on Android when app has been terminated.
- Fixed `MessageFieldOptions` not working.
- Updated dependencies' versions.

## 0.10.1

- Relaxed version requirements for the Dart SDK and http packages.

## 0.10.0

- Added support for Firebase push notifications on iOS.
- Added compound predicates to Chatbox and ConversationList.
- Added missing `themeOptions` property in ConversationList.
- Fixed push notification error when sender's photoUrl is invalid.
- Fixed build issue on Android Gradle Plugin (AGP) 8.0+.

## 0.9.3

- Fixed links in Android not opening in the external browser by default.

## 0.9.2

- Fixed build issue on Xcode 15.
- Fixed runtime error on iOS.
- Updated dependencies' versions.

## 0.9.1

- Fixed messages getting marked as read only after clicking the message field.
  Now they should get marked after the Chatbox has loaded.

## 0.9.0

- Added `setPushRegistration`, `unsetPushRegistration`, and `clearPushRegistrations` to the Session.
- Added `destroy` and `hasValidCredentials` to the Session.
- Added `onMessage` to the Session.
- Added `unreads` to the Session.
- Updated dependencies' versions.

## 0.8.1

- Updated Firebase dependencies versions.

## 0.8.0

- Added `lastMessageTs` and `subject` feedFilters.
- Re-enabled support for `onUrlNavigation` callback on the ChatBox.
- Fixed push notifications not working on Android in Flutter v3.3.0 and later.

## 0.7.0

- **Breaking change:** To ensure that file uploads work correctly, you'll need to update your
  `AndroidManifest.xml` file as indicated in the [docs](https://talkjs.com/docs/Features/Customizations/File_Sharing/#enabling-file-upload-on-flutter).
- **Breaking change:** Due to a change in the latest versions of iOS, to ensure that microphone
  permission is granted correctly for voice messages, update your `Podfile` as shown in
  the [docs](https://talkjs.com/docs/Features/Customizations/Voice_Messages/#ios).
- Updated dependencies versions.

## 0.6.0

- **Breaking change:** Updated version numbers for Firebase dependencies. This may require you to update
  your build versions on Android and iOS.
- Fixed audio messages not working.

## 0.5.0

- Added the `onUrlNavigation` callback to the ChatBox.

## 0.4.0

- **Breaking change:** Changed the `notify` property of the `Participant` to allow for mentions only.

## 0.3.1

- Added explicit support for Android and iOS in pubspec.yaml.

## 0.3.0

- Added support for push notification on both Android and iOS.
- Fixed file upload on Android.

## 0.2.1

- Fixed vertical scrolling when the ChatBox is in a bottom sheet.

## 0.2.0

- Implemented the `onLoadingStateChanged` callback.
- Implemented the `onCustomMessageAction` callbacks.

## 0.1.0

- Initial version.
