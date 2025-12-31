import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RedeemRequestsTab extends StatefulWidget {
  const RedeemRequestsTab({super.key});

  @override
  State<RedeemRequestsTab> createState() => _RedeemRequestsTabState();
}

class _RedeemRequestsTabState extends State<RedeemRequestsTab> {
  static const int _pageSize = 10;

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoadingInitial = true;

  final List<DocumentSnapshot> _requests = [];
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

  Query _baseQuery() {
    return FirebaseFirestore.instance
        .collection('redeem_requests')
        .orderBy('createdAt', descending: true);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
    });

    try {
      final snapshot = await _baseQuery().limit(_pageSize).get();

      if (!mounted) return;
      setState(() {
        _requests
          ..clear()
          ..addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ خطأ في تحميل الطلبات: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_lastDocument == null || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await _baseQuery()
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (!mounted) return;
      setState(() {
        _requests.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: "❌ خطأ في تحميل المزيد: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data() ?? {};
    return {
      "name": data['name'] ?? "مستخدم غير معروف",
      "phone": data['phone'] ?? "بدون رقم",
      "points": data['points'] ?? 0,
    };
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
      "date": FieldValue.serverTimestamp()
    });
  }

  /// ✅ FIXED: Only update status to approved, DON'T deduct points
  Future<void> _approve(
    String requestId,
    String userId,
    int requiredPoints,
    String reward,
  ) async {
    final requestRef =
        FirebaseFirestore.instance.collection('redeem_requests').doc(requestId);

    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception("الطلب غير موجود");
    }

    final requestData = requestDoc.data() as Map<String, dynamic>;
    final currentStatus = requestData['status'];

    if (currentStatus == 'approved') {
      throw Exception("هذا الطلب تمت الموافقة عليه بالفعل");
    }

    // ✅ Just update status - points already deducted when request was created
    await requestRef.update({
      "status": "approved",
      "approvedAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await NotificationService.sendNotification(
      title: '🎉 تمت الموافقة على طلب الاستبدال',
      body: 'تم قبول طلبك لاستبدال $requiredPoints نقطة بـ: $reward',
      userId: userId,
      deepLink: DeepLinkHandler.rewardsLink(),
    );

    await _loadInitialData();
  }

  /// ✅ FIXED: Return points when rejecting
  Future<void> _reject(
    String requestId,
    String userId,
    int requiredPoints,
    String reward,
  ) async {
    final requestRef =
        FirebaseFirestore.instance.collection('redeem_requests').doc(requestId);

    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception("الطلب غير موجود");
    }

    final requestData = requestDoc.data() as Map<String, dynamic>;
    final currentStatus = requestData['status'];

    if (currentStatus == 'rejected') {
      throw Exception("هذا الطلب تم رفضه بالفعل");
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // ✅ Return points and update status
    await FirebaseFirestore.instance.runTransaction((trx) async {
      final userSnap = await trx.get(userRef);
      final currentPoints = (userSnap.data()?['points'] ?? 0) as int;

      trx.update(userRef, {"points": currentPoints + requiredPoints});
      trx.update(requestRef, {
        "status": "rejected",
        "rejectedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    });

    await _addHistory(
      userId,
      requiredPoints,
      "refund",
      "إرجاع نقاط بعد رفض استبدال: $reward",
    );

    await NotificationService.sendNotification(
      title: '❌ تم رفض طلب الاستبدال',
      body: 'تم رفض طلبك لاستبدال: $reward وتم إرجاع $requiredPoints نقطة',
      userId: userId,
      deepLink: DeepLinkHandler.rewardsLink(),
    );

    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return const Center(child: AppText(title: "لا يوجد طلبات استبدال حالياً"));
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(12.r),
        itemCount: _requests.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _requests.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0.r),
                child: const CircularProgressIndicator(),
              ),
            );
          }

          final req = _requests[index];
          final data = (req.data() as Map<String, dynamic>?) ?? {};

          final uid = (data['userId'] ?? '').toString();
          final status = (data['status'] ?? 'pending').toString();
          final requestType = (data['requestType'] ?? data['type'] ?? 'unknown').toString();

          final selectedRewards = data['selectedRewards'] as List?;
          final totalPoints = (data['totalPointsDeducted'] ?? 0);
          final singleRewardTitle = data['rewardTitle'];
          final singleRequiredPoints = (data['requiredPoints'] ?? 0);

          return Card(
            color: AppColors.secondaryColor.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 12),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(uid),
              builder: (context, userSnap) {
                final user = userSnap.data ?? {};
                final name = (user['name'] ?? '').toString();
                final phone = (user['phone'] ?? '').toString();
                final currentPoints = user['points'] ?? 0;

                final Color statusColor = status == "approved"
                    ? Colors.green
                    : status == "rejected"
                        ? Colors.red
                        : Colors.orange;

                // ===== Rewards widget / points handling =====
                late Widget rewardsWidget;
                late int pointsToHandle;

                if (selectedRewards != null && selectedRewards.isNotEmpty) {
                  pointsToHandle = (totalPoints is num) ? totalPoints.toInt() : int.tryParse(totalPoints.toString()) ?? 0;

                  rewardsWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(title: 
                        'المكافآت المحددة:',
                      fontWeight: FontWeight.bold, fontSize: 14,
                      ),
                      SizedBox(height: 6.h),
                      ...selectedRewards.map((reward) {
                        final title = (reward is Map ? (reward['title'] ?? 'مكافأة') : 'مكافأة').toString();
                        final ptsRaw = (reward is Map ? (reward['requiredPoints'] ?? 0) : 0);
                        final pts = (ptsRaw is num) ? ptsRaw.toInt() : int.tryParse(ptsRaw.toString()) ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: AppText(title: 
                                  '$title ($pts نقطة)',
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(),
                    AppText(title: 
                        'إجمالي النقاط: $pointsToHandle',
                      
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
              
                      ),
                    ],
                  );
                } else if (singleRewardTitle != null) {
                  pointsToHandle = (singleRequiredPoints is num)
                      ? singleRequiredPoints.toInt()
                      : int.tryParse(singleRequiredPoints.toString()) ?? 0;

                  rewardsWidget = AppText(title: 
                    'المكافأة: $singleRewardTitle\nالنقاط المطلوبة: $pointsToHandle',
                   fontSize: 13,
                  );
                } else {
                  pointsToHandle = 0;
                  rewardsWidget = const AppText(title: 
                    'لا توجد تفاصيل متاحة',
                    color: Colors.grey,
                  );
                }

                // ===== Request type UI =====
                String requestTypeText = '';
                IconData requestIcon = Icons.help;

                if (requestType.contains('whatsapp')) {
                  requestTypeText = '📱 طلب عبر واتساب';
                  requestIcon = Icons.message;
                } else if (requestType.contains('meeting')) {
                  requestTypeText = '📅 طلب اجتماع';
                  requestIcon = Icons.calendar_month;

                  final scheduledTime = data['scheduledDatetime'] as Timestamp?;
                  if (scheduledTime != null) {
                    final dt = scheduledTime.toDate();
                    requestTypeText +=
                        '\nالموعد: ${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                  }
                } else {
                  requestTypeText = 'طلب غير معروف';
                }

                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(requestIcon, color: statusColor),
                  ),
                  title: AppText(title: 
                    name.isEmpty ? 'مستخدم' : name,
                    fontWeight: FontWeight.bold,
                  ),
                  subtitle: AppText(title: requestTypeText),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: statusColor),
                    ),
                    child: AppText(title: 
                      status == "approved"
                          ? "✅ مقبول"
                          : status == "rejected"
                              ? "❌ مرفوض"
                              : "⏳ معلق",
               
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
               
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('الهاتف', phone),
                          _buildInfoRow('النقاط الحالية', '$currentPoints نقطة'),
                          const Divider(),
                          rewardsWidget,
                          SizedBox(height: 12.h),

                          if (status == "pending") ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await _approve(
                                          req.id,
                                          uid,
                                          pointsToHandle,
                                          'المكافآت المحددة',
                                        );
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: AppText(title: "✅ تم قبول الطلب"),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("❌ خطأ: ${e.toString()}"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const AppText(title: 'قبول'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await _reject(
                                          req.id,
                                          uid,
                                          pointsToHandle,
                                          'المكافآت المحددة',
                                        );
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("❌ تم رفض الطلب وإرجاع النقاط"),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("❌ خطأ: ${e.toString()}"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const AppText(title: 'رفض'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (status == "approved") ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const AppText(title: "تأكيد الرفض"),
                                    content: AppText(title: 
                                      "هل تريد رفض هذا الطلب المقبول؟ سيتم إرجاع $pointsToHandle نقطة للمستخدم.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const AppText(title: "إلغاء"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const AppText(title: "تأكيد"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await _reject(
                                      req.id,
                                      uid,
                                      pointsToHandle,
                                      'المكافآت المحددة',
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: AppText(title: "❌ تم رفض الطلب وإرجاع النقاط"),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: AppText(title: "❌ خطأ: ${e.toString()}"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.undo),
                              label: const AppText(title: 'إلغاء الموافقة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ],
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
}

// Helper widget للمعلومات
Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: AppText(title: 
            '$label:',
        
              fontWeight: FontWeight.bold,
              fontSize: 13,
    
          ),
        ),
        Expanded(
          child:AppText(title: 
            value,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}