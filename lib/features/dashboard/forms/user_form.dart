import 'dart:ui';

import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

Future<void> showUserForm(BuildContext context, {DocumentSnapshot? doc}) async {
  final isEdit = doc != null;
  final data = doc?.data() as Map<String, dynamic>;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7A4458).withOpacity(0.9),
                  const Color(0xFF5D3344).withOpacity(0.9),
                  const Color(0xFF4A2735).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 28),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AppText(
                          title: data['name'] ?? 'معلومات المستخدم',

                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _buildGlassInfoRow('📧 البريد', data['email'] ?? '-'),
                  _buildGlassInfoRow('📱 الهاتف', data['phone'] ?? '-'),
                  _buildGlassInfoRow('🏷️ الدور', data['role'] ?? 'client'),
                  _buildGlassInfoRow(
                    '⭐ النقاط',
                    data['points']?.toString() ?? '0',
                  ),
                  _buildGlassInfoRow('🆔 ID', doc!.id),
                  _buildGlassInfoRow(
                    '📅 تاريخ التسجيل',
                    _formatTimestamp(data['createdAt']),
                  ),
                  _buildGlassInfoRow(
                    '🕐 آخر ظهور',
                    _formatTimestamp(data['lastSeenAt']),
                  ),
                  SizedBox(height: 20.h),
                  GlassButton(
                    onPressed: () => Navigator.pop(context),
                    child: const AppText(title: 'إغلاق'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildGlassInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5.w,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(title: '$label: ', fontWeight: FontWeight.bold),
              Expanded(child: AppText(title: value)),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }
  return '-';
}
