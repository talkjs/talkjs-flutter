import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import './user.dart';

/// A session represents a currently active user.
class Session extends StatelessWidget {
  /// Your TalkJS AppId that can be found your TalkJS [dashboard](https://talkjs.com/dashboard).
  final String appId;

  /// The TalkJS [User] associated with the current user in your application.
  final User me;

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  final String? signature;

  /// The child widget
  final Widget? child;

  Session({Key? key, required this.appId, required this.me, this.signature, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provide the model to all widgets within the app. We're using
    // ChangeNotifierProvider because that's a simple way to rebuild
    // widgets when a model changes. We could also just use
    // Provider, but then we would have to listen to Counter ourselves.
    //
    // Read Provider's docs to learn about all the available providers.
    return ChangeNotifierProvider(
      // Initialize the model in the builder. That way, Provider
      // can own Counter's lifecycle, making sure to call `dispose`
      // when not needed anymore.
      create: (context) => SessionState(appId: appId, me: me, signature: signature),
      child: Container(
          child: child,
      ),
    );
  }
}

/// Session state that is passed to child widgets
class SessionState with ChangeNotifier {
  /// Your TalkJS AppId that can be found your TalkJS [dashboard](https://talkjs.com/dashboard).
  String appId;

  /// The TalkJS [User] associated with the current user in your application.
  User me;

  /// A digital signature of the current [User.id]
  ///
  /// This is the HMAC-SHA256 hash of the current user id, signed with your
  /// TalkJS secret key.
  /// DO NOT embed your secret key within your mobile application / frontend
  /// code.
  String? signature;

  SessionState({required this.appId, required this.me, this.signature});
}

