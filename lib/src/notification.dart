import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_apns_only/flutter_apns_only.dart';

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

extension VisibilityToLocalNotification on AndroidVisibility {
  NotificationVisibility toLocalNotification() {
    switch (this) {
      case AndroidVisibility.PRIVATE:
        return NotificationVisibility.private;
      case AndroidVisibility.PUBLIC:
        return NotificationVisibility.public;
      case AndroidVisibility.SECRET:
        return NotificationVisibility.secret;
    }
  }
}

enum AndroidImportance {
  HIGH,
  DEFAULT,
  LOW,
  MIN,
  NONE,
}

extension ImportanceToLocalNotification on AndroidImportance {
  Importance toLocalNotification() {
    switch (this) {
      case AndroidImportance.HIGH:
        return Importance.high;
      case AndroidImportance.DEFAULT:
        return Importance.defaultImportance;
      case AndroidImportance.LOW:
        return Importance.low;
      case AndroidImportance.MIN:
        return Importance.min;
      case AndroidImportance.NONE:
        return Importance.none;
    }
  }
}

class AndroidSettings {
  final String channelId;
  final String channelName;
  final bool? badge;
  final String? channelDescription;
  final bool? lights;
  final Color? lightColor;
  final String playSound;
  final AndroidImportance? importance;
  final AndroidVisibility? visibility;
  final bool? vibrate;
  final Int64List? vibrationPattern;

  const AndroidSettings({
    required this.channelId,
    required this.channelName,
    this.badge,
    this.channelDescription,
    this.lights,
    this.lightColor,
    this.playSound = 'default',
    this.importance,
    this.visibility,
    this.vibrate,
    this.vibrationPattern,
  });
}

class IOSSettings {
  final bool useFirebase;
  const IOSSettings({this.useFirebase = false});
}

String? fcmToken;
String? apnsToken;

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
AndroidSettings? _androidSettings;
final _activeNotifications = <String, List<String>>{};
int _nextId = 0;
final _showIdFromNotificationId = <String, int>{};
final _receivePort = ReceivePort();
final _imageCache = <String, Uint8List>{};

Future<Uint8List?> _imageDataFromUrl(String url) async {
  // Use the cached image
  if (_imageCache.containsKey(url)) {
    print("📘 _imageDataFromUrl ($url): Using cached image");
    return _imageCache[url]!;
  }

  try {
    final response = await http.get(Uri.parse(url));
    print("📘 _imageDataFromUrl ($url): $response");

    // Cache the response only if the HTTP request was successful
    if (response.statusCode < 400) {
      _imageCache[url] = response.bodyBytes;
    }

    return response.bodyBytes;
  } on Exception catch (e) {
    print("📘 _imageDataFromUrl Exception ($url): $e");
    return null;
  }
}

Future<ByteArrayAndroidBitmap?> _androidBitmapFromUrl(String? url) async {
  if (url == null) {
    return null;
  }

  final imageData = await _imageDataFromUrl(url);
  if (imageData == null) {
    return null;
  }

  return ByteArrayAndroidBitmap(imageData);
}

Future<ByteArrayAndroidIcon?> _androidIconFromUrl(String? url) async {
  if (url == null) {
    return null;
  }

  final imageData = await _imageDataFromUrl(url);
  if (imageData == null) {
    return null;
  }

  return ByteArrayAndroidIcon(imageData);
}

Future<void> _onFCMBackgroundMessage(RemoteMessage firebaseMessage) async {
  print("📘 Handling a background message: ${firebaseMessage.messageId}");

  print('📘 Message data: ${firebaseMessage.data}');

  if (firebaseMessage.notification != null) {
    print(
        '📘 Message also contained a notification: ${firebaseMessage.notification}');
  }

  // onBackgroundMessage runs on a separate isolate, so we're passing the message to the main isolate
  IsolateNameServer.lookupPortByName('talkjsFCMPort')
      ?.send(firebaseMessage.toMap());
}

