import 'package:firebase_remote_config/firebase_remote_config.dart';

/// خدمة آمنة لإدارة المفاتيح السرية عبر Firebase Remote Config
class SecureConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  
  static bool _initialized = false;

  /// تهيئة Remote Config مع القيم الافتراضية
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // إعدادات Remote Config مع timeout أقصر
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10), // Reduced from 30
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // القيم الافتراضية
      await _remoteConfig.setDefaults({
        'gemini_api_key': '',
        'wordpress_url': '',
        'wordpress_username': '',
        'wordpress_app_password': '',
        'filebird_api_key': '',
        'onesignal_app_id': '',
        'onesignal_rest_api_key': '',
        'chat_model': '',
        'llama_api_key': '',

      });

      // جلب القيم من Firebase مع timeout
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print('⚠️ Remote Config fetch timeout - using defaults');
          return false;
        },
      );
      
      _initialized = true;
      print('✅ Remote Config initialized successfully');
    } catch (e) {
      print('⚠️ Remote Config initialization error: $e - using defaults');
      _initialized = true; // Mark as initialized to use defaults
    }
  }

  /// الحصول على مفتاح Gemini API
  static String get geminiApiKey {
    if (!_initialized) {
      print('⚠️ SecureConfig not initialized - returning empty string');
      return '';
    }
    return _remoteConfig.getString('gemini_api_key');
  }
  /// الحصول على مفتاح  llamaApiKey
  static String get llamaApiKey {
    if (!_initialized) {
      print('⚠️ SecureConfig not initialized - returning empty string');
      return '';
    }
    return _remoteConfig.getString('llama_api_key');
  }
  /// الحصول على نموذج الدردشة
  static String get chatModel {
    if (!_initialized) {
      print('⚠️ SecureConfig not initialized - returning empty string');
      return '';
    }
    return _remoteConfig.getString('chat_model');
  }

  /// الحصول على رابط WordPress
  static String get wordPressUrl {
    if (!_initialized) return '';
    return _remoteConfig.getString('wordpress_url');
  }

  /// الحصول على اسم مستخدم WordPress
  static String get wordPressUsername {
    if (!_initialized) return '';
    return _remoteConfig.getString('wordpress_username');
  }

  /// الحصول على كلمة مرور تطبيق WordPress
  static String get wordPressAppPassword {
    if (!_initialized) return '';
    return _remoteConfig.getString('wordpress_app_password');
  }

  /// الحصول على مفتاح FileBird API
  static String get fileBirdApiKey {
    if (!_initialized) return '';
    return _remoteConfig.getString('filebird_api_key');
  }

  /// الحصول على OneSignal App ID
  static String get oneSignalAppId {
    if (!_initialized) return '';
    return _remoteConfig.getString('onesignal_app_id');
  }

  /// الحصول على OneSignal REST API Key
  static String get oneSignalRestApiKey {
    if (!_initialized) return '';
    return _remoteConfig.getString('onesignal_rest_api_key');
  }

  /// تحديث القيم يدوياً
  static Future<void> forceRefresh() async {
    try {
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 8),
      );
      print('✅ Remote Config refreshed');
    } catch (e) {
      print('⚠️ Error refreshing Remote Config: $e');
    }
  }

  /// Check if initialized
  static bool get isInitialized => _initialized;

  /// الحصول على جميع المفاتيح (للتحقق من الاتصال فقط)
  static Map<String, String> getAllKeys() {
    if (!_initialized) {
      return {'status': '❌ Not initialized'};
    }
    
    return {
      'gemini_api_key': geminiApiKey.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'wordpress_url': wordPressUrl.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'wordpress_username': wordPressUsername.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'wordpress_app_password': wordPressAppPassword.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'filebird_api_key': fileBirdApiKey.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'onesignal_app_id': oneSignalAppId.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'onesignal_rest_api_key': oneSignalRestApiKey.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'chat_model': chatModel.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
      'llama_api_key': llamaApiKey.isNotEmpty ? '✅ موجود' : '❌ غير موجود',
    };
  }
}