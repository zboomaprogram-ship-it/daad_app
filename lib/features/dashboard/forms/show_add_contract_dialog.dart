import 'dart:io';
import 'dart:ui';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/utils/services/deep_link_handler.dart';
import 'package:daad_app/features/dashboard/services/contract_service.dart';
import 'package:flutter/material.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showAddContractDialog(
  BuildContext context, {
  required String userId,
  required String userName,
  required String currentAdminId,
}) async {
  final titleController = TextEditingController();
  File? selectedFile;
  String? selectedFileName;
  bool isUploading = false;
  double uploadProgress = 0.0;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7A4458).withOpacity(0.9),
                    const Color(0xFF5D3344).withOpacity(0.9),
                    const Color(0xFF4A2735).withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AppText(
                            title: 'إضافة عقد لـ $userName',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Title field
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'عنوان العقد',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // File display area
                    if (isUploading)
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const AppText(
                                        title: 'جاري رفع الملف...',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      SizedBox(height: 4.h),
                                      AppText(
                                        title: selectedFileName ?? '',
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
                              value: uploadProgress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            AppText(
                              title: '${(uploadProgress * 100).toInt()}%',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      )
                    else if (selectedFile != null)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppText(
                                    title: 'تم اختيار الملف',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    title: selectedFileName ?? '',
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
                                setState(() {
                                  selectedFile = null;
                                  selectedFileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: () async {
                          final file =
                              await WordPressMediaService.pickPdfFile();
                          if (file != null) {
                            setState(() {
                              selectedFile = file;
                              selectedFileName = file.path.split('/').last;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.upload_file,
                                color: Colors.white,
                              ),
                              SizedBox(width: 12.w),
                              const AppText(
                                title: 'اختر ملف PDF',
                                fontSize: 14,
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 20.h),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isUploading
                              ? null
                              : () => Navigator.pop(context),
                          child: const AppText(title: 'إلغاء'),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF7A4458),
                          ),
                          onPressed:
                              selectedFile == null ||
                                  titleController.text.isEmpty ||
                                  isUploading
                              ? null
                              : () async {
                                  setState(() {
                                    isUploading = true;
                                    uploadProgress = 0.0;
                                  });

                                  try {
                                    // Simulate progress
                                    for (int i = 0; i <= 100; i += 10) {
                                      await Future.delayed(
                                        const Duration(milliseconds: 150),
                                      );
                                      if (context.mounted) {
                                        setState(() {
                                          uploadProgress = i / 100;
                                        });
                                      }
                                    }

                                    // Upload to WordPress
                                    final pdfUrl =
                                        await WordPressMediaService.uploadPdf(
                                          selectedFile!,
                                        );

                                    if (!context.mounted) return;

                                    if (pdfUrl != null) {
                                      // Add to Firestore
                                      await ContractService.addContractToUser(
                                        userId: userId,
                                        title: titleController.text,
                                        pdfUrl: pdfUrl,
                                        uploadedBy: currentAdminId,
                                      );

                                      // Send notification
                                      await NotificationService.sendNotification(
                                        title: '📄 عقد جديد متاح',
                                        body:
                                            'تم إضافة عقد جديد: ${titleController.text}',
                                        userId: userId,
                                        deepLink: DeepLinkHandler.contractLink(
                                          pdfUrl,
                                        ),
                                      );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: AppText(
                                              title:
                                                  'تم إضافة العقد وإرسال الإشعار بنجاح',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else {
                                      throw Exception('فشل رفع الملف');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: AppText(title: 'خطأ: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setState(() => isUploading = false);
                                    }
                                  }
                                },
                          child: AppText(
                            title: isUploading ? 'جاري الرفع...' : 'إضافة',
                            color: const Color(0xFF7A4458),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
