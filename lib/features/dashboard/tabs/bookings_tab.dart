import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class MeetingRequestsTab extends StatefulWidget {
  const MeetingRequestsTab({super.key});

  @override
  State<MeetingRequestsTab> createState() => _MeetingRequestsTabState();
}

class _MeetingRequestsTabState extends State<MeetingRequestsTab> {
  static const int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final List<DocumentSnapshot> _bookings = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
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
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('type', isEqualTo: 'rewards_discussion')
        // .orderBy('datetime', descending: true)
        .limit(_pageSize)
        .get();

    if (mounted) {
      setState(() {
        _bookings.clear();
        _bookings.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_lastDocument == null || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('type', isEqualTo: 'rewards_discussion')
          .orderBy('datetime', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          _bookings.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = snap.data() ?? {};
    return {
      "name": data['name'] ?? "مستخدم غير معروف",
      "phone": data['phone'] ?? "بدون رقم",
      "email": data['email'] ?? "بدون بريد",
      "points": data['points'] ?? 0,
    };
  }

  Future<void> _approve(
    String bookingId,
    String userId,
    String userName,
    DateTime meetingDate,
  ) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw Exception("الطلب غير موجود");
    }

    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    final currentStatus = bookingData['status'];

    if (currentStatus == 'approved') {
      throw Exception("هذا الطلب تمت الموافقة عليه بالفعل");
    }

    await bookingRef.update({
      "status": "approved",
      "approvedAt": FieldValue.serverTimestamp(),
    });

    // Format the date
    final dateFormatter = DateFormat('dd/MM/yyyy', 'ar');
    final timeFormatter = DateFormat('hh:mm a', 'ar');
    final formattedDate = dateFormatter.format(meetingDate);
    final formattedTime = timeFormatter.format(meetingDate);

    // Send notification to user
    await NotificationService.sendNotification(
      title: '✅ تم تأكيد موعد الاجتماع',
      body:
          'تم تأكيد اجتماعك لمناقشة تفاصيل الخدمة المختارة بتاريخ $formattedDate الساعة $formattedTime',
      userId: userId,
      deepLink: DeepLinkHandler.rewardsLink(),
    );

    await _loadInitialData();
  }

  Future<void> _reject(String bookingId, String userId, String userName) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId);
    final bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw Exception("الطلب غير موجود");
    }

    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    final currentStatus = bookingData['status'];

    if (currentStatus == 'rejected') {
      throw Exception("هذا الطلب تم رفضه بالفعل");
    }

    await bookingRef.update({
      "status": "rejected",
      "rejectedAt": FieldValue.serverTimestamp(),
    });

    // Send notification to user
    await NotificationService.sendNotification(
      title: '❌ تم رفض طلب الاجتماع',
      body: 'نعتذر، تم رفض طلب الاجتماع الخاص بك. يمكنك طلب موعد آخر.',
      userId: userId,
      deepLink: DeepLinkHandler.rewardsLink(),
    );

    await _loadInitialData();
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "غير محدد";
    final date = timestamp.toDate();
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    return '${dateFormatter.format(date)} - ${timeFormatter.format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_bookings.isEmpty && !_isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0.r),
          child: const AppText(
            title: "لا يوجد طلبات اجتماعات حالياً",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(12.r),
        itemCount: _bookings.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _bookings.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0.r),
                child: const CircularProgressIndicator(),
              ),
            );
          }

          final booking = _bookings[index];
          final data = booking.data() as Map<String, dynamic>;
          final uid = data['userId'] ?? '';
          final status = data['status'] ?? 'pending';
          final datetime = data['datetime'] as Timestamp?;
          final notes = data['notes'] ?? 'لا توجد ملاحظات';
          final createdAt = data['createdAt'] as Timestamp?;

          return Card(
            color: AppColors.secondaryColor.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 12),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(uid),
              builder: (context, userSnap) {
                final user = userSnap.data ?? {};
                final name = user['name'] ?? 'جاري التحميل...';
                final phone = user['phone'] ?? '';
                final email = user['email'] ?? '';
                final currentPoints = user['points'] ?? 0;

                Color statusColor = status == "approved"
                    ? Colors.green
                    : status == "rejected"
                    ? Colors.red
                    : Colors.orange;

                String statusText = status == "approved"
                    ? "✅ مؤكد"
                    : status == "rejected"
                    ? "❌ مرفوض"
                    : "⏳ قيد الانتظار";

                return ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: EdgeInsets.all(16.r),
                  leading: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      status == "approved"
                          ? Icons.check_circle
                          : status == "rejected"
                          ? Icons.cancel
                          : Icons.schedule,
                      color: statusColor,
                    ),
                  ),
                  title: AppText(
                    title: name,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.h),
                      AppText(
                        title: '📅 ${_formatDateTime(datetime)}',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: statusColor, width: 1.w),
                        ),
                        child: AppText(
                          title: statusText,
                          color: statusColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: status == "pending"
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              tooltip: "قبول",
                              onPressed: () async {
                                try {
                                  final meetingDate =
                                      datetime?.toDate() ?? DateTime.now();
                                  await _approve(
                                    booking.id,
                                    uid,
                                    name,
                                    meetingDate,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: AppText(
                                          title:
                                              "✅ تم تأكيد الاجتماع وإرسال الإشعار",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: AppText(
                                          title: "❌ خطأ: ${e.toString()}",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: "رفض",
                              onPressed: () async {
                                try {
                                  await _reject(booking.id, uid, name);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: AppText(
                                          title:
                                              "❌ تم رفض الطلب وإرسال الإشعار",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: AppText(
                                          title: "❌ خطأ: ${e.toString()}",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        )
                      : null,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('👤 الاسم:', name),
                          Divider(height: 20.h, color: Colors.white24),
                          _buildInfoRow('📞 الهاتف:', phone),
                          Divider(height: 20.h, color: Colors.white24),
                          _buildInfoRow('📧 البريد:', email),
                          Divider(height: 20.h, color: Colors.white24),
                          _buildInfoRow(
                            '⭐ النقاط الحالية:',
                            '$currentPoints نقطة',
                          ),
                          Divider(height: 20.h, color: Colors.white24),
                          _buildInfoRow(
                            '📅 موعد الاجتماع:',
                            _formatDateTime(datetime),
                          ),
                          Divider(height: 20.h, color: Colors.white24),
                          _buildInfoRow('📝 الملاحظات:', notes),
                          Divider(height: 20.h, color: Colors.white24),
                          _buildInfoRow(
                            '🕐 تاريخ الطلب:',
                            _formatDateTime(createdAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              title: label,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          Expanded(
            flex: 3,
            child: AppText(title: value, fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
