import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:talkjs_flutter/talkjs_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request push notification permissions
  if (Platform.isAndroid) {
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();
  } else if (Platform.isIOS) {
    await ApnsPushConnectorOnly().requestNotificationPermissions(
        const IosNotificationSettings(sound: true, alert: true, badge: true));
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Talk.registerPushNotificationHandlers(
    androidSettings: const AndroidSettings(
      channelId: 'com.talkjs.flutter_push_example.messages',
      channelName: 'Messages',
    ),
    iosSettings: const IOSSettings(useFirebase: true),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final session = Session(appId: 'YOUR_APP_ID', enablePushNotifications: true);

    final me = session.getUser(
      id: '123456',
      name: 'Alice',
      email: ['alice@example.com'],
      photoUrl: 'https://demo.talkjs.com/img/alice.jpg',
      welcomeMessage: 'Hey there! How are you? :-)',
      role: 'default',
    );

    session.me = me;

    final other = session.getUser(
      id: '654321',
      name: 'Sebastian',
      email: ['Sebastian@example.com'],
      photoUrl: 'https://demo.talkjs.com/img/sebastian.jpg',
      welcomeMessage: 'Hey, how can I help?',
      role: 'default',
    );

    final conversation = session.getConversation(
      id: Talk.oneOnOneId(me.id, other.id),
      participants: {Participant(me), Participant(other)},
    );

    return MaterialApp(
      title: 'TalkJS Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TalkJS Demo'),
        ),
        body: ChatBox(
          session: session,
          conversation: conversation,
        ),
      ),
    );
  }
}
