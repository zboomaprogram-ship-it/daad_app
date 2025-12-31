 import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OldNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'إشعار',
        body: message.notification?.body ?? '',
        payload: message.data['deepLink'],
      );
    });

    // Listen to Firestore notifications collection
    _listenToNotifications();
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daad_channel',
      'DAAD Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Listen to Firestore notifications
  static void _listenToNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('createdAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _showLocalNotification(
          title: data['title'] ?? 'إشعار',
          body: data['body'] ?? '',
          payload: data['deepLink'],
        );
      }
    });
  }

  // Send notification via Firestore (triggers Cloud Function)
  static Future<void> sendNotification({
    required String title,
    required String body,
    String? userId,
    String? deepLink,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'userId': userId,
      'topic': userId == null ? 'all' : null,
      'deepLink': deepLink,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}