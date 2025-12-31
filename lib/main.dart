import 'dart:async';
import 'package:daad_app/features/services/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'app.dart';
import 'firebase_options.dart';

/// 🔔 Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background messages here
}

final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: android, iOS: ios);
  await _fln.initialize(initSettings);
}

Future<void> _initFcm() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // iOS permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true, provisional: false,
  );

  // Token
  // final token = await FirebaseMessaging.instance.getToken();
  // debugPrint('FCM token: $token');
  FirebaseMessaging.instance.subscribeToTopic('offers');

  // Foreground messages → show local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await _fln.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daad_channel', 'Daad Notifications',
            importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  });
}

// Future<void> _ensureAnonymousAuth() async {
//   try {
//     if (FirebaseAuth.instance.currentUser == null) {
//       await FirebaseAuth.instance.signInAnonymously();
//     }
//   } on FirebaseAuthException catch (e) {
//     print('FirebaseAuth error: ${e.code} -> ${e.message}');
//     rethrow;
//   }
// }

/// Function to check data availability in Firestore
Future<void> _checkFirestoreData() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('services').get();
    if (snapshot.docs.isEmpty) {
      print('لا توجد بيانات في collection "services".');
    } else {
      print('تم العثور على بيانات في collection "services".');
      snapshot.docs.forEach((doc) {
        print('Document data: ${doc.data()}');
      });
    }
  } catch (e) {
    print('خطأ في جلب البيانات من Firestore: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // await _ensureAnonymousAuth();
  await _initLocalNotifications();
  // await _initFcm();
  await RemoteConfigService.instance.ensureLoaded();

  // Check Firestore data availability
  await _checkFirestoreData();

  runApp(const ProviderScope(child: DaadRoot()));
}

class DaadRoot extends StatelessWidget {
  const DaadRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const DaadApp();
  }
}
