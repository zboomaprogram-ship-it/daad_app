import 'package:daad_app/core/utils/services/secure_storage_service.dart';

/// User preferences for authentication state
/// Uses secure encrypted storage to prevent tampering
class UserPreferences {
  /// Set user logged in state (encrypted storage)
  static Future<void> setUserLoggedIn(bool value) async {
    await SecureStorageService.setUserLoggedIn(value);
  }

  /// Check if user is logged in (from encrypted storage)
  static Future<bool> isUserLoggedIn() async {
    return await SecureStorageService.isUserLoggedIn();
  }

  /// Clear login state on logout
  static Future<void> clearLoginState() async {
    await SecureStorageService.clearLoginState();
  }
}
