import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentlyViewedService {
  static final RecentlyViewedService _instance = RecentlyViewedService._internal();
  factory RecentlyViewedService() => _instance;
  RecentlyViewedService._internal();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// إضافة عنصر إلى قائمة المشاهدات الأخيرة
  Future<void> addRecentlyViewed({
    required String itemId,
    required String collection,
    required String title,
    String? titleAr,
    String? imageUrl,
    String? body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final recentlyViewedRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('recentlyViewed')
          .doc(itemId);

      await recentlyViewedRef.set({
        'itemId': itemId,
        'collection': collection,
        'title': title,
        'titleAr': titleAr ?? '',
        'imageUrl': imageUrl ?? '',
        'body': body ?? '',
        'viewedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      }, SetOptions(merge: true));

      // حذف العناصر القديمة (الاحتفاظ بآخر 20 عنصر فقط)
      await _cleanOldItems(user.uid);
    } catch (e) {
      print('Error adding recently viewed: $e');
    }
  }

  /// حذف العناصر القديمة (الاحتفاظ بآخر 20)
  Future<void> _cleanOldItems(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('recentlyViewed')
          .orderBy('viewedAt', descending: true)
          .get();

      if (snapshot.docs.length > 20) {
        final toDelete = snapshot.docs.skip(20).toList();
        for (var doc in toDelete) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error cleaning old items: $e');
    }
  }
  /// الحصول على العناصر المشاهدة مؤخراً
  Stream<QuerySnapshot> getRecentlyViewed({int limit = 10}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(
        FirebaseFirestore.instance.collection('empty').snapshots() as QuerySnapshot,
      );
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .orderBy('viewedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// حذف عنصر معين من المشاهدات
  Future<void> removeRecentlyViewed(String itemId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('recentlyViewed')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing recently viewed: $e');
    }
  }

  /// مسح كل المشاهدات الأخيرة
  Future<void> clearAllRecentlyViewed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('recentlyViewed')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing recently viewed: $e');
    }
  }
}