import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/app_colors/app_colors.dart';
import '../../../core/widgets/app_text.dart';

void showPointsHistoryDialog(BuildContext context, String userId) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.primaryColor,
      title: const AppText(title: 'سجل النقاط'),
      content: SizedBox(
        width: 350.w
,
        height: 400.h
,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('points_history')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: AppText(title: 'لا يوجد تاريخ للنقاط'));

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final h = docs[i].data() as Map<String, dynamic>;
                final points = h['points'] ?? 0;
                final type = h['type'] ?? '';
                final note = h['note'] ?? 'بدون سبب';
                final date = h['date'] != null
                    ? h['date'].toDate().toString().substring(0, 16)
                    : '';

                // تحويل النوع إلى نص واضح
                String typeLabel = '';
                if (type == "add") {
                  typeLabel = "إضافة نقاط";
                } else if (type == "rejected") {
                  typeLabel = "رفض الطلب";
                } else if (type == "redeem") {
                  typeLabel = "خصم نقاط للاستبدال";
                }

                return Card(
                  color: AppColors.secondaryColor.withOpacity(0.2),
                  child: ListTile(
                    title: AppText(title: '$typeLabel: $points نقطة'),
                    subtitle: AppText(title: 'السبب: $note'),
                    
                    trailing: AppText(title: date),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}