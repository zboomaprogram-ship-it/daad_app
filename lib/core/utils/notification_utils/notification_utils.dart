import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/network_utils/secure_config_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  // 🔐 استخدام المفاتيح من Remote Config
  static String get oneSignalAppId => SecureConfigService.oneSignalAppId;
  static String get oneSignalRestApiKey => SecureConfigService.oneSignalRestApiKey;
  
  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);
  }

  /// ✅ Send notification with deep link support
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? userId,
    String? deepLink, // Format: "service/{serviceId}" or "article/{articleId}"
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'userId': userId,
        'deepLink': deepLink,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });

      final url = Uri.parse('https://onesignal.com/api/v1/notifications');
      
      final Map<String, dynamic> notification = {
        'app_id': oneSignalAppId,
        'headings': {'en': title},
        'contents': {'en': body},
      };

      // ✅ Add deep link data
      if (deepLink != null && deepLink.isNotEmpty) {
        notification['data'] = {
          'deepLink': deepLink,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        };
      }

      if (userId != null && userId.isNotEmpty) {
        notification['include_external_user_ids'] = [userId];
      } else {
        notification['included_segments'] = ['All'];
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $oneSignalRestApiKey',
        },
        body: json.encode(notification),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Get the current user's Player ID (OneSignal User ID)
  static String? getUserId() {
    final subscription = OneSignal.User.pushSubscription;
    return subscription.id;
  }
  
  /// Get the current user's external ID (your app's user ID)
  static String? getExternalUserId() {
    return OneSignal.User.toString();
  }

  /// Set external user ID (your app's user ID)
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }

  /// Remove external user ID (on logout)
  static Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }

  /// ✅ Setup notification handlers with deep linking
  static void setupNotificationHandlers({
    Function(OSNotificationWillDisplayEvent)? onForegroundNotification,
    Function(OSNotificationClickEvent)? onNotificationClick,
    required Function(String) onDeepLinkReceived,
  }) {
    // Handle notifications received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      if (onForegroundNotification != null) {
        onForegroundNotification(event);
      }
      event.notification.display();
    });

    // Handle notification clicks with deep linking
    OneSignal.Notifications.addClickListener((event) {
      if (onNotificationClick != null) {
        onNotificationClick(event);
      }
      
      // ✅ Handle deep link
      final deepLink = event.notification.additionalData?['deepLink'];
      if (deepLink != null) {
        print('📱 Deep link received: $deepLink');
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