import 'dart:async';
import 'package:daad_app/app.dart';
import 'package:daad_app/core/utils/network_utils/secure_config_service.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/utils/services/debug_logger.dart';
import 'package:daad_app/core/utils/caching_utils/hive_cache_service.dart';
import 'package:daad_app/features/services/remote_config_service.dart';
import 'package:daad_app/lifecycle_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Only initialize Firebase - let other services load asynchronously
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Start app immediately - initialize services in background
  runApp(const LifeCycleWatcher(child: ProviderScope(child: DaadRoot())));
  // ✅ Initialize other services asynchronously (non-blocking)
  _initializeServicesInBackground();
}

/// Initialize services in background without blocking app startup
Future<void> _initializeServicesInBackground() async {
  try {
    // Start all initializations in parallel
    await Future.wait([
      _initializeSecureConfig(),
      _initializeNotifications(),
      _initializeRemoteConfig(),
      _initializeHiveCache(),
    ]);
    DebugLogger.success('All background services initialized');
  } catch (e) {
    DebugLogger.warning('Error initializing background services: $e');
  }
}

Future<void> _initializeSecureConfig() async {
  try {
    await SecureConfigService.initialize();
    DebugLogger.success('SecureConfig initialized');
  } catch (e) {
    DebugLogger.warning('SecureConfig initialization failed: $e');
  }
}

Future<void> _initializeNotifications() async {
  if (kIsWeb) {
    DebugLogger.warning('OneSignal disabled on Web (plugin not supported)');
    return;
  }
  try {
    await NotificationService.initialize();
    // Setup notification handlers with deep linking
    NotificationService.setupNotificationHandlers(
      onForegroundNotification: (event) {
        DebugLogger.info('Notification received in foreground');
      },
      onNotificationClick: (event) {
        DebugLogger.info('Notification clicked');
      },
      onDeepLinkReceived: (deepLink) async {
        DebugLogger.info('Deep link received');
        await Future.delayed(const Duration(milliseconds: 500));
        await DeepLinkHandler.handleDeepLink(deepLink);
      },
    );

    DebugLogger.success('Notifications initialized');
  } catch (e) {
    DebugLogger.warning('Notification initialization failed: $e');
  }
}

Future<void> _initializeRemoteConfig() async {
  try {
    await RemoteConfigService.instance.ensureLoaded();
    DebugLogger.success('RemoteConfig initialized');
  } catch (e) {
    DebugLogger.warning('RemoteConfig initialization failed: $e');
  }
}

Future<void> _initializeHiveCache() async {
  try {
    await HiveCacheService.initialize();
    DebugLogger.success('HiveCache initialized');
  } catch (e) {
    DebugLogger.warning('HiveCache initialization failed: $e');
  }
}

class DaadRoot extends StatelessWidget {
  const DaadRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const DaadApp();
  }
}
