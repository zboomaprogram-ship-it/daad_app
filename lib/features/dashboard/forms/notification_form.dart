import 'package:daad_app/features/dashboard/services/notification_services.dart';
import 'package:daad_app/features/dashboard/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
 import '../widgets/labeled_field.dart';

Future<void> showNotificationForm(BuildContext context) async {
 final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final userIdCtrl = TextEditingController();
  final deepLinkCtrl = TextEditingController();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => buildGlassBottomSheet(
      context: context,
      title: 'إرسال إشعار',
      children: [
        LabeledField(label: 'العنوان', controller: titleCtrl),
        LabeledField(label: 'المحتوى', controller: bodyCtrl, maxLines: 3),
     LabeledField(
          label: 'معرف المستخدم (اختياري - فارغ للجميع)',
          controller: userIdCtrl,
        ),
        LabeledField(
          label: 'رابط التطبيق (اختياري)',
          controller: deepLinkCtrl,
        ),
        const SizedBox(height: 16),
        GlassButton(
          onPressed: () async {
            if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يرجى ملء الحقول المطلوبة'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            await NotificationService.sendNotification(
              title: titleCtrl.text.trim(),
              body: bodyCtrl.text.trim(),
              userId: userIdCtrl.text.trim().isEmpty ? null : userIdCtrl.text.trim(),
              deepLink: deepLinkCtrl.text.trim().isEmpty ? null : deepLinkCtrl.text.trim(),
            );

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إرسال الإشعار بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send, size: 20),
              SizedBox(width: 8),
              Text('إرسال الإشعار'),
            ],
          ),
        ),
      ],
    ),
  );
}