Future<void> _onReceiveMessageFromPort(
    Map<String, dynamic> firebaseMessageMap) async {
  final firebaseMessage = RemoteMessage.fromMap(firebaseMessageMap);
  print("📘 _onReceiveMessageFromPort: ${firebaseMessage.messageId}");

  final data = firebaseMessage.data;
  StyleInformation styleInformation;
  styleInformation = MessagingStyleInformation(Person(name: 'me'));
  int showId;
  if (data['talkjs'] is String) {
    print("📘 _onFCMBackgroundMessage: data['talkjs'] is String");
    final Map<String, dynamic> talkjsData = json.decode(data['talkjs']);
    final String notificationId = talkjsData['conversation']['id'];

    if (!_showIdFromNotificationId.containsKey(notificationId)) {
      _showIdFromNotificationId[notificationId] = _nextId;
      _nextId += 1;
    }

    showId = _showIdFromNotificationId[notificationId]!;

    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(talkjsData['timestamp']);

    final activeNotifications = _activeNotifications[notificationId];

    if (activeNotifications == null) {
      print("📘 _onFCMBackgroundMessage: activeNotifications == null");
      _activeNotifications[notificationId] = [data['talkjs']];

      final attachment = talkjsData['message']['attachment'];

      if (attachment != null) {
        print("📘 _onFCMBackgroundMessage: attachment != null");
        final picture = await _androidBitmapFromUrl(attachment['url']);
        if (picture != null) {
          print("📘 _onFCMBackgroundMessage: picture != null");
          styleInformation = BigPictureStyleInformation(picture);
        } else {
          print("📘 _onFCMBackgroundMessage: picture == null");
        }
      } else {
        print("📘 _onFCMBackgroundMessage: attachment == null");
        final sender = talkjsData['sender'];
        styleInformation = MessagingStyleInformation(
          Person(
            name: 'me',
          ),
          groupConversation:
              talkjsData['conversation']['participants'].length > 2,
          messages: [
            Message(
              talkjsData['message']['text'],
              timestamp,
              Person(
                icon: await _androidIconFromUrl(sender['photoUrl']),
                key: sender['id'],
                name: sender['name'],
              ),
            ),
          ],
        );
      }
    } else {
      print("📘 _onFCMBackgroundMessage: activeNotifications != null");
      activeNotifications.add(data['talkjs']);
      final messages = <Message>[];
      for (final talkjsString in activeNotifications) {
        final Map<String, dynamic> messageTalkjsData =
            json.decode(talkjsString);
        final messageTimestamp =
            DateTime.fromMillisecondsSinceEpoch(messageTalkjsData['timestamp']);
        final messageSender = talkjsData['sender'];

        messages.add(
          Message(
            messageTalkjsData['message']['text'],
            messageTimestamp,
            Person(
              icon: await _androidIconFromUrl(messageSender['photoUrl']),
              key: messageSender['id'],
              name: messageSender['name'],
            ),
          ),
        );
      }

      styleInformation = MessagingStyleInformation(
        Person(
          name: 'me',
        ),
        groupConversation:
            talkjsData['conversation']['participants'].length > 2,
        messages: messages,
      );
    }
  } else {
    print("📘 _onFCMBackgroundMessage: data['talkjs'] is NOT String");
    showId = _nextId;
    _nextId += 1;

    styleInformation = DefaultStyleInformation(false, false);
  }

  // We default to not playing sounds, unless a non-empty string is provided
  final playSound = _androidSettings!.playSound.isNotEmpty;
  RawResourceAndroidNotificationSound? sound;

  // We use the string 'default' for the default sound (for compatibility with the React Natve SDK)
  if (playSound && (_androidSettings!.playSound != 'default')) {
    sound = RawResourceAndroidNotificationSound(_androidSettings!.playSound);
  }

  final platformChannelSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      _androidSettings!.channelId,
      _androidSettings!.channelName,
      channelDescription: _androidSettings!.channelDescription,
      importance: _androidSettings!.importance?.toLocalNotification() ??
          Importance.high,
      playSound: playSound,
      sound: sound,
      enableVibration: _androidSettings!.vibrate ?? true,
      vibrationPattern: _androidSettings!.vibrationPattern,
      channelShowBadge: _androidSettings!.badge ?? true,
      enableLights: _androidSettings!.lights ?? false,
      ledColor: _androidSettings!.lightColor,
      visibility: _androidSettings!.visibility?.toLocalNotification(),
      styleInformation: styleInformation,
    ),
  );

  await _flutterLocalNotificationsPlugin.show(
    showId, // id
    data['title'], // title
    data['message'], // body
    platformChannelSpecifics, // notificationDetails
    payload: data['talkjs'],
  );
}

