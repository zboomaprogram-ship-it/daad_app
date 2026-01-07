import 'package:hive_flutter/hive_flutter.dart';
import 'package:daad_app/core/utils/services/debug_logger.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Hive-based caching service for Firestore data
/// Reduces Firebase reads by caching frequently accessed data
class HiveCacheService {
  static const String _usersCacheBox = 'users_cache';
  static const String _rewardsCacheBox = 'rewards_cache';
  static const String _activitiesCacheBox = 'activities_cache';
  static const String _metadataBox = 'cache_metadata';

  static const Duration _defaultTTL = Duration(minutes: 5);

  static bool _isInitialized = false;

  /// Initialize Hive and open cache boxes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Open all cache boxes - using String for JSON storage
      await Future.wait([
        Hive.openBox<String>(_usersCacheBox),
        Hive.openBox<String>(_rewardsCacheBox),
        Hive.openBox<String>(_activitiesCacheBox),
        Hive.openBox<String>(_metadataBox),
      ]);

      _isInitialized = true;
      DebugLogger.success('HiveCacheService initialized');
    } catch (e) {
      DebugLogger.error('Failed to initialize HiveCacheService', e);
    }
  }

  // ============ USER CACHE ============

  /// Cache user data with TTL
  static Future<void> cacheUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final box = Hive.box<String>(_usersCacheBox);
      final jsonSafe = _toJsonSafe(userData);
      await box.put(userId, json.encode(jsonSafe));
      await _setTimestamp('user_$userId');
    } catch (e) {
      DebugLogger.error('Failed to cache user $userId', e);
    }
  }

  /// Get cached user data (returns null if expired or not found)
  static Map<String, dynamic>? getCachedUser(String userId, {Duration? ttl}) {
    try {
      if (!_isValid('user_$userId', ttl ?? _defaultTTL)) {
        return null;
      }

      final box = Hive.box<String>(_usersCacheBox);
      final data = box.get(userId);
      if (data == null) return null;
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      DebugLogger.error('Failed to get cached user $userId', e);
      return null;
    }
  }

  /// Cache all users (for dashboard)
  static Future<void> cacheAllUsers(List<Map<String, dynamic>> users) async {
    try {
      final box = Hive.box<String>(_usersCacheBox);
      await box.clear();

      for (final user in users) {
        final id = user['id'] ?? user['uid'];
        if (id != null) {
          final jsonSafe = _toJsonSafe(user);
          await box.put(id, json.encode(jsonSafe));
        }
      }

      await _setTimestamp('all_users');
      DebugLogger.info('Cached ${users.length} users');
    } catch (e) {
      DebugLogger.error('Failed to cache all users', e);
    }
  }

  /// Get all cached users
  static List<Map<String, dynamic>>? getAllCachedUsers({Duration? ttl}) {
    try {
      if (!_isValid('all_users', ttl ?? _defaultTTL)) {
        return null;
      }

      final box = Hive.box<String>(_usersCacheBox);
      return box.values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      DebugLogger.error('Failed to get cached users', e);
      return null;
    }
  }

  // ============ REWARDS CACHE ============

  /// Cache rewards list
  static Future<void> cacheRewards(List<Map<String, dynamic>> rewards) async {
    try {
      final box = Hive.box<String>(_rewardsCacheBox);
      await box.clear();

      for (int i = 0; i < rewards.length; i++) {
        final jsonSafe = _toJsonSafe(rewards[i]);
        await box.put('reward_$i', json.encode(jsonSafe));
      }

      await _setTimestamp('rewards');
      DebugLogger.info('Cached ${rewards.length} rewards');
    } catch (e) {
      DebugLogger.error('Failed to cache rewards', e);
    }
  }

  /// Get cached rewards
  static List<Map<String, dynamic>>? getCachedRewards({Duration? ttl}) {
    try {
      if (!_isValid('rewards', ttl ?? _defaultTTL)) {
        return null;
      }

      final box = Hive.box<String>(_rewardsCacheBox);
      return box.values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      DebugLogger.error('Failed to get cached rewards', e);
      return null;
    }
  }

  // ============ ACTIVITIES CACHE ============

  /// Cache activities configuration
  static Future<void> cacheActivities(
    Map<String, Map<String, dynamic>> activities,
  ) async {
    try {
      final box = Hive.box<String>(_activitiesCacheBox);
      await box.clear();

      for (final entry in activities.entries) {
        final jsonSafe = _toJsonSafe(entry.value);
        await box.put(entry.key, json.encode(jsonSafe));
      }

      await _setTimestamp('activities');
      DebugLogger.info('Cached ${activities.length} activities');
    } catch (e) {
      DebugLogger.error('Failed to cache activities', e);
    }
  }

  /// Get cached activities
  static Map<String, Map<String, dynamic>>? getCachedActivities({
    Duration? ttl,
  }) {
    try {
      if (!_isValid('activities', ttl ?? _defaultTTL)) {
        return null;
      }

      final box = Hive.box<String>(_activitiesCacheBox);
      final result = <String, Map<String, dynamic>>{};

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          result[key.toString()] = json.decode(data) as Map<String, dynamic>;
        }
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      DebugLogger.error('Failed to get cached activities', e);
      return null;
    }
  }

  // ============ CACHE MANAGEMENT ============

  /// Clear all caches (on logout)
  static Future<void> clearAll() async {
    try {
      await Hive.box<String>(_usersCacheBox).clear();
      await Hive.box<String>(_rewardsCacheBox).clear();
      await Hive.box<String>(_activitiesCacheBox).clear();
      await Hive.box<String>(_metadataBox).clear();
      DebugLogger.info('All caches cleared');
    } catch (e) {
      DebugLogger.error('Failed to clear caches', e);
    }
  }

  /// Invalidate specific cache
  static Future<void> invalidate(String key) async {
    try {
      final box = Hive.box<String>(_metadataBox);
      await box.delete('ts_$key');
    } catch (e) {
      DebugLogger.error('Failed to invalidate cache $key', e);
    }
  }

  /// Invalidate user-related caches
  static Future<void> invalidateUserCache() async {
    await invalidate('all_users');
    await Hive.box<String>(_usersCacheBox).clear();
  }

  // ============ PRIVATE HELPERS ============

  static Future<void> _setTimestamp(String key) async {
    final box = Hive.box<String>(_metadataBox);
    await box.put('ts_$key', DateTime.now().toIso8601String());
  }

  static bool _isValid(String key, Duration ttl) {
    try {
      final box = Hive.box<String>(_metadataBox);
      final timestamp = box.get('ts_$key');

      if (timestamp == null) return false;

      final cachedAt = DateTime.parse(timestamp);
      return DateTime.now().difference(cachedAt) < ttl;
    } catch (e) {
      return false;
    }
  }

  /// Convert Firestore data to JSON-safe format
  /// Handles Timestamp -> ISO string conversion
  static Map<String, dynamic> _toJsonSafe(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is Map) {
        result[key] = _toJsonSafe(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = value.map((e) {
          if (e is Map) return _toJsonSafe(Map<String, dynamic>.from(e));
          if (e is Timestamp) return e.toDate().toIso8601String();
          return e;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
