import 'package:cloud_firestore/cloud_firestore.dart';

class PackageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a package to a user
  static Future<void> addPackageToUser({
    required String userId,
    required String title,
    required String pdfUrl,
    required String uploadedBy,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final packageData = {
        'title': title,
        'description': description ?? '',
        'pdfUrl': pdfUrl,
        'uploadedBy': uploadedBy,
        'uploadedAt': FieldValue.serverTimestamp(),
        'startDate': startDate ?? DateTime.now(),
        'endDate': endDate,
        'isActive': true,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('packages')
          .add(packageData);
    } catch (e) {
      throw Exception('فشل في إضافة الباقة: $e');
    }
  }

  /// Get user's packages
  static Stream<QuerySnapshot> getUserPackages(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('packages')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// Delete a package
  static Future<void> deletePackage({
    required String userId,
    required String packageId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('packages')
          .doc(packageId)
          .delete();
    } catch (e) {
      throw Exception('فشل في حذف الباقة: $e');
    }
  }

  /// Update package status
  static Future<void> updatePackageStatus({
    required String userId,
    required String packageId,
    required bool isActive,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('packages')
          .doc(packageId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('فشل في تحديث حالة الباقة: $e');
    }
  }
}