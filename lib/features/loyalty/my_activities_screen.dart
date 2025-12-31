// lib/screens/my_activities_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/points_history_dialog.dart';
import 'package:daad_app/features/loyalty/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class MyActivitiesScreen extends StatelessWidget {
  MyActivitiesScreen({Key? key}) : super(key: key);

  final service = LoyaltyService();
  final df = DateFormat.yMd().add_Hm();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: AppText(title: 'تسجيل الدخول مطلوب')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppText(title: 'أنشطتي'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: () {
                // Show points history for the logged-in user
                showPointsHistoryDialog(context, user.uid);
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.myActivitiesStream(user.uid),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: AppText(title:'لا توجد أنشطة بعد'));
          
          return ListView.separated(
            padding: EdgeInsets.all(12.r),
            separatorBuilder: (_, __) => SizedBox(height: 8.h
),
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();

              return Card(
                color: AppColors.secondaryColor.withOpacity(0.2),
                child: ListTile(
                  title: AppText(title:'${data['type']} • ${data['points']} نقطة'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['link'] != null) AppText(title:'رابط: ${data['link']}'),
                      AppText(title:'الحالة: ${data['status'] ?? 'pending'}'),
                      if (date != null) AppText(title:'تاريخ: ${df.format(date)}'),
                    ],
                  ),
                  trailing: data['status'] == 'pending'
                      ? const Icon(Icons.hourglass_top)
                      : (data['status'] == 'approved'
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
