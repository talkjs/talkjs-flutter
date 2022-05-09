import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

enum AndroidImportance {
  HIGH,
  DEFAULT,
  LOW,
  MIN,
  NONE,
}

enum AndroidVisibility {
  /// Show the notification on all lockscreens, but conceal sensitive or private information on secure lockscreens.
  PRIVATE,
  /// Show this notification in its entirety on all lockscreens.
  PUBLIC,
  /// Do not reveal any part of this notification on a secure lockscreen.
  ///
  /// Useful for notifications showing sensitive information such as banking apps.
  SECRET,
}

class AndroidChannel {
  final String channelId;
  final String channelName;
  final bool? badge;
  final String? channelDescription;
  final bool? lights;
  final String? lightColor;
  final bool? bypassDnd;
  final String? playSound;
  final AndroidImportance? importance;
  final AndroidVisibility? visibility;
  final bool? vibrate;
  final Int64List? vibrationPattern;

  const AndroidChannel({
    required this.channelId,
    required this.channelName,
    this.badge,
    this.channelDescription,
    this.lights,
    this.lightColor,
    this.bypassDnd,
    this.playSound,
    this.importance,
    this.visibility,
    this.vibrate,
    this.vibrationPattern,
  });
}

class IOSPermissions {
  final bool? alert;
  final bool? badge;
  final bool? sound;
  final bool? critical;
  const IOSPermissions({
    this.alert,
    this.badge,
    this.sound,
    this.critical,
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  //await Firebase.initializeApp(
  //  //options: currentPlatform, // TODO
  //);


  print("📘 Handling a background message: ${message.messageId}");

  print('📘 Message data: ${message.data}');

  if (message.notification != null) {
    print('📘 Message also contained a notification: ${message.notification}');
  }
}

Future<void> registerAndroidPushNotificationHandlers(FirebaseOptions currentPlatform, AndroidChannel androidChannel) async {
  // TODO: Should the Firebase initialization be done here or in the client app?
  await Firebase.initializeApp(
    options: currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  /*
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
  */

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📘 Got a message whilst in the foreground!');
    print('📘 Message data: ${message.data}');

    if (message.notification != null) {
      print('📘 Message also contained a notification: ${message.notification}');
    }

    /*
    RemoteNotification notification = message.notification;
    AndroidNotification android = message.notification?.android;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channel.description,
            icon: android?.smallIcon,
            // other properties...
          ),
        )
      );
    }
    */
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Get the token each time the application loads
  String? token = await FirebaseMessaging.instance.getToken();
  print('📘 Firebase token: $token');

  // Any time the token refreshes, store this in the database too.
  //FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
}

