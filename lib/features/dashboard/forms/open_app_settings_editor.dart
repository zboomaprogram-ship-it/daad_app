import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> openAppSettingsEditor(BuildContext context) async {
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
              const Text(
                'إعدادات التطبيق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              LabeledField(label: 'رابط صورة البانر', controller: bannerCtrl),
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
