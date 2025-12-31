import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

Future<void> openLearnForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};

  final titleAr = TextEditingController(text: data['title'] ?? '');
  final person = TextEditingController(text: data['person'] ?? '');
  final link = TextEditingController(text: data['link'] ?? '');
  final bodyAr = TextEditingController(text: data['body'] ?? '');

  List<String> uploadedImages = data['images'] != null
      ? List<String>.from(data['images'])
      : [];

  final tagsCsv = TextEditingController(
    text: (data['tags'] is List) ? (data['tags'] as List).join(',') : '',
  );

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
                title: isEdit ? 'تعديل تعلم' : 'إضافة تعلم',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 12.h),

              LabeledField(label: 'العنوان (عربي)', controller: titleAr),
              LabeledField(label: 'الشخص', controller: person),
              LabeledField(label: 'Link', controller: link),
              LabeledField(label: 'ملخص', controller: bodyAr, maxLines: 5),

              SizedBox(height: 10.h),

              // 📸 Upload Multiple images - FIXED VERSION
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final images = await ImagePicker().pickMultiImage();
                      if (images.isEmpty) return;

                      // CRITICAL: Capture the ScaffoldMessenger before async gap
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      // Show uploading message
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: AppText(title: 'جاري رفع الصور...'),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      try {
                        final wordPressUrls =
                            await WordPressMediaService.uploadMultipleImages(
                          images,
                        );

                        // Check if widget is still mounted before updating state
                        if (!context.mounted) return;

                        if (wordPressUrls.isNotEmpty) {
                          setModalState(() {
                            uploadedImages.addAll(wordPressUrls);
                          });
                          
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: AppText(
                                title: "تم رفع ${wordPressUrls.length} صورة",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: AppText(title: 'فشل رفع الصور'),
                            ),
                          );
                        }
                      } catch (e) {
                        // Only show error if widget is still mounted
                        if (context.mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: AppText(title: 'خطأ في رفع الصور: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const AppText(title: 'اختيار صور متعددة'),
                  ),
                  SizedBox(height: 8.h),
                  if (uploadedImages.isNotEmpty)
                    SizedBox(
                      height: 120.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: uploadedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.all(4.0.r),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    uploadedImages[index],
                                    height: 100.h,
                                    width: 100.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        uploadedImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),

              SizedBox(height: 10.h),

              LabeledField(
                label: 'وسوم (tags) مفصولة بفواصل',
                controller: tagsCsv,
              ),

              SizedBox(height: 10.h),

              SwitchListTile(
                title: const AppText(title: 'إرسال إشعار للمستخدمين'),
                subtitle: const AppText(
                  title: 'إعلام المستخدمين بالمقال الجديد/المحدّث',
                ),
                activeColor: Colors.greenAccent,
                value: sendNotification,
                onChanged: (v) => setModalState(() => sendNotification = v),
              ),

              SizedBox(height: 12.h),

              ElevatedButton.icon(
                onPressed: () async {
                  // Validation
                  if (titleAr.text.trim().isEmpty ||
                      bodyAr.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: AppText(
                          title: 'يرجى إدخال العنوان و الملخص',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final tags = tagsCsv.text.trim().isEmpty
                      ? <String>[]
                      : tagsCsv.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                  final payload = {
                    'title': titleAr.text.trim(),
                    'person': person.text.trim(),
                    'link': link.text.trim(),
                    'body': bodyAr.text.trim(),
                    'tags': tags,
                    'images': uploadedImages,
                    'publishedAt': isEdit
                        ? (data['publishedAt'] ?? FieldValue.serverTimestamp())
                        : FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'sendNotification': sendNotification,
                  };

                  final col = FirebaseFirestore.instance.collection(
                    'learnWithdaad',
                  );

                  // CRITICAL: Capture navigator and messenger before async operations
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // Save to Firestore
                    if (isEdit) {
                      await col
                          .doc(doc.id)
                          .set(payload, SetOptions(merge: true));
                    } else {
                      await col.add(payload);
                    }

                    // Send notification if enabled
                    if (sendNotification) {
                      try {
                        await NotificationService.sendNotification(
                          title: isEdit ? '📣 تعلم محدّث' : '📚 تعلم جديد',
                          body:
                              '${titleAr.text.trim()} ${person.text.trim().isNotEmpty ? "بواسطة ${person.text.trim()}" : ""}',
                              deepLink:DeepLinkHandler.learnLink(doc!.id),
                        );
                        
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: AppText(
                              title: isEdit
                                  ? 'تم التحديث وإرسال الإشعار بنجاح'
                                  : 'تم النشر وإرسال الإشعار بنجاح',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (notifyErr) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: AppText(
                              title:
                                  'تم الحفظ لكن فشل إرسال الإشعار: ${notifyErr.toString()}',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: AppText(
                            title: isEdit
                                ? 'تم تحديث المقال بنجاح'
                                : 'تم نشر المقال بنجاح',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    // Close dialogs using captured navigator
                    navigator.pop(); // close loading dialog
                    navigator.pop(); // close bottom sheet
                  } catch (e) {
                    navigator.pop(); // close loading dialog
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: AppText(
                          title: 'حدث خطأ أثناء الحفظ: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: AppText(title: isEdit ? 'حفظ' : 'نشر'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}