import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/features/loyalty/models/activity_type.dart';

class PointsSubmission {
  final String id;
  final String userId;
  final ActivityType activityType;
  final int count;
  final List<String> links;
  final int totalPoints;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  PointsSubmission({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.count,
    required this.links,
    required this.totalPoints,
    this.status = 'pending',
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'activityType': activityType.name,
      'count': count,
      'links': links,
      'totalPoints': totalPoints,
      'status': status,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'reviewNote': reviewNote,
    };
  }

  factory PointsSubmission.fromMap(String id, Map<String, dynamic> map) {
    return PointsSubmission(
      id: id,
      userId: map['userId'] ?? '',
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == map['activityType'],
        orElse: () => ActivityType.comment,
      ),
      count: map['count'] ?? 0,
      links: List<String>.from(map['links'] ?? []),
      totalPoints: map['totalPoints'] ?? 0,
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewNote: map['reviewNote'],
    );
  }
}