import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive user data
/// Uses platform keychain (iOS) and keystore (Android) for encryption
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for user info
  static const _keyFirstName = 'secure_first_name';
  static const _keyLastName = 'secure_last_name';
  static const _keyEmail = 'secure_email';
  static const _keyPhone = 'secure_phone';
  static const _keyWhatsAppPhone = 'secure_whatsapp_phone';
  static const _keyAddress = 'secure_address';
  static const _keyCity = 'secure_city';
  static const _keyCountry = 'secure_country';
  static const _keyStreet = 'secure_street';
  static const _keyBuilding = 'secure_building';
  static const _keyFloor = 'secure_floor';
  static const _keyApartment = 'secure_apartment';
  static const _keyIsLoggedIn = 'secure_is_logged_in';

  // ==================== User Info Storage ====================

  /// Save all user info securely
  static Future<void> saveUserInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String whatsAppPhone,
    required String address,
    required String city,
    required String country,
    required String street,
    required String building,
    required String floor,
    required String apartment,
  }) async {
    await Future.wait([
      _storage.write(key: _keyFirstName, value: firstName),
      _storage.write(key: _keyLastName, value: lastName),
      _storage.write(key: _keyEmail, value: email),
      _storage.write(key: _keyPhone, value: phone),
      _storage.write(key: _keyWhatsAppPhone, value: whatsAppPhone),
      _storage.write(key: _keyAddress, value: address),
      _storage.write(key: _keyCity, value: city),
      _storage.write(key: _keyCountry, value: country),
      _storage.write(key: _keyStreet, value: street),
      _storage.write(key: _keyBuilding, value: building),
      _storage.write(key: _keyFloor, value: floor),
      _storage.write(key: _keyApartment, value: apartment),
    ]);
  }

  /// Get all user info
  static Future<Map<String, String>> getUserInfo() async {
    final results = await Future.wait([
      _storage.read(key: _keyFirstName),
      _storage.read(key: _keyLastName),
      _storage.read(key: _keyEmail),
      _storage.read(key: _keyPhone),
      _storage.read(key: _keyWhatsAppPhone),
      _storage.read(key: _keyAddress),
      _storage.read(key: _keyCity),
      _storage.read(key: _keyCountry),
      _storage.read(key: _keyStreet),
      _storage.read(key: _keyBuilding),
      _storage.read(key: _keyFloor),
      _storage.read(key: _keyApartment),
    ]);

    return {
      'first_name': results[0] ?? '',
      'last_name': results[1] ?? '',
      'email': results[2] ?? '',
      'phone': results[3] ?? '',
      'whatAppPhone': results[4] ?? '',
      'address': results[5] ?? '',
      'city': results[6] ?? '',
      'country': results[7] ?? '',
      'street': results[8] ?? '',
      'building': results[9] ?? '',
      'floor': results[10] ?? '',
      'apartment': results[11] ?? '',
    };
  }

  /// Get user first name
  static Future<String?> getUserFirstName() async {
    return await _storage.read(key: _keyFirstName);
  }

  /// Get user last name
  static Future<String?> getUserLastName() async {
    return await _storage.read(key: _keyLastName);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  /// Get user phone
  static Future<String?> getUserPhone() async {
    return await _storage.read(key: _keyPhone);
  }

  // ==================== Login State ====================

  /// Set user logged in state securely
  static Future<void> setUserLoggedIn(bool value) async {
    await _storage.write(key: _keyIsLoggedIn, value: value.toString());
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final value = await _storage.read(key: _keyIsLoggedIn);
    return value == 'true';
  }

  // ==================== Clear Data ====================

  /// Clear all secure user data (on logout)
  static Future<void> clearUserInfo() async {
    await Future.wait([
      _storage.delete(key: _keyFirstName),
      _storage.delete(key: _keyLastName),
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyPhone),
      _storage.delete(key: _keyWhatsAppPhone),
      _storage.delete(key: _keyAddress),
      _storage.delete(key: _keyCity),
      _storage.delete(key: _keyCountry),
      _storage.delete(key: _keyStreet),
      _storage.delete(key: _keyBuilding),
      _storage.delete(key: _keyFloor),
      _storage.delete(key: _keyApartment),
    ]);
  }

  /// Clear login state
  static Future<void> clearLoginState() async {
    await _storage.delete(key: _keyIsLoggedIn);
  }

  /// Clear all secure storage
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
