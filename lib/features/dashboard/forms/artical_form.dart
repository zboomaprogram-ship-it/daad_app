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

Future<void> openArticleForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};

  final titleAr = TextEditingController(text: data['title'] ?? '');
  final bodyAr = TextEditingController(text: data['body'] ?? '');

  List<String> uploadedImages = data['images'] != null
      ? List<String>.from(data['images'])
      : [];

  final tagsCsv = TextEditingController(
    text: (data['tags'] is List) ? (data['tags'] as List).join(',') : '',
  );

  // ✅ Notification switch (default = true for new post, false for edit unless stored)
  bool sendNotification = data['sendNotification'] ?? (!isEdit);

  await showModalBottomSheet(
    backgroundColor: AppColors.primaryColor,
    context: context,
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
                title: isEdit ? 'تعديل مقال' : 'إضافة مقال',

                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 12.h),

              LabeledField(label: 'العنوان (عربي)', controller: titleAr),
              LabeledField(
                label: 'المحتوى (عربي)',
                controller: bodyAr,
                maxLines: 5,
              ),

              // 🔥 Upload Images
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
                label: const AppText(
                  title: 'اختيار صور متعددة',
                  color: AppColors.primaryColor,
                ),
              ),

              SizedBox(height: 8.h),
              // Add this test button in your form
              ElevatedButton.icon(
                onPressed: () async {
                  final result =
                      await WordPressMediaService.testAuthentication();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText(
                        title: result ? 'تم التحقق بنجاح ✅' : 'فشل التحقق ❌',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_user),
                label: const AppText(
                  title: 'اختبار الاتصال',
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              if (uploadedImages.isNotEmpty)
                SizedBox(
                  height: 120.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: uploadedImages.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Stack(
                        children: [
                          Image.network(
                            uploadedImages[i],
                            height: 100.h,
                            width: 100.w,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
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

              SizedBox(height: 10.h),

              LabeledField(
                label: 'وسوم (tags) مفصولة بفواصل',
                controller: tagsCsv,
              ),

              SizedBox(height: 10.h),

              // ✅ Notification toggle
              SwitchListTile(
                title: const AppText(title: 'إرسال إشعار للمستخدمين'),
                subtitle: const AppText(
                  title: 'تنبيه المستخدمين بالمقال الجديد/المُعدل',
                ),
                activeThumbColor: Colors.greenAccent,
                value: sendNotification,
                onChanged: (v) => setModalState(() => sendNotification = v),
              ),

              SizedBox(height: 12.h),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: AppText(
                  title: isEdit ? 'حفظ' : 'نشر',
                  color: AppColors.primaryColor,
                ),
                onPressed: () async {
                  final tags = tagsCsv.text.trim().isEmpty
                      ? <String>[]
                      : tagsCsv.text.split(',').map((e) => e.trim()).toList();

                  final payload = {
                    'title': titleAr.text.trim(),
                    'body': bodyAr.text.trim(),
                    'tags': tags,
                    'images': uploadedImages,
                    'publishedAt': isEdit
                        ? (data['publishedAt'] ?? FieldValue.serverTimestamp())
                        : FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'sendNotification': sendNotification,
                  };

                  final col = FirebaseFirestore.instance.collection('articles');

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    if (isEdit) {
                      await col
                          .doc(doc.id)
                          .set(payload, SetOptions(merge: true));
                    } else {
                      await col.add(payload);
                    }

                    // ✅ Send notification if enabled
                    if (sendNotification) {
                      await NotificationService.sendNotification(
                        title: isEdit ? '📌 تحديث مقال' : '📰 مقال جديد',
                        body: titleAr.text.trim(),
                        deepLink: DeepLinkHandler.articleLink(doc!.id),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: AppText(
                            title: isEdit
                                ? 'تم التعديل وإرسال الإشعار'
                                : 'تم النشر وإرسال الإشعار',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: AppText(
                            title: isEdit ? 'تم تعديل المقال' : 'تم نشر المقال',
                          ),
                        ),
                      );
                    }

                    if (context.mounted)
                      Navigator.pop(context); // close loading
                    if (context.mounted) Navigator.pop(context); // close sheet
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
