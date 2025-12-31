import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointsService {
  static final _db = FirebaseFirestore.instance;

  static Future<int> getUserPoints() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final snap = await _db.collection('users').doc(uid).get();
    return (snap.data()?['points'] ?? 0) as int;
  }

  static Future<void> addPoints(int amount, {String reason = 'activity'}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final curr = (doc.data()?['points'] ?? 0) as int;
      tx.set(ref, {'points': curr + amount}, SetOptions(merge: true));
      final hist = ref.collection('points_history').doc();
      tx.set(hist, {'delta': amount, 'reason': reason, 'ts': FieldValue.serverTimestamp()});
    });
  }

  static Future<bool> redeemPoints(int amount, {String reason = 'redeem'}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final ref = _db.collection('users').doc(uid);
    return _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final curr = (doc.data()?['points'] ?? 0) as int;
      if (curr < amount) return false;
      tx.set(ref, {'points': curr - amount}, SetOptions(merge: true));
      final hist = ref.collection('points_history').doc();
      tx.set(hist, {'delta': -amount, 'reason': reason, 'ts': FieldValue.serverTimestamp()});
      return true;
    });
  }
}
