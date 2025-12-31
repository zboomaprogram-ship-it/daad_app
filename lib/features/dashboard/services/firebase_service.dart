import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;

  // Save user after login/signup
  static Future<void> saveUserToFirestore(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final exists = (await userDoc.get()).exists;

    if (!exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'مستخدم جديد',
        'phone': user.phoneNumber ?? '',
        'role': 'client',
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update user role
  static Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ➕ Add or subtract points and save history
  static Future<void> updateUserPoints({
    required String userId,
    required int change,
    required String reason,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userData = await userRef.get();
    final currentPoints = userData['points'] ?? 0;
    final newPoints = currentPoints + change;

    // Update points
    await userRef.update({
      'points': newPoints,
    });

    // Add history
    await userRef.collection('points_history').add({
      'change': change,
      'newTotal': newPoints,
      'reason': reason,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
