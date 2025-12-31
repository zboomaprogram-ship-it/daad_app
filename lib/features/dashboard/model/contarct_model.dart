import 'package:cloud_firestore/cloud_firestore.dart';

class Contract {
  final String id;
  final String title;
  final String pdfUrl;
  final DateTime uploadedAt;
  final DateTime? agreedAt;
  final bool isAgreed;
  final String uploadedBy;

  Contract({
    required this.id,
    required this.title,
    required this.pdfUrl,
    required this.uploadedAt,
    this.agreedAt,
    this.isAgreed = false,
    required this.uploadedBy,
  });

  factory Contract.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      title: data['title'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      agreedAt: data['agreedAt'] != null 
          ? (data['agreedAt'] as Timestamp).toDate() 
          : null,
      isAgreed: data['isAgreed'] ?? false,
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'pdfUrl': pdfUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'agreedAt': agreedAt != null ? Timestamp.fromDate(agreedAt!) : null,
      'isAgreed': isAgreed,
      'uploadedBy': uploadedBy,
    };
  }

  Contract copyWith({
    String? id,
    String? title,
    String? pdfUrl,
    DateTime? uploadedAt,
    DateTime? agreedAt,
    bool? isAgreed,
    String? uploadedBy,
  }) {
    return Contract(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      agreedAt: agreedAt ?? this.agreedAt,
      isAgreed: isAgreed ?? this.isAgreed,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }
}