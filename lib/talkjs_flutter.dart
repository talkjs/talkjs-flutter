library talkjs;

import 'dart:convert' show json, utf8;
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart' show sha1;
import 'src/notification.dart';

export 'src/chatoptions.dart';
export 'src/conversation.dart';
export 'src/session.dart';
export 'src/chatbox.dart';
export 'src/user.dart';
export 'src/conversationlist.dart';
export 'src/predicate.dart';
export 'src/notification.dart';
export 'src/themeoptions.dart';
export 'src/unreads.dart';

/// The [Talk] object provides utility functions to help use TalkJS.
class Talk {
  /// Compute a Conversation ID based on participants' ids given.
  ///
  /// The order of the parameters does not matter.
  /// Use this method if you want to simply create a conversation between two
  /// users, not related to a particular product, order or transaction.
  static String oneOnOneId(String me, String other) {
    List ids = [me, other];
    ids.sort();

    final encoded = json.encode(ids);
    final digest = sha1.convert(utf8.encode(encoded));

    final hash = digest.toString().toLowerCase();
    return hash.substring(0, 20);
  }

  static Future<void> registerPushNotificationHandlers(
      {AndroidSettings? androidSettings, IOSSettings? iosSettings}) async {
    if ((Platform.isAndroid) && (androidSettings != null)) {
      await registerAndroidPushNotificationHandlers(androidSettings);
    }

    if ((Platform.isIOS) && (iosSettings != null)) {
      await registerIOSPushNotificationHandlers(iosSettings);
    }
  }
}
