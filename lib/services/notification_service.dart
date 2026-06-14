import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Background handler — top level bo'lishi shart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await NotificationService.showLocal(msg);
}

class NotificationService {
  NotificationService._();

  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Ruxsat so'rash
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((msg) => showLocal(msg));
  }

  // FCM token ni Firestore ga saqlash
  static Future<void> saveToken(String uid) async {
    final token = await _fcm.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});

    // Token yangilansa
    _fcm.onTokenRefresh.listen((t) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': t});
    });
  }

  // Local notification ko'rsatish
  static Future<void> showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;

    await _local.show(
      msg.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bolajon_channel',
          'BolaJon OS',
          channelDescription: 'BolaJon OS bildirishnomalar',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Ota-ona bolaga xabar yuboradi (Cloud Functions orqali)
  static Future<void> sendToChild({
    required String childToken,
    required String title,
    required String body,
  }) async {
    // Bu Cloud Functions orqali ishlaydi
    // lib/services/functions_service.dart da ko'ring
    await FirebaseFirestore.instance.collection('notifications').add({
      'to': childToken,
      'title': title,
      'body': body,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}