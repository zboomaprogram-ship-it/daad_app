import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daad_app/core/utils/services/secure_storage_service.dart';

class CachingUtils {
  static late SharedPreferences _prefs;
  static const String cartKey = 'cart_items';
  static const String favKey = 'favorite_products';
  static const _imageKey = 'user_profile_image';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cart caching
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final cartJson = _prefs.getStringList(cartKey) ?? [];

    return cartJson.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> saveCartItems(
    List<Map<String, dynamic>> cartItems,
  ) async {
    final cartJson = cartItems.map((e) => json.encode(e)).toList();
    await _prefs.setStringList(cartKey, cartJson);
  }

  static Future<void> clearCart() async {
    await _prefs.remove(cartKey);
  }

  // fav caching
  static Future<List<Map<String, dynamic>>> getFavoriteItems() async {
    final favJson = _prefs.getStringList(favKey) ?? [];
    return favJson.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> saveFavoriteItems(
    List<Map<String, dynamic>> favItems,
  ) async {
    final favJson = favItems.map((e) => json.encode(e)).toList();
    await _prefs.setStringList(favKey, favJson);
  }

  static Future<void> clearFavorites() async {
    await _prefs.remove(favKey);
  }

  // user caching - NOW USES SECURE STORAGE FOR PII
  /// Save user info to ENCRYPTED secure storage
  static Future<void> saveUserInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String whatAppPhone,
    required String city,
    required String country,
    required String street,
    required String building,
    required String floor,
    required String apartment,
  }) async {
    // Use SecureStorageService for PII (encrypted)
    await SecureStorageService.saveUserInfo(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      whatsAppPhone: whatAppPhone,
      address: address,
      city: city,
      country: country,
      street: street,
      building: building,
      floor: floor,
      apartment: apartment,
    );
  }

  /// Get user info from ENCRYPTED secure storage
  static Future<Map<String, String>> getUserInfo() async {
    return await SecureStorageService.getUserInfo();
  }

  /// Get first name from secure storage
  static Future<String?> getUserFirstName() async {
    return await SecureStorageService.getUserFirstName();
  }

  /// Get last name from secure storage
  static Future<String?> getUserSecondName() async {
    return await SecureStorageService.getUserLastName();
  }

  /// Get email from secure storage
  static Future<String?> getUserEmail() async {
    return await SecureStorageService.getUserEmail();
  }

  /// Clear all secure user info on logout
  static Future<void> clearUserInfo() async {
    await SecureStorageService.clearUserInfo();
  }

  static Future<void> saveImageToLocalStorage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/profile.jpg';
    final savedImage = await imageFile.copy(path);

    await _prefs.setString(_imageKey, savedImage.path);
  }

  static Future<String?> getSavedImagePath() async {
    return _prefs.getString(_imageKey);
  }

  // order cach
  static const String _orderHistoryKey = 'order_history';

  static Future<void> saveOrder(Map<String, dynamic> order) async {
    final List<String> orders = _prefs.getStringList(_orderHistoryKey) ?? [];
    orders.add(jsonEncode(order));
    await _prefs.setStringList(_orderHistoryKey, orders);
  }

  static Future<List<Map<String, dynamic>>> getOrderHistory() async {
    final List<String> orders = _prefs.getStringList(_orderHistoryKey) ?? [];
    return orders
        .map((orderStr) => jsonDecode(orderStr))
        .toList()
        .cast<Map<String, dynamic>>();
  }

  // notifecation
  // notifecation prounduct
  static Future<int?> getLatestProductId() async {
    return _prefs.getInt('latest_product_id');
  }

  static Future<void> saveLatestProductId(int id) async {
    await _prefs.setInt('latest_product_id', id);
  }

  static Future<List<int>> getNotifiedLowStockProductIds() async {
    return _prefs
            .getStringList('notified_stock_ids')
            ?.map(int.parse)
            .toList() ??
        [];
  }

  static Future<List<int>> getBackInStockProductIds() async {
    return _prefs.getStringList('back_in_stock_ids')?.map(int.parse).toList() ??
        [];
  }

  static Future<void> addBackInStockProductId(int id) async {
    final current = await getBackInStockProductIds();
    if (!current.contains(id)) {
      current.add(id);
      await _prefs.setStringList(
        'back_in_stock_ids',
        current.map((e) => e.toString()).toList(),
      );
    }
  }

  static Future<void> addNotifiedProductId(int id) async {
    final current = await getNotifiedLowStockProductIds();
    if (!current.contains(id)) {
      current.add(id);
      await _prefs.setStringList(
        'notified_stock_ids',
        current.map((e) => e.toString()).toList(),
      );
    }
  }

  static Future<DateTime?> getLastProductCheckAttemptTime() async {
    final dateStr = _prefs.getString('last_product_check_attempt_time');
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  static Future<void> cleargetLastProductCheckTime() async {
    await _prefs.remove('last_product_check_time');
  }

  static Future<void> saveLastProductCheckAttemptTime(DateTime time) async {
    await _prefs.setString(
      'last_product_check_attempt_time',
      time.toIso8601String(),
    );
  }

  static Future<void> clearsaveLastProductCheckTime() async {
    await _prefs.remove('last_product_check_time');
  }

  static Future<DateTime?> getLastSaleStockCheckTime() async {
    final dateStr = _prefs.getString('last_sale_stock_check_time');
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  static Future<void> saveLastSaleStockCheckTime(DateTime time) async {
    await _prefs.setString(
      'last_sale_stock_check_time',
      time.toIso8601String(),
    );
  }

  // notifecation fav
  static Future<List<int>> getNotifiedFavorites() async {
    return _prefs
            .getStringList('notified_favorites')
            ?.map(int.parse)
            .toList() ??
        [];
  }

  static Future<void> saveNotifiedFavorites(List<int> ids) async {
    await _prefs.setStringList(
      'notified_favorites',
      ids.map((e) => e.toString()).toList(),
    );
  }

  static Future<Map<String, double>> getLastFavoritePrices() async {
    final raw = _prefs.getString('last_fav_prices');
    if (raw == null) return {};
    final decoded = Map<String, dynamic>.from(json.decode(raw));
    return decoded.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  static Future<void> saveLastFavoritePrices(Map<String, double> prices) async {
    await _prefs.setString('last_fav_prices', json.encode(prices));
  }
}
