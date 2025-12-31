import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/presentation/user_contracts_screen.dart';
import 'package:daad_app/features/dashboard/forms/show_add_contract_dialog.dart';
import 'package:daad_app/features/dashboard/services/contract_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showUserInfoDialog(
  BuildContext context,
  DocumentSnapshot doc, {
  bool isAdmin = true,
  String? currentUserId,
}) async {
  final data = doc.data() as Map<String, dynamic>;
  final contractStats = await ContractService.getContractStats(doc.id);

  final socialLinks = (data['socialLinks'] ?? {}) as  dynamic;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(maxHeight: 600.h),
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
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: AppText(
                          title: (data['name']?.isNotEmpty ?? false)
                              ? (data['name'] ?? 'U')[0].toUpperCase()
                              : 'U',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              title: data['name'] ?? 'مستخدم',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            AppText(
                              title: _getRoleLabel(data['role']),
                              fontSize: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Info section
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlassInfoRow('📧 البريد', data['email'] ?? '-'),
                          _buildGlassInfoRow('📱 الهاتف', data['phone'] ?? '-'),
                          _buildGlassInfoRow(
                            '⭐ النقاط',
                            data['points']?.toString() ?? '0',
                          ),
                          _buildGlassInfoRow(
                            '🏠 العنوان',
                            data['address'] ?? '-',
                          ),
                          _buildGlassInfoRow(
                            '🏙️ المدينة',
                            data['city'] ?? '-',
                          ),

                          // ✅ isDaadClient field
                          _buildGlassInfoRow(
                            '🤝 حالة العميل',
                            (data['isDaadClient'] == true)
                                ? '✅ عميل ضاد'
                                : '❌ ليس عميل ضاد',
                          ),

                          _buildGlassInfoRow('🆔 ID', doc.id),
                          _buildGlassInfoRow(
                            '📅 تاريخ التسجيل',
                            _formatTimestamp(data['createdAt']),
                          ),
                          _buildGlassInfoRow(
                            '🕐 آخر ظهور',
                            _formatTimestamp(data['lastSeenAt']),
                          ),

                          SizedBox(height: 16.h),

                          // Social Links Section
                          if (socialLinks.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 0.5.w,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.link, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      AppText(
                                        title: 'روابط التواصل الاجتماعي',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (socialLinks['facebook'] != null &&
                                          socialLinks['facebook']
                                              .toString()
                                              .isNotEmpty)
                                        _buildSocialLinkRow(
                                          'Facebook',
                                          socialLinks['facebook'],
                                          Icons.facebook,
                                          Colors.blue,
                                        ),
                                      if (socialLinks['tiktok'] != null &&
                                          socialLinks['tiktok']
                                              .toString()
                                              .isNotEmpty)
                                        _buildSocialLinkRow(
                                          'TikTok',
                                          socialLinks['tiktok'],
                                          Icons.music_note,
                                          Colors.pinkAccent,
                                        ),
                                      if (socialLinks['storelink'] != null &&
                                          socialLinks['storelink']
                                              .toString()
                                              .isNotEmpty)
                                        _buildSocialLinkRow(
                                          'Store',
                                          socialLinks['storelink'],
                                          Icons.store,
                                          Colors.greenAccent,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: 16.h),

                          // Contracts section
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.5.w,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8.w),
                                    AppText(
                                      title: 'العقود والاتفاقيات',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        '📋 الإجمالي',
                                        contractStats['total'].toString(),
                                        Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: _buildStatCard(
                                        '✅ موقعة',
                                        contractStats['agreed'].toString(),
                                        Colors.green,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: _buildStatCard(
                                        '⏳ معلقة',
                                        contractStats['pending'].toString(),
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Action buttons
                  Row(
                    children: [
                      if (isAdmin)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF7A4458),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              showAddContractDialog(
                                context,
                                userId: doc.id,
                                userName: data['name'] ?? 'مستخدم',
                                currentAdminId: currentUserId ?? '',
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const AppText(
                              title: 'إضافة عقد',
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      if (isAdmin) SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserContractsScreen(
                                  userId: doc.id,
                                  userName: data['name'] ?? 'مستخدم',
                                  isAdmin: isAdmin,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const AppText(title: 'عرض العقود'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const AppText(title: 'إغلاق'),
                    ),
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
    padding: EdgeInsets.symmetric(vertical: 6),
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

Widget _buildSocialLinkRow(
  String label,
  String url,
  IconData icon,
  Color color,
) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8.w),
          Expanded(
            child: AppText(title: url, fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatCard(String label, String value, Color color) {
  return Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Column(
      children: [
        AppText(
          title: value,
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 4.h),
        AppText(title: label, fontSize: 11, textAlign: TextAlign.center),
      ],
    ),
  );
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }
  return '-';
}

String _getRoleLabel(String? role) {
  switch (role) {
    case 'admin':
      return 'مسؤول 👨‍💼';
    case 'client':
      return 'عميل 👤';
    default:
      return 'غير محدد';
  }
}
