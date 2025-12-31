// lib/core/utils/user_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;

  /// Initialize the user manager (call this after login)
  Future<void> init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _fetchUser(user.uid);
    }
  }

  /// Fetch user data from Firestore
  Future<void> _fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      _userData = doc.data();
      _userData!['uid'] = uid;
    }
  }

  /// Refresh user data manually
  Future<void> refresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _fetchUser(uid);
    }
  }

  /// Getters for user info
  String get uid => _userData?['uid'] ?? '';
  String get name => _userData?['name'] ?? 'مستخدم';
  String get email => _userData?['email'] ?? '';
  String get phone => _userData?['phone'] ?? '';
  int get points => _userData?['points'] ?? 0;
  Map<String, dynamic> get allData => _userData ?? {};

  /// Stream for real-time updates
  Stream<Map<String, dynamic>> userStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('users').doc(uid).snapshots().map((snap) {
      _userData = snap.data();
      _userData?['uid'] = uid;
      return _userData ?? {};
    });
  }

  /// Update a field in Firestore and locally
  Future<void> updateField(String key, dynamic value) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({key: value});
      _userData?[key] = value;
    }
  }
}
