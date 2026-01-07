import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ProfileChangesReviewTab extends StatefulWidget {
  const ProfileChangesReviewTab({super.key});

  @override
  State<ProfileChangesReviewTab> createState() =>
      _ProfileChangesReviewTabState();
}

class _ProfileChangesReviewTabState extends State<ProfileChangesReviewTab> {
  final DateFormat df = DateFormat.yMd().add_Hm();
  bool _processing = false;

  // ✅ Labels بالعربي لعرضها في الإشعار والواجهة
  String _getFieldLabel(String field) {
    const labels = {
      'name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'city': 'المدينة',
      'address': 'العنوان',
      'storelink': 'رابط المتجر',
      'isDaadClient': 'عميل ضاد',
      'socialLinks': 'روابط التواصل الاجتماعي',
    };
    return labels[field] ?? field;
  }

  String _formatValue(String field, dynamic value) {
    if (value == null) return 'غير محدد';

    if (field == 'isDaadClient') {
      return value == true ? 'نعم' : 'لا';
    }

    return value.toString().trim().isEmpty
        ? 'غير محدد'
        : value.toString().trim();
  }

  String _truncate(String text, {int max = 800}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  Future<void> _approve(
    String requestId,
    String userId,
    String userName,
    Map<String, dynamic> changes,
  ) async {
    setState(() => _processing = true);

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final requestRef = FirebaseFirestore.instance
          .collection('profile_change_requests')
          .doc(requestId);

      await FirebaseFirestore.instance.runTransaction((trx) async {
        final updateData = Map<String, dynamic>.from(changes);
        updateData['updatedAt'] = FieldValue.serverTimestamp();

        trx.update(userRef, updateData);

        trx.update(requestRef, {
          "status": "approved",
          "approvedAt": FieldValue.serverTimestamp(),
        });
      });

      // ✅ إشعار عربي مع ملخص للتعديلات

      const notifTitle = '✅ تمت الموافقة على تعديل الملف الشخصي';
      final notifBody = _truncate(
        'مرحباً ${userName.isEmpty ? "بك" : userName}،\n'
        'تمت الموافقة على طلب تعديل ملفك الشخصي وتحديث البيانات :\n',
      );

      await NotificationService.sendNotification(
        title: notifTitle,
        body: notifBody,
        userId: userId,
        deepLink: DeepLinkHandler.profileLink(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            title: '✅ الملف الشخصي تمت الموافقة وتحديث البيانات',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject(
    String requestId,
    String userId,
    String userName,
    Map<String, dynamic> changes,
  ) async {
    setState(() => _processing = true);

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('profile_change_requests')
          .doc(requestId);

      await requestRef.update({
        "status": "rejected",
        "reviewedAt": FieldValue.serverTimestamp(),
      });

      // ✅ إشعار عربي مع ملخص للتعديلات

      const notifTitle = '❌ تم رفض طلب تعديل الملف الشخصي';
      final notifBody = _truncate(
        'مرحباً ${userName.isEmpty ? "بك" : userName}،\n'
        'تم رفض طلب تعديل الملف الشخصي.\n'
        '\nيمكنك تعديل البيانات وإعادة إرسال الطلب مرة أخرى.',
      );

      await NotificationService.sendNotification(
        title: notifTitle,
        body: notifBody,
        userId: userId,
        deepLink: DeepLinkHandler.profileLink(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: '❌ تم رفض الطلب'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildChangeItem(String field, dynamic oldValue, dynamic newValue) {
    if (field == 'socialLinks') {
      return _buildSocialLinksChanges(oldValue, newValue);
    }

    String displayOld = _formatValue(field, oldValue);
    String displayNew = _formatValue(field, newValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title: _getFieldLabel(field),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title: 'القديم:',
                        fontSize: 11,
                        color: Colors.red.shade200,
                      ),
                      AppText(
                        title: displayOld,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: Colors.green.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title: 'الجديد:',
                        fontSize: 11,
                        color: Colors.green.shade200,
                      ),
                      AppText(
                        title: displayNew,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksChanges(dynamic oldValue, dynamic newValue) {
    final oldLinks = oldValue as Map<String, dynamic>? ?? {};
    final newLinks = newValue as Map<String, dynamic>? ?? {};

    const socialLabels = {
      'facebook': 'فيسبوك',
      'tiktok': 'تيك توك',
      'snapchat': 'سناب شات',
      'instagram': 'انستجرام',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title: 'روابط التواصل الاجتماعي',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.9),
        ),
        SizedBox(height: 8.h),
        ...socialLabels.entries.map((entry) {
          final platform = entry.key;
          final label = entry.value;
          final oldLink = oldLinks[platform]?.toString() ?? '';
          final newLink = newLinks[platform]?.toString() ?? '';

          if (oldLink == newLink) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title: label,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 4.h),
                  if (oldLink.isNotEmpty)
                    AppText(
                      title: 'القديم: $oldLink',
                      fontSize: 11,
                      color: Colors.red.shade200,
                    ),
                  if (newLink.isNotEmpty)
                    AppText(
                      title: 'الجديد: $newLink',
                      fontSize: 11,
                      color: Colors.green.shade200,
                    ),
                  if (oldLink.isEmpty && newLink.isNotEmpty)
                    AppText(
                      title: '(إضافة جديدة)',
                      fontSize: 11,
                      color: Colors.green.shade300,
                    ),
                  if (oldLink.isNotEmpty && newLink.isEmpty)
                    AppText(
                      title: '(تم الحذف)',
                      fontSize: 11,
                      color: Colors.red.shade300,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('profile_change_requests')
              .where('status', isEqualTo: 'pending')
              // ✅ بدون orderBy لتجنب index/permission flicker
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Card(
                    color: AppColors.secondaryColor.withOpacity(0.25),
                    child: Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 42,
                          ),
                          SizedBox(height: 10.h),
                          const AppText(
                            title: 'حدث خطأ في تحميل الطلبات',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          SizedBox(height: 6.h),
                          AppText(
                            title: '${snap.error}',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final docs = (snap.data?.docs ?? []).toList();

            // ✅ sort locally by requestedAt desc
            docs.sort((a, b) {
              final ta = a.data()['requestedAt'];
              final tb = b.data()['requestedAt'];
              final da = (ta is Timestamp)
                  ? ta.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final db = (tb is Timestamp)
                  ? tb.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });

            if (docs.isEmpty) {
              return const Center(
                child: AppText(title: 'لا توجد طلبات تعديل قيد المراجعة'),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(12.r),
              itemCount: docs.length,
              itemBuilder: (c, i) {
                final d = docs[i];
                final data = d.data();

                final userId = (data['userId'] ?? '').toString();
                final userName = (data['userName'] ?? 'مستخدم').toString();
                final userPhone = (data['userPhone'] ?? 'غير متوفر').toString();
                final changes = (data['changes'] is Map)
                    ? Map<String, dynamic>.from(data['changes'])
                    : <String, dynamic>{};

                final date = (data['requestedAt'] is Timestamp)
                    ? (data['requestedAt'] as Timestamp).toDate()
                    : null;

                if (userId.isEmpty) {
                  return Card(
                    color: AppColors.secondaryColor.withOpacity(0.2),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: const AppText(
                        title:
                            '⚠️ الطلب بدون userId (تحقق من البيانات في Firestore)',
                        color: Colors.orangeAccent,
                      ),
                    ),
                  );
                }

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final currentData =
                        userSnap.data?.data() ?? <String, dynamic>{};

                    return Card(
                      color: AppColors.secondaryColor.withOpacity(0.2),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12.0.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        title: userName,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      AppText(
                                        title: 'الهاتف: $userPhone',
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (date != null) ...[
                              SizedBox(height: 8.h),
                              AppText(
                                title: 'تاريخ الطلب: ${df.format(date)}',
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ],
                            SizedBox(height: 16.h),
                            const Divider(color: Colors.white24),
                            SizedBox(height: 12.h),

                            const AppText(
                              title: 'التعديلات المطلوبة:',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            SizedBox(height: 12.h),

                            ...changes.entries.map((entry) {
                              final field = entry.key;
                              final newValue = entry.value;
                              final oldValue = currentData[field];
                              return _buildChangeItem(
                                field,
                                oldValue,
                                newValue,
                              );
                            }),

                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _processing
                                      ? null
                                      : () => _reject(
                                          d.id,
                                          userId,
                                          userName,
                                          changes,
                                        ),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const AppText(title: 'رفض'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                ElevatedButton.icon(
                                  onPressed: _processing
                                      ? null
                                      : () => _approve(
                                          d.id,
                                          userId,
                                          userName,
                                          changes,
                                        ),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const AppText(title: 'قبول'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        if (_processing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
