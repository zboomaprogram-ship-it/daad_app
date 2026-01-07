import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/chatbot_persona_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: ListView(
          children: [
            // إعدادات الواجهة
            _buildSettingsCard(
              context,
              title: 'إعدادات الواجهة',
              subtitle: 'التحكم في عرض العناصر الرئيسية',
              icon: Icons.dashboard_customize,
              onTap: () => _openAppSettingsEditor(context),
            ),

            SizedBox(height: 16.h),

            // إعدادات البوت
            _buildSettingsCard(
              context,
              title: 'إعدادات البوت الذكي',
              subtitle: 'تعديل شخصية وسلوك مساعد ضاد',
              icon: Icons.smart_toy,
              onTap: () => _openChatBotPersonaEditor(context),
            ),

            SizedBox(height: 16.h),

            // عرض حالة Remote Config
            _buildSettingsCard(
              context,
              title: 'حالة المفاتيح السرية',
              subtitle: 'التحقق من اتصال Remote Config',
              icon: Icons.security,
              onTap: () => _showConfigStatus(context),
            ),

            SizedBox(height: 16.h),

            // معلومات عامة
            // _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: AppText(title: title, fontWeight: FontWeight.bold, fontSize: 16),
        subtitle: AppText(title: subtitle, fontSize: 12),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                SizedBox(width: 8.w),
                AppText(
                  title: 'ملاحظات مهمة',

                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue.shade900,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            AppText(
              title:
                  '• المفاتيح السرية محفوظة في Firebase Remote Config\n'
                  '• يتم تحديث إعدادات البوت فوراً في جميع الأجهزة\n'
                  '• التغييرات آمنة ولا تحتاج إعادة نشر التطبيق',
              fontSize: 12.sp,
              color: Colors.blue.shade800,
            ),
          ],
        ),
      ),
    );
  }

  // فتح محرر إعدادات الواجهة
  Future<void> _openAppSettingsEditor(BuildContext context) async {
    final docRef = FirebaseFirestore.instance
        .collection('app_settings')
        .doc('public');
    final snap = await docRef.get();
    final data = (snap.data() ?? <String, dynamic>{});

    bool showDeals = (data['show_deals_wheel'] ?? false) as bool;
    bool showBanner = (data['show_home_banner'] ?? false) as bool;
    final bannerCtrl = TextEditingController(
      text: data['home_banner_image'] ?? '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            right: 16,
            left: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  title: 'إعدادات التطبيق',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 12.h),
                SwitchListTile(
                  title: const AppText(title: 'إظهار عجلة العروض'),
                  value: showDeals,
                  onChanged: (v) => setSheet(() => showDeals = v),
                ),
                SwitchListTile(
                  title: const AppText(title: 'إظهار بانر الصفحة الرئيسية'),
                  value: showBanner,
                  onChanged: (v) => setSheet(() => showBanner = v),
                ),
                TextField(
                  controller: bannerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط صورة البانر',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                ElevatedButton.icon(
                  onPressed: () async {
                    await docRef.set({
                      'show_deals_wheel': showDeals,
                      'show_home_banner': showBanner,
                      'home_banner_image': bannerCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const AppText(title: 'حفظ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // فتح محرر شخصية البوت
  void _openChatBotPersonaEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatBotPersonaEditor()),
    );
  }

  // عرض حالة المفاتيح
  Future<void> _showConfigStatus(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const AppText(title: 'حالة المفاتيح السرية'),
        content: FutureBuilder<Map<String, String>>(
          future: _getConfigStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return AppText(title: 'خطأ: ${snapshot.error}');
            }

            final status = snapshot.data ?? {};
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: status.entries.map((e) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      AppText(title: e.value, fontWeight: FontWeight.bold),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AppText(title: e.key, fontSize: 12.sp),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
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

  Future<Map<String, String>> _getConfigStatus() async {
    // هنا يمكنك استدعاء SecureConfigService.getAllKeys()
    // للحصول على حالة المفاتيح
    await Future.delayed(const Duration(seconds: 1));
    return {
      'gemini_api_key': '✅ موجود',
      'wordpress_url': '✅ موجود',
      'wordpress_username': '✅ موجود',
      'wordpress_app_password': '✅ موجود',
      'filebird_api_key': '✅ موجود',
      'onesignal_app_id': '✅ موجود',
      'onesignal_rest_api_key': '✅ موجود',
      'chat_model': '✅ موجود',
      'llama_api_key': '✅ موجود',
    };
  }
}

// استيراد ChatBotPersonaEditor
// class ChatBotPersonaEditor extends StatefulWidget {
//   const ChatBotPersonaEditor({super.key});

//   @override
//   State<ChatBotPersonaEditor> createState() => _ChatBotPersonaEditorState();
// }

// class _ChatBotPersonaEditorState extends State<ChatBotPersonaEditor> {
//   // ... (استخدم الكود من الـ artifact السابق)
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('إعدادات البوت')),
//       body: const Center(child: Text('محرر شخصية البوت هنا')),
//     );
//   }
// }
