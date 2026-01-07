import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart'
    show NotificationService;
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationDebugWidget extends StatefulWidget {
  const NotificationDebugWidget({super.key});

  @override
  State<NotificationDebugWidget> createState() =>
      _NotificationDebugWidgetState();
}

class _NotificationDebugWidgetState extends State<NotificationDebugWidget> {
  String? _userId;
  String? _externalUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  void _loadUserId() {
    setState(() {
      _userId = NotificationService.getUserId();
      _externalUserId = NotificationService.getExternalUserId();
    });
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);

    bool success = false;
    try {
      success = await NotificationService.sendNotification(
        title: 'إشعار تجريبي',
        body: 'هذا إشعار تجريبي من تطبيق الدعد',
      );
    } catch (e) {
      print('Error: $e');
      success = false;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            title: success ? 'تم الإرسال بنجاح ✓' : 'فشل الإرسال ✗',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.r),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText(
              title: '🔔 اختبار الإشعارات',

              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 16.h),

            // OneSignal Player ID Display
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          title: 'OneSignal Player ID:',

                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4.h),
                        AppText(title: _userId ?? 'غير متصل', fontSize: 12),
                      ],
                    ),
                  ),
                  if (_userId != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _userId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText(title: 'تم النسخ'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // External User ID Display
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint, size: 20),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          title: 'External User ID (Firebase UID):',

                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4.h),
                        AppText(title: _externalUserId ?? 'غير مسجل'),
                      ],
                    ),
                  ),
                  if (_externalUserId != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _externalUserId!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText(title: 'تم النسخ'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Test Instructions
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    title: '📋 خطوات الاختبار:',
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  const AppText(title: '1. اضغط على زر "إرسال إشعار تجريبي"'),
                  const AppText(title: '2. اغلق التطبيق أو ضعه في الخلفية'),
                  const AppText(title: '3. يجب أن تستلم الإشعار خلال ثوانٍ'),
                  SizedBox(height: 8.h),
                  const AppText(
                    title: '💡 ملاحظة: الإشعارات لا تعمل بشكل جيد على المحاكي',

                    fontSize: 12,

                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Send Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendTestNotification,
                icon: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          // strokewidth: 2.w
                          strokeWidth: 2.w,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: AppText(
                  title: _isLoading ? 'جاري الإرسال...' : 'إرسال إشعار تجريبي',
                  color: AppColors.primaryColor,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Refresh User ID Button
            TextButton.icon(
              onPressed: _loadUserId,
              icon: const Icon(Icons.refresh, size: 18),
              label: const AppText(title: 'تحديث معرف المستخدم'),
            ),
          ],
        ),
      ),
    );
  }
}
