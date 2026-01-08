import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _showHistory = false; // Toggle for showing old notifications

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  /// Marks all unread notifications as read when the screen opens
  Future<void> _markAllAsRead() async {
    if (currentUserId == null) return;
    final batch = FirebaseFirestore.instance.batch();

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('readBy', whereNotIn: [currentUserId])
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final readBy = List<String>.from(data['readBy'] ?? []);
      final targetUserId = data['userId'];

      // Only mark if it belongs to this user
      if (targetUserId == null || targetUserId == currentUserId) {
        if (!readBy.contains(currentUserId)) {
          readBy.add(currentUserId!);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }
    }
    await batch.commit();
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final deepLink = data['deepLink'];
    if (deepLink != null && deepLink.toString().isNotEmpty) {
      await DeepLinkHandler.handleDeepLink(deepLink.toString());
    } else {
      _showNotificationDetails(context, data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        title: AppText(
          title: _showHistory ? 'الأرشيف' : 'الإشعارات',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Toggle Button for History
          IconButton(
            icon: Icon(
              _showHistory ? Icons.notifications_active : Icons.history,
              color: Colors.white,
            ),
            tooltip: _showHistory ? 'عرض الحالية' : 'عرض الأرشيف',
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.fill,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              // Increased limit to ensure we fetch enough data for both views
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: AppText(
                  title: 'خطأ: ${snapshot.error}',
                  color: Colors.white,
                ),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];
            final now = DateTime.now();
            final threeDaysAgo = now.subtract(const Duration(days: 3));

            // Filter Logic
            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // 1. User Check
              final targetUserId = data['userId'];
              if (targetUserId != null && targetUserId != currentUserId) {
                return false;
              }

              // 2. Read Status & Date Check
              final readBy = List<String>.from(data['readBy'] ?? []);
              final isRead = readBy.contains(currentUserId);

              final timestamp = data['createdAt'] as Timestamp?;
              final createdAt = timestamp?.toDate() ?? DateTime.now();

              if (_showHistory) {
                // Show ONLY: Read AND Older than 3 days
                return isRead && createdAt.isBefore(threeDaysAgo);
              } else {
                // Show: Unread OR (Read BUT Newer than 3 days)
                return !isRead || (isRead && createdAt.isAfter(threeDaysAgo));
              }
            }).toList();

            if (filteredDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showHistory
                          ? Icons.history_toggle_off
                          : Icons.notifications_off_outlined,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      title: _showHistory
                          ? 'لا يوجد إشعارات قديمة'
                          : 'لا توجد إشعارات جديدة',
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                final data = doc.data() as Map<String, dynamic>;

                final timestamp = data['createdAt'] as Timestamp?;
                final dateStr = timestamp != null
                    ? _formatTimestamp(timestamp)
                    : 'الآن';

                final imagePath = _getImageForNotification(data);
                final color = _getColorForNotification(data);
                final hasDeepLink =
                    data['deepLink'] != null &&
                    data['deepLink'].toString().isNotEmpty;

                return _buildNotificationCard(
                  imagePath: imagePath,
                  color: color,
                  title: data['title'] ?? 'إشعار',
                  body: data['body'] ?? '',
                  time: dateStr,
                  hasDeepLink: hasDeepLink,
                  onTap: () => _handleNotificationTap(data),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ... (Helper methods remain mostly the same) ...

  Widget _buildNotificationCard({
    required String imagePath,
    required Color color,
    required String title,
    required String body,
    required String time,
    required bool hasDeepLink,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.45),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: hasDeepLink
                      ? AppColors.secondaryTextColor.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        width: 26.w,
                        height: 26.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (hasDeepLink)
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14.sp,
                                color: AppColors.secondaryTextColor,
                              ),
                            Expanded(
                              child: AppText(
                                title: title,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          title: body,
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        AppText(
                          title: time,
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getImageForNotification(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString();
    final body = (data['body'] ?? '').toString();

    if (title.contains('عقد') ||
        body.contains('عقد') ||
        title.contains('باقه') ||
        body.contains('باقه')) {
      return 'assets/icons/contract_agreement.png';
    } else if (title.contains('مقال') || body.contains('مقال')) {
      return 'assets/icons/artcal_no.png';
    } else if (title.contains('دعم') ||
        body.contains('دعم') ||
        body.contains('رفض') ||
        body.contains('قبول') ||
        title.contains('قبول') ||
        title.contains('رفض')) {
      return 'assets/icons/support_no.png';
    } else if (title.contains('خدمة') || body.contains('خدمة')) {
      return 'assets/icons/servises_no.png';
    } else if (title.contains('نقاط') || body.contains('نقاط')) {
      return 'assets/icons/points_no.png';
    } else if (title.contains('تعلم') || body.contains('تعلم')) {
      return 'assets/icons/learn_no.png';
    } else {
      return 'assets/icons/notification.png';
    }
  }

  Color _getColorForNotification(Map<String, dynamic> data) {
    return Colors.white;
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final imagePath = _getImageForNotification(data);
    final color = _getColorForNotification(data);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 18.w,
                  height: 18.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText(
                title: data['title'] ?? 'إشعار',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                title: 'المحتوى:',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              SizedBox(height: 8.h),
              AppText(title: data['body'] ?? '', color: Colors.white70),
              if (data['deepLink'] != null) ...[
                SizedBox(height: 16.h),
                const AppText(
                  title: 'رابط التطبيق:',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                SizedBox(height: 4.h),
                AppText(
                  title: data['deepLink'].toString(),
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (data['deepLink'] != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                DeepLinkHandler.handleDeepLink(data['deepLink'].toString());
              },
              child: const AppText(
                title: 'فتح',
                color: AppColors.secondaryTextColor,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(title: 'إغلاق', color: Colors.white),
          ),
        ],
      ),
    );
  }
}
