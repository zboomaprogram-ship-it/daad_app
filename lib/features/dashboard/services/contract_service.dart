import 'package:cloud_firestore/cloud_firestore.dart';

class ContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add contract to user
  static Future<void> addContractToUser({
    required String userId,
    required String title,
    required String pdfUrl,
    required String uploadedBy,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contracts')
          .add({
        'title': title,
        'pdfUrl': pdfUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'agreedAt': null,
        'isAgreed': false,
        'uploadedBy': uploadedBy,
      });
    } catch (e) {
      print('Error adding contract: $e');
      rethrow;
    }
  }
  /// Mark contract as agreed
  static Future<void> agreeToContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contracts')
          .doc(contractId)
          .update({
        'isAgreed': true,
        'agreedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error agreeing to contract: $e');
      rethrow;
    }
  }

  /// Get user contracts stream
  static Stream<QuerySnapshot> getUserContracts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contracts')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// Delete contract
  static Future<void> deleteContract({
    required String userId,
    required String contractId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contracts')
          .doc(contractId)
          .delete();
    } catch (e) {
      print('Error deleting contract: $e');
      rethrow;
    }
  }

  /// Get contract statistics for user
  static Future<Map<String, int>> getContractStats(String userId) async {
    try {
      final contracts = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contracts')
          .get();

      int total = contracts.docs.length;
      int agreed = contracts.docs.where((doc) => doc['isAgreed'] == true).length;
      int pending = total - agreed;

      return {
        'total': total,
        'agreed': agreed,
        'pending': pending,
      };
    } catch (e) {
      print('Error getting contract stats: $e');
      return {'total': 0, 'agreed': 0, 'pending': 0};
    }
  }
}