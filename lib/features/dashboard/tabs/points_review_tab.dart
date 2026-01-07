import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/route_utils/url_launcher.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/loyalty/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class PointsReviewTab extends StatefulWidget {
  const PointsReviewTab({super.key});

  @override
  State<PointsReviewTab> createState() => _PointsReviewTabState();
}

class _PointsReviewTabState extends State<PointsReviewTab> {
  final LoyaltyService service = LoyaltyService();
  final DateFormat df = DateFormat.yMd().add_Hm();
  bool _processing = false;

  // Pagination state
  static const int _pageSize = 15;
  final List<DocumentSnapshot> _activities = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _activities.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('points_activity')
          .where('status', isEqualTo: 'pending')
          .orderBy('date', descending: true)
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          _activities.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_lastDocument == null || !_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('points_activity')
          .where('status', isEqualTo: 'pending')
          .orderBy('date', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          _activities.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<Map<String, dynamic>?> _getUser(String uid) async {
    final u = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!u.exists) return null;
    return u.data() as Map<String, dynamic>;
  }

  Future<void> _addHistory(
    String uid,
    int points,
    String type,
    String note,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('points_history')
        .add({
          "points": points,
          "type": type,
          "note": note,
          "date": FieldValue.serverTimestamp(),
        });
  }

  Future<void> _approve(
    String activityId,
    String userId,
    int points,
    String type,
  ) async {
    setState(() => _processing = true);
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final activityRef = FirebaseFirestore.instance
          .collection('points_activity')
          .doc(activityId);

      await FirebaseFirestore.instance.runTransaction((trx) async {
        final userSnap = await trx.get(userRef);
        final current = userSnap.data()?['points'] ?? 0;

        trx.update(userRef, {"points": current + points});
        trx.update(activityRef, {
          "status": "approved",
          "approvedAt": FieldValue.serverTimestamp(),
        });
      });

      // Add history AFTER transaction
      await _addHistory(userId, points, "add", "إضافة نقاط لنشاط: $type");

      // Send notification to user
      await NotificationService.sendNotification(
        title: '✅ تمت الموافقة على طلبك',
        body: 'تمت إضافة $points نقطة إلى رصيدك لنشاط: $type',
        userId: userId,
        deepLink: DeepLinkHandler.rewardsLink(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            title: '✅ تمت الموافقة وإضافة النقاط وإرسال الإشعار',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText(title: 'خطأ: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }

    // Refresh list after approval
    _loadInitialData();
  }

  Future<void> _reject(
    String activityId,
    String userId,
    int points,
    String type,
  ) async {
    setState(() => _processing = true);
    try {
      final activityRef = FirebaseFirestore.instance
          .collection('points_activity')
          .doc(activityId);
      await activityRef.update({
        "status": "rejected",
        "reviewedAt": FieldValue.serverTimestamp(),
      });

      await _addHistory(
        userId,
        0,
        "rejected",
        "تم رفض نشاط: $type بقيمة $points نقطة",
      );

      // Send notification to user
      await NotificationService.sendNotification(
        title: '❌ تم رفض طلبك',
        body: 'تم رفض طلب النقاط لنشاط: $type',
        userId: userId,
        deepLink: DeepLinkHandler.rewardsLink(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            title: '❌ تم الرفض وتسجيله في التاريخ وإرسال الإشعار',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText(title: 'خطأ: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }

    // Refresh list after rejection
    _loadInitialData();
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 300.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300.h,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, size: 48, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: AppText(title: 'إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading && _activities.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _activities.isEmpty
            ? const Center(child: AppText(title: 'لا توجد طلبات قيد المراجعة'))
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(12.r),
                  itemCount: _activities.length + (_hasMore ? 1 : 0),
                  itemBuilder: (c, i) {
                    // Loading indicator at end
                    if (i >= _activities.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    final d = _activities[i];
                    final data = d.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp?)?.toDate();
                    final link = data['link'] as String?;
                    final imageUrl = data['imageUrl'] as String?;
                    final type = data['type'] as String?;
                    final points = (data['points'] as num?)?.toInt() ?? 0;
                    final userId = data['userId'] as String?;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUser(userId!),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const ListTile(
                            title: AppText(title: "جاري جلب المستخدم..."),
                          );
                        }
                        final user = snap.data!;
                        final name = user['name'] ?? 'مستخدم';
                        final phone = user['phone'] ?? 'غير متوفر';
                        final currentPoints = user['points'] ?? 0;

                        return Card(
                          color: AppColors.secondaryColor.withOpacity(0.2),
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: EdgeInsets.all(12.0.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User Info
                                AppText(
                                  title: '$name • $points نقطة',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(height: 8.h),
                                AppText(title: 'الهاتف: $phone', fontSize: 13),
                                AppText(
                                  title: 'رصيد المستخدم الحالي: $currentPoints',
                                  fontSize: 13,
                                ),
                                AppText(
                                  title: 'نوع النشاط: $type',
                                  fontSize: 13,
                                ),
                                if (date != null)
                                  AppText(
                                    title:
                                        'تاريخ: ${DateFormat.yMd().add_Hm().format(date)}',
                                    fontSize: 13,
                                  ),

                                SizedBox(height: 12.h),

                                // Link
                                if (link != null && link.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.link,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                UrlLauncherUtils.openExternalUrl(
                                                  context,
                                                  link,
                                                ),
                                            child: AppText(
                                              title: link,
                                              fontSize: 12,
                                              color: Colors.blue,
                                              textDecoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Image Preview
                                if (imageUrl != null &&
                                    imageUrl.isNotEmpty) ...[
                                  SizedBox(height: 12.h),
                                  GestureDetector(
                                    onTap: () =>
                                        _showImageDialog(context, imageUrl),
                                    child: Container(
                                      height: 150.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2.w,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              imageUrl,
                                              width: double.infinity,
                                              height: 150.h,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                      ),
                                                    );
                                                  },
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.r,
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.zoom_in,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    const AppText(
                                                      title: 'انقر للتكبير',
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                SizedBox(height: 12.h),

                                // Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _processing
                                          ? null
                                          : () => _reject(
                                              d.id,
                                              userId,
                                              points,
                                              type ?? "",
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
                                              points,
                                              type ?? "",
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
                ),
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
