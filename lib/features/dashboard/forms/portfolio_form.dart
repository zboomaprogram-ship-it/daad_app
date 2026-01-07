import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/glass_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/labeled_field.dart';

const List<String> industries = [
  'نتائج الحملات الإعلانية',
  'نتائج تحسين محركات البحث',
  'معرض تصاميمنا',
  'أعمال قسم إدارة وسائل التواصل الأجتماعى',
];

// Maximum PDF file size (10MB recommended, adjust as needed)
const int maxPdfSizeInBytes = 10 * 1024 * 1024; // 10MB

Future<void> showPortfolioForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};

  final titleCtrl = TextEditingController(text: data['title'] ?? '');
  final bodyCtrl = TextEditingController(text: data['body'] ?? '');
  final orderCtrl = TextEditingController(
    text: (data['order'] ?? 1).toString(),
  );

  String? selectedIndustry = industries.contains(data['industry'])
      ? data['industry']
      : null;

  List<String> uploadedImages = List<String>.from(data['images'] ?? []);
  String? pdfUrl = data['pdfUrl'];
  String? pdfFileName;
  bool isUploadingPdf = false;
  double pdfUploadProgress = 0.0;

  bool sendNotification = !isEdit;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => buildGlassBottomSheet(
        context: context,
        title: isEdit ? 'تعديل عمل' : 'إضافة عمل',
        children: [
          LabeledField(label: 'عنوان العمل', controller: titleCtrl),
          LabeledField(label: 'الوصف', controller: bodyCtrl, maxLines: 4),

          // القطاع
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8, right: 4),
                child: AppText(
                  title: 'القطاع (industry)',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.secondaryColor,
                    isExpanded: true,
                    value: selectedIndustry,
                    hint: const AppText(title: 'اختر القطاع'),
                    items: industries.map((industry) {
                      return DropdownMenuItem<String>(
                        value: industry,
                        child: AppText(title: industry),
                      );
                    }).toList(),
                    onChanged: (v) => setModalState(() => selectedIndustry = v),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // الصور
          const AppText(title: 'الصور', fontWeight: FontWeight.bold),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            onPressed: () async {
              final images = await ImagePicker().pickMultiImage();
              if (images.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: AppText(title: 'جاري رفع الصور...')),
                );

                try {
                  final wordPressUrls =
                      await WordPressMediaService.uploadMultipleImages(images);

                  if (wordPressUrls.isNotEmpty) {
                    setModalState(() => uploadedImages.addAll(wordPressUrls));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: AppText(
                          title: "تم رفع ${wordPressUrls.length} صورة",
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: AppText(title: 'فشل رفع الصور')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: AppText(title: 'خطأ: $e')));
                }
              }
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: AppText(
              title: 'اختيار صور (${uploadedImages.length})',
              color: AppColors.primaryColor,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
            ),
          ),

          SizedBox(height: 8.h),

          if (uploadedImages.isNotEmpty)
            SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: uploadedImages.length,
                itemBuilder: (_, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(6.r),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            uploadedImages[index],
                            width: 100.w,
                            height: 100.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setModalState(() {
                              uploadedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          SizedBox(height: 16.h),

          // ملف PDF مع مؤشر التقدم
          const AppText(title: 'ملف PDF', fontWeight: FontWeight.bold),
          SizedBox(height: 8.h),

          if (isUploadingPdf)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              title: 'جاري رفع الملف...',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: 4.h),
                            AppText(
                              title: pdfFileName ?? '',
                              fontSize: 11,
                              color: Colors.white70,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  LinearProgressIndicator(
                    value: pdfUploadProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AppText(
                    title: '${(pdfUploadProgress * 100).toInt()}%',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ],
              ),
            )
          else if (pdfUrl != null && pdfUrl!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          title: 'تم رفع الملف بنجاح',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          title: pdfFileName ?? pdfUrl ?? '',
                          fontSize: 10,
                          color: Colors.white70,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setModalState(() {
                        pdfUrl = null;
                        pdfFileName = null;
                      });
                    },
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: isUploadingPdf
                  ? null
                  : () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        final fileSize = await file.length();

                        // Check file size before upload
                        if (fileSize > maxPdfSizeInBytes) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AppText(
                                title:
                                    'حجم الملف كبير جداً. الحد الأقصى ${(maxPdfSizeInBytes / (1024 * 1024)).toStringAsFixed(0)} ميجابايت',
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          return;
                        }

                        setModalState(() {
                          isUploadingPdf = true;
                          pdfFileName = result.files.single.name;
                          pdfUploadProgress = 0.0;
                        });

                        try {
                          // Upload with progress callback
                          final uploadedPdfUrl =
                              await WordPressMediaService.uploadPdf(
                                file,
                                onProgress: (progress) {
                                  if (context.mounted) {
                                    setModalState(() {
                                      pdfUploadProgress = progress;
                                    });
                                  }
                                },
                              );

                          if (!context.mounted) return;

                          if (uploadedPdfUrl != null &&
                              uploadedPdfUrl.isNotEmpty) {
                            setModalState(() {
                              pdfUrl = uploadedPdfUrl;
                              isUploadingPdf = false;
                              pdfUploadProgress = 1.0;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: AppText(title: 'تم رفع ملف PDF بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            throw Exception('فشل رفع الملف');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setModalState(() {
                              isUploadingPdf = false;
                              pdfFileName = null;
                              pdfUploadProgress = 0.0;
                            });

                            String errorMessage = 'فشل رفع ملف PDF';
                            if (e.toString().contains('403')) {
                              errorMessage =
                                  'خطأ في الصلاحيات. تحقق من إعدادات WordPress';
                            } else if (e.toString().contains('timeout')) {
                              errorMessage =
                                  'انتهت مهلة الرفع. حاول بملف أصغر حجماً';
                            } else if (e.toString().contains('413')) {
                              errorMessage = 'حجم الملف كبير جداً للخادم';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: AppText(title: errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      }
                    },
              icon: const Icon(Icons.picture_as_pdf),
              label: const AppText(
                title: 'اختيار ملف PDF',
                color: AppColors.primaryColor,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
              ),
            ),

          SizedBox(height: 16.h),

          LabeledField(
            label: 'الترتيب',
            controller: orderCtrl,
            keyboardType: TextInputType.number,
          ),

          GlassSwitchTile(
            title: 'إرسال إشعار للمستخدمين',
            subtitle: 'إعلام المستخدمين بالعمل الجديد',
            value: sendNotification,
            onChanged: (v) => setModalState(() => sendNotification = v),
          ),

          SizedBox(height: 16.h),

          GlassButton(
            onPressed: isUploadingPdf
                ? null
                : () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        bodyCtrl.text.trim().isEmpty ||
                        selectedIndustry == null ||
                        uploadedImages.isEmpty ||
                        pdfUrl == null ||
                        pdfUrl!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'يرجى ملء جميع الحقول وإضافة صور وملف PDF',
                          ),
                        ),
                      );
                      return;
                    }

                    final body = {
                      'title': titleCtrl.text.trim(),
                      'body': bodyCtrl.text.trim(),
                      'industry': selectedIndustry,
                      'order': int.tryParse(orderCtrl.text) ?? 1,
                      'images': uploadedImages,
                      'pdfUrl': pdfUrl,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    final col = FirebaseFirestore.instance.collection(
                      'portfolio',
                    );

                    try {
                      if (isEdit) {
                        await col
                            .doc(doc.id)
                            .set(body, SetOptions(merge: true));
                      } else {
                        body['createdAt'] = FieldValue.serverTimestamp();
                        await col.add(body);

                        if (sendNotification) {
                          await NotificationService.sendNotification(
                            title: '🎨 عمل جديد',
                            body:
                                '${titleCtrl.text.trim()} - $selectedIndustry',
                            deepLink: DeepLinkHandler.contractLink(pdfUrl!),
                          );
                        }
                      }

                      Navigator.pop(context);
                      Navigator.pop(context);
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: AppText(title: 'خطأ: $e')),
                      );
                    }
                  },
            child: Text(
              isUploadingPdf ? 'جاري الرفع...' : (isEdit ? 'حفظ' : 'إضافة'),
            ),
          ),
        ],
      ),
    ),
  );
}
