import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/labeled_field.dart';

Future<void> showNotificationForm(BuildContext context) async {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final deepLinkCtrl = TextEditingController();

  String? selectedUserId;
  String selectedUserDisplay = 'الجميع 📢';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => buildGlassBottomSheet(
        context: context,
        title: 'إرسال إشعار',
        children: [
          LabeledField(label: 'العنوان', controller: titleCtrl),
          LabeledField(label: 'المحتوى', controller: bodyCtrl, maxLines: 3),

          // User Selection Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: const AppText(
                  title: 'المستخدم المستهدف',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => _showUserSelectionDialog(
                  context,
                  onUserSelected: (userId, userName) {
                    setState(() {
                      selectedUserId = userId;
                      selectedUserDisplay = userName ?? 'مستخدم';
                    });
                  },
                  onClearSelection: () {
                    setState(() {
                      selectedUserId = null;
                      selectedUserDisplay = 'الجميع 📢';
                    });
                  },
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedUserId == null ? Icons.people : Icons.person,
                        color: Colors.white70,
                        size: 20,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AppText(
                          title: selectedUserDisplay,
                          fontSize: 14,
                        ),
                      ),
                      if (selectedUserId != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedUserId = null;
                              selectedUserDisplay = 'الجميع 📢';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.clear,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          LabeledField(
            label: 'رابط التطبيق (اختياري)',
            controller: deepLinkCtrl,
          ),

          // Info Box
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8.w),
                const Expanded(
                  child: Text(
                    'ملاحظة: الإشعارات قد لا تظهر على المحاكي. اختبر على جهاز حقيقي.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          GlassButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  bodyCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: AppText(title: 'يرجى ملء الحقول المطلوبة'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );

              bool success = false;
              try {
                success = await NotificationService.sendNotification(
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  userId: selectedUserId,
                  deepLink: deepLinkCtrl.text.trim().isEmpty
                      ? null
                      : deepLinkCtrl.text.trim(),
                );
              } catch (e) {
                print('Error sending notification: $e');
                success = false;
              }

              if (context.mounted) {
                // Close loading
                Navigator.pop(context);

                // Close form
                Navigator.pop(context);

                // Show result
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            success
                                ? 'تم إرسال الإشعار بنجاح ✓\n(قد يستغرق ثوانٍ للوصول)'
                                : 'فشل إرسال الإشعار ✗\nتحقق من مفتاح API',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send, size: 20),
                SizedBox(width: 8.w),
                const AppText(title: 'إرسال الإشعار'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showUserSelectionDialog(
  BuildContext context, {
  required Function(String? userId, String? userName) onUserSelected,
  required VoidCallback onClearSelection,
}) async {
  final searchController = TextEditingController();
  String searchQuery = '';

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: Column(
          children: [
            const AppText(
              title: 'اختيار مستخدم',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث عن مستخدم...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: Column(
            children: [
              // Send to All option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.3),
                  child: const Icon(Icons.people, color: Colors.green),
                ),
                title: const AppText(
                  title: 'إرسال للجميع 📢',
                  fontWeight: FontWeight.bold,
                ),
                subtitle: const AppText(
                  title: 'سيتم إرسال الإشعار لجميع المستخدمين',
                  fontSize: 12,
                  color: Colors.white60,
                ),
                onTap: () {
                  onClearSelection();
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white24),

              // Users List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      // .where('acceptedTerms', isEqualTo: true)
                      .orderBy('name')
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
                          color: Colors.red,
                        ),
                      );
                    }

                    var users = snapshot.data?.docs ?? [];

                    // Filter by search query
                    if (searchQuery.isNotEmpty) {
                      users = users.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email = (data['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        final phone = (data['phone'] ?? '')
                            .toString()
                            .toLowerCase();

                        return name.contains(searchQuery) ||
                            email.contains(searchQuery) ||
                            phone.contains(searchQuery);
                      }).toList();
                    }

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_off,
                              size: 48,
                              color: Colors.white38,
                            ),
                            SizedBox(height: 8.h),
                            AppText(
                              title: searchQuery.isEmpty
                                  ? 'لا يوجد مستخدمين'
                                  : 'لم يتم العثور على نتائج',
                              color: Colors.white60,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final doc = users[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'مستخدم';
                        final email = data['email'] ?? '';
                        final phone = data['phone'] ?? '';
                        final role = data['role'] ?? 'client';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: role == 'admin'
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.blue.withOpacity(0.3),
                            child: AppText(
                              title: name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'U',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: AppText(
                            title: name,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (email.isNotEmpty)
                                AppText(
                                  title: email,
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              if (phone.isNotEmpty)
                                AppText(
                                  title: phone,
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                            ],
                          ),
                          trailing: role == 'admin'
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: const AppText(
                                    title: 'مسؤول',
                                    fontSize: 10,
                                    color: Colors.orange,
                                  ),
                                )
                              : null,
                          onTap: () {
                            onUserSelected(doc.id, name);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(title: 'إلغاء'),
          ),
        ],
      ),
    ),
  );
}
