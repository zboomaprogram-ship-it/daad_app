import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/network_utils/secure_config_service.dart';
import 'package:daad_app/core/utils/services/debug_logger.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  // 🔐 استخدام المفاتيح من Remote Config
  static String get oneSignalAppId => SecureConfigService.oneSignalAppId;
  static String get oneSignalRestApiKey =>
      SecureConfigService.oneSignalRestApiKey;

  static Future<void> initialize() async {
    try {
      final appId = oneSignalAppId;
      if (appId.isEmpty || appId == '') {
        DebugLogger.error(
          '❌ OneSignal App ID is empty! Skipping initialization.',
        );
        return;
      }

      DebugLogger.info('🔔 Initializing OneSignal...');

      // Set debug logging level
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // ✅ Disable location tracking to avoid requiring location permissions
      OneSignal.Location.setShared(false);

      // Initialize OneSignal with App ID
      OneSignal.initialize(appId);

      // Request notification permission (may fail silently on iOS)
      try {
        await OneSignal.Notifications.requestPermission(true);
      } catch (permissionError) {
        DebugLogger.warning('⚠️ Permission request failed: $permissionError');
        // Don't throw - continue anyway
      }

      DebugLogger.success(
        '✅ OneSignal initialized with App ID: ${appId.substring(0, 8)}...',
      );
    } catch (e, stackTrace) {
      DebugLogger.error('❌ OneSignal initialization failed: $e');
      DebugLogger.error('Stack trace: $stackTrace');
      // Don't rethrow - allow app to continue without notifications
    }
  }

  /// ✅ Send notification with deep link support
  /// Uses filters with tags for reliable delivery
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? userId,
    String? deepLink,
  }) async {
    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'userId': userId,
        'deepLink': deepLink,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });

      // Send push notification via OneSignal REST API
      final url = Uri.parse('https://onesignal.com/api/v1/notifications');

      final Map<String, dynamic> notification = {
        'app_id': oneSignalAppId,
        'headings': {'en': title, 'ar': title},
        'contents': {'en': body, 'ar': body},
        // Android specific settings
        'priority': 10,
        'android_visibility': 1,
        // iOS specific settings
        'ios_sound': 'default',
        'ios_badgeType': 'Increase',
        'ios_badgeCount': 1,
      };

      // ✅ Add deep link data
      if (deepLink != null && deepLink.isNotEmpty) {
        notification['data'] = {
          'deepLink': deepLink,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        };
      }

      // ✅ Target specific user using TAGS or all users
      if (userId != null && userId.isNotEmpty) {
        // Use filters with firebase_uid tag
        notification['filters'] = [
          {
            'field': 'tag',
            'key': 'firebase_uid',
            'relation': '=',
            'value': userId,
          },
        ];
        DebugLogger.info('📤 Sending to user with tag firebase_uid=$userId');
      } else {
        notification['included_segments'] = ['All'];
        DebugLogger.info('📤 Sending to: All users');
      }

      DebugLogger.info('📤 Title: $title');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $oneSignalRestApiKey',
        },
        body: json.encode(notification),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final recipients = responseBody['recipients'] ?? 0;
        DebugLogger.success(
          '✅ Notification sent successfully. Recipients: $recipients',
        );

        if (recipients == 0 && userId != null) {
          DebugLogger.warning(
            '⚠️ 0 recipients - User may need to restart app on a real device',
          );
        }

        return recipients > 0;
      } else {
        DebugLogger.error('❌ OneSignal API Error: ${response.statusCode}');
        DebugLogger.error('❌ Response: $responseBody');
        return false;
      }
    } catch (e) {
      DebugLogger.error('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Get the current user's Player ID (OneSignal User ID)
  static String? getPlayerId() {
    final subscription = OneSignal.User.pushSubscription;
    return subscription.id;
  }

  /// ✅ Register user with OneSignal using TAGS
  /// Tags are more reliable than external_id for targeting
  static Future<void> setExternalUserId(String firebaseUid) async {
    try {
      // Login to OneSignal with Firebase UID
      await OneSignal.login(firebaseUid);

      // ✅ Add firebase_uid tag for reliable targeting
      await OneSignal.User.addTags({'firebase_uid': firebaseUid});

      DebugLogger.success(
        '✅ OneSignal: User registered with tag firebase_uid=$firebaseUid',
      );

      // Also try to save player_id to Firestore if available
      await Future.delayed(const Duration(milliseconds: 500));
      final playerId = getPlayerId();

      if (playerId != null && playerId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUid)
            .set({
              'oneSignalPlayerId': playerId,
              'oneSignalUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        DebugLogger.success('✅ Player ID saved: $playerId');
      }
    } catch (e) {
      DebugLogger.error('❌ OneSignal registration failed: $e');
    }
  }

  /// Remove external user ID (on logout)
  static Future<void> removeExternalUserId() async {
    try {
      await OneSignal.User.removeTags(['firebase_uid']);
      await OneSignal.logout();
      DebugLogger.info('OneSignal: User logged out');
    } catch (e) {
      DebugLogger.error('❌ OneSignal logout failed: $e');
    }
  }

  /// ✅ Setup notification handlers with deep linking
  static void setupNotificationHandlers({
    Function(OSNotificationWillDisplayEvent)? onForegroundNotification,
    Function(OSNotificationClickEvent)? onNotificationClick,
    required Function(String) onDeepLinkReceived,
  }) {
    // Handle notifications received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      DebugLogger.info(
        '📬 Foreground notification received: ${event.notification.title}',
      );
      if (onForegroundNotification != null) {
        onForegroundNotification(event);
      }
      event.notification.display();
    });

    // Handle notification clicks with deep linking
    OneSignal.Notifications.addClickListener((event) {
      DebugLogger.info('👆 Notification clicked: ${event.notification.title}');
      if (onNotificationClick != null) {
        onNotificationClick(event);
      }

      // ✅ Handle deep link
      final deepLink = event.notification.additionalData?['deepLink'];
      if (deepLink != null) {
        DebugLogger.info('📱 Deep link received: $deepLink');
        onDeepLinkReceived(deepLink.toString());
      }
    });
  }

  /// Add tags to user for segmentation
  static Future<void> addTags(Map<String, String> tags) async {
    OneSignal.User.addTags(tags);
  }

  /// Remove tags from user
  static Future<void> removeTags(List<String> keys) async {
    OneSignal.User.removeTags(keys);
  }
}
