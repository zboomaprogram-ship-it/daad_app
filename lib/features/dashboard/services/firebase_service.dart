import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;
  // static final _auth = FirebaseAuth.instance;

  // Save user to Firestore after signup/login
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

  // Get all users (for Excel export)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}