// The commented code is for when we will upgrade to flutter_local_notifications version 10
void _onSelectNotification(NotificationResponse details) {
  final payload = details.payload;

  print('📘 _onSelectNotification: $payload');

  if (payload != null) {
    final Map<String, dynamic> talkjsData = json.decode(payload);
    final String notificationId = talkjsData['conversation']['id'];
    _activeNotifications.remove(notificationId);
  }
}

void _onFCMTokenRefresh(String token) {
  print('📘 Firebase onTokenRefresh: $token');

  fcmToken = token;

  // TODO: Update the token on the Talkjs server once we have the data layer SDK ready
}

Future<void> registerAndroidPushNotificationHandlers(
    AndroidSettings androidSettings) async {
  // Get the token each time the application loads
  fcmToken = await FirebaseMessaging.instance.getToken();
  print('📘 Firebase token: $fcmToken');

  // Update the token each time it refreshes
  FirebaseMessaging.instance.onTokenRefresh.listen(_onFCMTokenRefresh);

  await _flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: _onSelectNotification,
  );

  _androidSettings = androidSettings;

  try {
    final activeNotifications = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications();

    if (activeNotifications != null) {
      for (final displayedNotification in activeNotifications) {
        if (displayedNotification.payload != null) {
          final Map<String, dynamic> talkjsData =
              json.decode(displayedNotification.payload!);

          if ((talkjsData['conversation'] != null) &&
              (talkjsData['conversation']['id'] != null)) {
            print('📘 Existing notification: ${displayedNotification.payload}');
            final String notificationId = talkjsData['conversation']['id'];

            if (!_showIdFromNotificationId.containsKey(notificationId)) {
              _showIdFromNotificationId[notificationId] = _nextId;
              _nextId += 1;
            }

            if (_activeNotifications[notificationId] == null) {
              _activeNotifications[notificationId] = [
                displayedNotification.payload!
              ];
            } else {
              _activeNotifications[notificationId]!
                  .add(displayedNotification.payload!);
            }
          }
        }
      }
    }
  } on PlatformException {
    // PlatformException is raised on Android < 6.0
    // Simply ignoring this part
  }

  IsolateNameServer.registerPortWithName(
      _receivePort.sendPort, 'talkjsFCMPort');
  _receivePort
      .listen((message) async => await _onReceiveMessageFromPort(message));

  FirebaseMessaging.onBackgroundMessage(_onFCMBackgroundMessage);
}

Future<void> _onPush(String name, ApnsRemoteMessage message) async {
  final payload = message.payload;
  print('📘 _onPush $name: ${payload["notification"]?["title"]}');

  final action = UNNotificationAction.getIdentifier(payload['data']);

  if (action != null && action != UNNotificationAction.defaultIdentifier) {
    print('📘 _onPush action: $action');
  }
}

Future<void> registerIOSPushNotificationHandlers(
    IOSSettings iosSettings) async {
  final connector = ApnsPushConnectorOnly();

  connector.configureApns(
    onLaunch: (data) => _onPush('onLaunch', data),
    onResume: (data) => _onPush('onResume', data),
    onMessage: (data) => _onPush('onMessage', data),
    onBackgroundMessage: (data) => _onPush('onBackgroundMessage', data),
  );

  if (iosSettings.useFirebase) {
    fcmToken = await FirebaseMessaging.instance.getToken();

    print('📘 apns token refresh: $fcmToken');
  } else {
    connector.token.addListener(() {
      print('📘 apns token refresh: ${connector.token.value}');

      apnsToken = connector.token.value;
    });
  }
}
