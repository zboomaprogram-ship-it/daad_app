import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

Future<void> openServiceForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};

  final titleAr = TextEditingController(text: data['title'] ?? '');
  final descAr = TextEditingController(text: data['desc'] ?? '');
  final priceCtrl = TextEditingController(
    text: (data['priceTiers'] is List && data['priceTiers'].isNotEmpty)
        ? (data['priceTiers'][0]['price']?.toString() ?? '')
        : '',
  );
  final featuresCsv = TextEditingController(
    text:
        (data['priceTiers'] is List &&
            data['priceTiers'].isNotEmpty &&
            data['priceTiers'][0]['features'] is List)
        ? (data['priceTiers'][0]['features'] as List).join(',')
        : '',
  );

  List<String> uploadedImages = data['images'] != null
      ? List<String>.from(data['images'])
      : [];

  bool isActive = (data['isActive'] ?? true) as bool;
  final orderCtrl = TextEditingController(
    text: (data['order'] ?? 1).toString(),
  );

  final categoryOptions = [
    'main',
    'المجال الطبي',
    'إنشاء المتاجر',
    'التجارة الإلكترونية',
    'مطاعم',
  ];
  String selectedCategory = data['category'] ?? 'main';

  // ✅ Notification switch
  bool sendNotification = data['sendNotification'] ?? (!isEdit);

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.primaryColor,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          right: 16,
          left: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                title: isEdit ? 'تعديل خدمة' : 'إضافة خدمة',

                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 12.h),

              LabeledField(label: 'العنوان (عربي)', controller: titleAr),
              LabeledField(
                label: 'الوصف (عربي)',
                controller: descAr,
                maxLines: 3,
              ),

              // ✅ Category
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                onChanged: (v) => setModalState(() => selectedCategory = v!),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: categoryOptions
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: AppText(title: cat),
                      ),
                    )
                    .toList(),
              ),

              SizedBox(height: 8.h),

              // ✅ Upload images
              ElevatedButton.icon(
                onPressed: () async {
                  final images = await ImagePicker().pickMultiImage();
                  if (images.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: AppText(title: 'جاري رفع الصور...'),
                      ),
                    );

                    try {
                      // Upload to WordPress instead of Cloudinary
                      final wordPressUrls =
                          await WordPressMediaService.uploadMultipleImages(
                            images,
                          );

                      if (wordPressUrls.isNotEmpty) {
                        setModalState(
                          () => uploadedImages.addAll(wordPressUrls),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AppText(
                              title: "تم رفع ${wordPressUrls.length} صورة",
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText(title: 'فشل رفع الصور'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: AppText(title: 'خطأ في رفع الصور: $e'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const AppText(title: 'اختيار صور'),
              ),

              if (uploadedImages.isNotEmpty)
                SizedBox(
                  height: 120.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: uploadedImages.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.all(4.0.r),
                      child: Stack(
                        children: [
                          Image.network(
                            uploadedImages[i],
                            height: 100.h,
                            width: 100.w,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => setModalState(
                                () => uploadedImages.removeAt(i),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              LabeledField(
                label: 'الترتيب',
                controller: orderCtrl,
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const AppText(title: 'مُفعل'),
                value: isActive,
                onChanged: (v) => setModalState(() => isActive = v),
              ),

              // ✅ Pricing inputs
              LabeledField(
                label: 'السعر',
                controller: priceCtrl,
                keyboardType: TextInputType.number,
              ),
              LabeledField(
                label: 'المميزات (مفصولة بفواصل)',
                controller: featuresCsv,
              ),

              SizedBox(height: 10.h),

              // ✅ Notification toggle
              SwitchListTile(
                title: const AppText(title: 'إرسال إشعار للعملاء'),
                subtitle: const AppText(title: 'تنبيه المستخدمين بشأن الخدمة'),
                value: sendNotification,
                onChanged: (v) => setModalState(() => sendNotification = v),
                activeThumbColor: Colors.greenAccent,
              ),

              SizedBox(height: 10.h),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: AppText(title: isEdit ? 'حفظ التعديلات' : 'إضافة'),
                onPressed: () async {
                  final price = double.tryParse(priceCtrl.text.trim());
                  final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
                  final features = featuresCsv.text.trim().isEmpty
                      ? <String>[]
                      : featuresCsv.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList();

                  final body = {
                    'title': titleAr.text.trim(),
                    'desc': descAr.text.trim(),
                    'images': uploadedImages,
                    'isActive': isActive,
                    'order': order,
                    'category': selectedCategory,
                    'priceTiers': [
                      {
                        'name': 'Basic',
                        'price': price ?? 0,
                        'features': features,
                      },
                    ],
                    'updatedAt': FieldValue.serverTimestamp(),
                    'sendNotification': sendNotification,
                  };

                  final col = FirebaseFirestore.instance.collection('services');

                  // ✅ Show loading
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    if (isEdit) {
                      await col.doc(doc.id).set(body, SetOptions(merge: true));
                    } else {
                      body['createdAt'] = FieldValue.serverTimestamp();
                      await col.add(body);
                    }

                    if (sendNotification) {
                      await NotificationService.sendNotification(
                        title: isEdit ? '🔧 تحديث خدمة' : '✨ خدمة جديدة',
                        body: titleAr.text.trim(),
                        deepLink: DeepLinkHandler.serviceLink(doc!.id),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: AppText(
                            title: '✅ تم حفظ الخدمة وإرسال الإشعار',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: AppText(title: '✅ تم حفظ الخدمة'),
                        ),
                      );
                    }

                    Navigator.pop(context); // close loader
                    Navigator.pop(context); // close sheet
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: AppText(title: 'خطأ: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
