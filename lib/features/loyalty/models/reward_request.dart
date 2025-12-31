import 'package:cloud_firestore/cloud_firestore.dart';

class RewardRequest {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardTitle;
  final int pointsUsed;
  final String status;// 'pending', 'scheduled', 'completed', 'cancelled'
  final DateTime requestedAt;
  final DateTime? scheduledMeetingAt;
  final String? meetingNotes;
  final String? additionalDetails;

  RewardRequest({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardTitle,
    required this.pointsUsed,
    this.status = 'pending',
    required this.requestedAt,
    this.scheduledMeetingAt,
    this.meetingNotes,
    this.additionalDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'pointsUsed': pointsUsed,
      'status': status,
      'requestedAt': requestedAt,
      'scheduledMeetingAt': scheduledMeetingAt,
      'meetingNotes': meetingNotes,
      'additionalDetails': additionalDetails,
    };
  }

  factory RewardRequest.fromMap(String id, Map<String, dynamic> map) {
    return RewardRequest(
      id: id,
      userId: map['userId'] ?? '',
      rewardId: map['rewardId'] ?? '',
      rewardTitle: map['rewardTitle'] ?? '',
      pointsUsed: map['pointsUsed'] ?? 0,
      status: map['status'] ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      scheduledMeetingAt: map['scheduledMeetingAt'] != null
          ? (map['scheduledMeetingAt'] as Timestamp).toDate()
          : null,
      meetingNotes: map['meetingNotes'],
      additionalDetails: map['additionalDetails'],
    );
  }
}