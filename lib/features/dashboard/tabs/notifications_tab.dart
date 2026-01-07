import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  final List<DocumentSnapshot> _notifications = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  String? _currentUserRole;
  List<String> _assignedUserIds = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      _currentUserId = user.uid;
      _currentUserRole = userDoc.data()?['role'] ?? 'client';

      // For sales, get their assigned users list
      if (_currentUserRole == 'sales') {
        _assignedUserIds = List<String>.from(
          userDoc.data()?['assignedUsers'] ?? [],
        );
      }
    });

    _loadInitialNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadInitialNotifications() async {
    if (!mounted) return;

    setState(() {
      _notifications.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadMoreNotifications();
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore || _currentUserId == null) return;

    if (!mounted) return;

    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true);

      query = query.limit(_pageSize * 2); // Fetch more for filtering

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (!mounted) return;

      // Filter notifications based on role
      List<DocumentSnapshot> filteredDocs = snapshot.docs;

      if (_currentUserRole == 'sales') {
        // For sales: show only notifications they sent OR to their assigned clients OR broadcast
        filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final sentBy = data['sentBy'];
          final userId = data['userId'];
          final targetType = data['targetType'];

          // Show if:
          // 1. Sent by this sales person
          // 2. Sent to one of their assigned clients
          // 3. Targeted to "my_clients" and sent by this sales person
          // 4. Broadcast (userId is null and targetType is 'all')
          return sentBy == _currentUserId ||
              (userId != null && _assignedUserIds.contains(userId)) ||
              (targetType == 'my_clients' && sentBy == _currentUserId) ||
              (userId == null && targetType == 'all');
        }).toList();
      }

      if (filteredDocs.length < _pageSize) {
        if (mounted) {
          setState(() => _hasMore = false);
        }
      }

      if (filteredDocs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _lastDocument = filteredDocs.last;
            _notifications.addAll(filteredDocs);
          });
        }
      } else {
        if (mounted) {
          setState(() => _hasMore = false);
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _showSendNotificationDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String targetType = _currentUserRole == 'sales' ? 'my_clients' : 'all';
    String? selectedUserId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
          title: const AppText(title: 'إرسال إشعار'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: bodyController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'المحتوى',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                SizedBox(height: 16.h),

                // Target selection
                const AppText(title: 'إرسال إلى:', fontWeight: FontWeight.bold),

                if (_currentUserRole == 'admin') ...[
                  RadioListTile<String>(
                    title: const AppText(title: 'الجميع'),
                    value: 'all',
                    groupValue: targetType,
                    onChanged: (value) {
                      setDialogState(() {
                        targetType = value!;
                        selectedUserId = null;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const AppText(title: 'مستخدم محدد'),
                    value: 'specific',
                    groupValue: targetType,
                    onChanged: (value) {
                      setDialogState(() {
                        targetType = value!;
                      });
                    },
                  ),
                ],

                if (_currentUserRole == 'sales') ...[
                  RadioListTile<String>(
                    title: const AppText(title: 'جميع عملائي'),
                    value: 'my_clients',
                    groupValue: targetType,
                    onChanged: (value) {
                      setDialogState(() {
                        targetType = value!;
                        selectedUserId = null;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const AppText(title: 'عميل محدد'),
                    value: 'specific',
                    groupValue: targetType,
                    onChanged: (value) {
                      setDialogState(() {
                        targetType = value!;
                      });
                    },
                  ),
                ],

                if (targetType == 'specific') ...[
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () async {
                      final userId = await _selectUser();
                      if (userId != null) {
                        setDialogState(() {
                          selectedUserId = userId;
                        });
                      }
                    },
                    child: AppText(
                      title: selectedUserId != null
                          ? 'تم اختيار المستخدم'
                          : 'اختر مستخدم',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText(title: 'إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: AppText(title: 'الرجاء إدخال العنوان والمحتوى'),
                    ),
                  );
                  return;
                }

                if (targetType == 'specific' && selectedUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: AppText(title: 'الرجاء اختيار مستخدم'),
                    ),
                  );
                  return;
                }

                await _sendNotification(
                  title: titleController.text,
                  body: bodyController.text,
                  targetType: targetType,
                  userId: selectedUserId,
                );

                Navigator.pop(context);
              },
              child: const AppText(title: 'إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _selectUser() async {
    Query query = FirebaseFirestore.instance.collection('users');

    // Filter based on role
    if (_currentUserRole == 'sales') {
      // Sales can only select from their assigned clients
      if (_assignedUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText(title: 'لا يوجد عملاء مخصصين لك')),
        );
        return null;
      }

      // Fetch assigned users
      const batchSize = 10;
      List<DocumentSnapshot> assignedUsers = [];

      for (int i = 0; i < _assignedUserIds.length; i += batchSize) {
        final batch = _assignedUserIds.skip(i).take(batchSize).toList();
        final snapshot = await query
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        assignedUsers.addAll(snapshot.docs);
      }

      if (!mounted) return null;

      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
          title: const AppText(title: 'اختر عميل'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400.h,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: assignedUsers.length,
              itemBuilder: (context, index) {
                final user = assignedUsers[index];
                final data = user.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: AppText(
                      title: (data['name'] ?? 'U')[0].toUpperCase(),
                    ),
                  ),
                  title: AppText(title: data['name'] ?? 'مستخدم'),
                  subtitle: AppText(
                    title: data['email'] ?? '',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  onTap: () => Navigator.pop(context, user.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText(title: 'إلغاء'),
            ),
          ],
        ),
      );
    } else {
      // Admin can select any user
      final users = await query.get();

      if (!mounted) return null;

      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
          title: const AppText(title: 'اختر مستخدم'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400.h,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.docs.length,
              itemBuilder: (context, index) {
                final user = users.docs[index];
                final data = user.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: AppText(
                      title: (data['name'] ?? 'U')[0].toUpperCase(),
                    ),
                  ),
                  title: AppText(title: data['name'] ?? 'مستخدم'),
                  subtitle: AppText(
                    title: data['email'] ?? '',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  onTap: () => Navigator.pop(context, user.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText(title: 'إلغاء'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    required String targetType,
    String? userId,
  }) async {
    try {
      if (targetType == 'all' && _currentUserRole == 'admin') {
        // Send to all users
        await NotificationService.sendNotification(title: title, body: body);
      } else if (targetType == 'my_clients') {
        // Send to all assigned clients
        for (final clientId in _assignedUserIds) {
          await NotificationService.sendNotification(
            title: title,
            body: body,
            userId: clientId,
          );
        }
      } else if (targetType == 'specific' && userId != null) {
        // Send to specific user
        await NotificationService.sendNotification(
          title: title,
          body: body,
          userId: userId,
        );
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'userId': targetType == 'specific' ? userId : null,
        'targetType': targetType,
        'sentBy': _currentUserId,
        'sentByRole': _currentUserRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(title: 'تم إرسال الإشعار بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialNotifications();
      }
    } catch (e) {
      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(title: 'خطأ في الإرسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUserRole == 'admin';

    return Scaffold(
      body: _notifications.isEmpty && !_isLoadingMore
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  AppText(
                    title: 'لا توجد إشعارات بعد',
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    title: 'اضغط على الزر أدناه لإرسال إشعار',
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.r),
              itemCount: _notifications.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _notifications.length) {
                  return _isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                final doc = _notifications[index];
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['createdAt'] as Timestamp?;
                final dateStr = timestamp != null
                    ? _formatTimestamp(timestamp)
                    : 'الآن';

                return Card(
                  color: AppColors.secondaryColor,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.orange,
                      ),
                    ),
                    title: AppText(
                      title: data['title'] ?? 'إشعار',
                      fontWeight: FontWeight.bold,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        AppText(
                          title: data['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4.w),
                            AppText(
                              title: dateStr,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 12.w),
                            if (data['targetType'] == 'all')
                              Chip(
                                label: const AppText(
                                  title: 'للجميع 📢',
                                  fontSize: 10,
                                ),
                                backgroundColor: Colors.green[100],
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              )
                            else if (data['targetType'] == 'my_clients')
                              Chip(
                                label: const AppText(
                                  title: 'لعملائي 👥',
                                  fontSize: 10,
                                ),
                                backgroundColor: Colors.blue[100],
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              )
                            else
                              Chip(
                                label: const AppText(
                                  title: 'مستخدم محدد 👤',
                                  fontSize: 10,
                                ),
                                backgroundColor: Colors.purple[100],
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, doc.id),
                          )
                        : null,
                    onTap: () => _showNotificationDetails(context, data),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendNotificationDialog,
        icon: const Icon(Icons.send),
        label: const AppText(title: 'إرسال إشعار'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: const AppText(title: 'حذف إشعار'),
        content: const AppText(title: 'هل أنت متأكد من حذف هذا الإشعار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(title: 'إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(docId)
                  .delete();

              setState(() {
                _notifications.removeWhere((notif) => notif.id == docId);
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: AppText(title: 'تم الحذف بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const AppText(title: 'حذف', color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.orange),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText(title: data['title'] ?? 'إشعار', fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(title: 'المحتوى:', fontWeight: FontWeight.bold),
              SizedBox(height: 8.h),
              AppText(title: data['body'] ?? ''),
              SizedBox(height: 16.h),
              if (data['userId'] != null) ...[
                const AppText(
                  title: 'معرف المستخدم:',
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 4.h),
                AppText(title: data['userId']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(title: 'إغلاق'),
          ),
        ],
      ),
    );
  }
}
