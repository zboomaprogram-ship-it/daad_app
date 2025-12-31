// lib/services/loyalty_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoyaltyService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get uid => _auth.currentUser!.uid;

  /// Get user points
  static Future<int> getUserPoints() async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['points'] ?? 0;
  }

  /// Update user points
  static Future<void> updateUserPoints(int newPoints) async {
    await _firestore.collection('users').doc(uid).update({'points': newPoints});
  }

  /// Get rewards list
  static Stream<QuerySnapshot> getRewards() {
    return _firestore.collection('rewards').snapshots();
  }

  /// Redeem reward
  static Future<String> redeemReward(String rewardId, int cost) async {
    int points = await getUserPoints();

    if (points < cost) return "Not enough points";

    await _firestore.collection('users').doc(uid).update({
      'points': points - cost,
    });

    /// Save redemption history
    await _firestore.collection('users').doc(uid).collection('redemptions').add({
      'rewardId': rewardId,
      'cost': cost,
      'date': DateTime.now(),
    });

    return "Reward redeemed successfully 🎉";
  }

  static const Map<String, int> pointsMap = {
    'comment': 5,
    'like': 5,
    'shareStory': 10,
    'postAboutUs': 30,
    'ugcVideo': 50,
    'referral': 100,
    'review': 20,
  };

  // Submit activity with optional image
  Future<void> submitActivity({
    required String type,
    required String link,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final points = pointsMap[type] ?? 0;

    Map<String, dynamic> activityData = {
      'userId': user.uid,
      'type': type,
      'link': link,
      'points': points,
      'date': FieldValue.serverTimestamp(),
      'status': 'pending',
    };
    if (imageUrl != null && imageUrl.isNotEmpty) {
      activityData['imageUrl'] = imageUrl;
    }

    await _db.collection('points_activity').add(activityData);
  }

  // Approve activity
  Future<void> approveActivity({required String activityId}) async {
    final actRef = _db.collection('points_activity').doc(activityId);
    final actSnap = await actRef.get();
    if (!actSnap.exists) throw Exception("Activity not found");

    final data = actSnap.data()!;
    final userId = data['userId'];
    final points = (data['points'] as int?) ?? 0;

    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((trx) async {
      final userSnap = await trx.get(userRef);
      final currentPoints = userSnap['points'] ?? 0;
      final newTotal = currentPoints + points;

      // 1️⃣ Add points to user
      trx.update(userRef, {"points": newTotal, "updatedAt": FieldValue.serverTimestamp()});

      // 2️⃣ Add points history
      trx.set(
        userRef.collection('points_history').doc(),
        {
          "change": points,
          "reason": "تمت الموافقة على نشاط $activityId",
          "date": FieldValue.serverTimestamp(),
          "newTotal": newTotal,
        },
      );

      // 3️⃣ Mark activity approved
      trx.update(actRef, {
        "status": "approved",
        "approvedAt": FieldValue.serverTimestamp(),
      });
    });
  }

  // Increment user points directly
  Future<void> incrementUserPointsDirectly({
    required String userId,
    required int points,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    await userRef.set({
      'points': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Reject activity
  Future<void> rejectActivity({required String activityId}) async {
    final actRef = _db.collection('points_activity').doc(activityId);
    final actSnap = await actRef.get();
    if (!actSnap.exists) throw Exception("Activity not found");

    final data = actSnap.data()!;
    final userId = data['userId'];
    final points = (data['points'] as int?) ?? 0;

    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((trx) async {
      // 1️⃣ Mark activity rejected
      trx.update(actRef, {
        "status": "rejected",
        "reviewedAt": FieldValue.serverTimestamp(),
      });

      // 2️⃣ Add history note (no points added)
      trx.set(
        userRef.collection('points_history').doc(),
        {
          "change": 0,
          "reason": "تم رفض طلب كسب $points نقطة",
          "date": FieldValue.serverTimestamp(),
          "newTotal": (await trx.get(userRef))['points'] ?? 0,
        },
      );
    });
  }

  // Streams & helpers
  Stream<QuerySnapshot> pendingActivitiesStream() {
    return _db
        .collection('points_activity')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> myActivitiesStream(String uid) {
    return _db
        .collection('points_activity')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Stream<DocumentSnapshot> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Compute availability percentage
  static int availabilityPercent(int userPoints, int required) {
    if (required <= 0) return 0;
    final percent = (userPoints / required * 100).clamp(0, 100);
    return percent.toInt();
  }
}