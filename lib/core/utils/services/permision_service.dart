import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  // Keys for storing permission request state
  static const String _photosAskedKey = 'photos_permission_asked';

  /// ✅ APPLE COMPLIANT: Request photo permission
  /// - Ask ONLY ONCE per install
  /// - NO pressure dialogs after denial
  /// - ONLY show neutral info when user ACTIVELY tries to use feature
  static Future<PermissionResult> requestPhotosPermission() async {
    // ✅ ANDROID 13+: No permissions needed if using Photo Picker
    // We treat it as "granted" so the UI proceeds to open the picker.
    if (Platform.isAndroid) {
      return PermissionResult.granted;
    }

    // iOS Logic
    final prefs = await SharedPreferences.getInstance();
    final hasAskedBefore = prefs.getBool(_photosAskedKey) ?? false;

    Permission permission = Permission.photos;

    PermissionStatus status = await permission.status;

    // ✅ Already granted - allow feature
    if (status.isGranted || status.isLimited) {
      return PermissionResult.granted;
    }

    // ✅ Permanently denied - return status without showing dialog
    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    }

    // ✅ Request permission ONLY if never asked before
    if (!hasAskedBefore) {
      await prefs.setBool(_photosAskedKey, true);
      status = await permission.request();

      if (status.isGranted || status.isLimited) {
        return PermissionResult.granted;
      } else if (status.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else {
        return PermissionResult.denied;
      }
    }

    // ✅ User previously denied - don't ask again
    return PermissionResult.denied;
  }

  /// ✅ Check current permission status without requesting
  static Future<bool> hasPhotosPermission() async {
    // ✅ ANDROID: Always return true to allow UI to proceed to picker
    if (Platform.isAndroid) return true;

    final permission = Permission.photos;
    final status = await permission.status;
    return status.isGranted || status.isLimited;
  }

  /// ✅ NEUTRAL message - only informational, no pressure
  static String getPermissionMessage(PermissionResult result) {
    switch (result) {
      case PermissionResult.denied:
        return 'تم رفض إذن الصور من إعدادات التطبيق. فعّل إذن الصور من إعدادات التطبيق ثم حاول مرة أخرى.';
      case PermissionResult.permanentlyDenied:
        return 'تم رفض إذن الصور من إعدادات التطبيق. فعّل إذن الصور من إعدادات التطبيق ثم حاول مرة أخرى.';
      case PermissionResult.granted:
        return '';
    }
  }

  /// ✅ Reset permission flags (for testing ONLY - remove in production)
  static Future<void> resetPermissionFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photosAskedKey);
  }
}

/// Permission request result
enum PermissionResult { granted, denied, permanentlyDenied }
