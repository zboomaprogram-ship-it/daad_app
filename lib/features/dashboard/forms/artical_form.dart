import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
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
                Text(
                  isEdit ? 'تعديل مقال' : 'إضافة مقال',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(label: 'العنوان (عربي)', controller: titleAr),
                LabeledField(
                  label: 'المحتوى (عربي)',
                  controller: bodyAr,
                  maxLines: 5,
                ),
                
                // Multiple Images Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final images = await ImagePicker().pickMultiImage();
                        if (images.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('جاري رفع الصور...')),
                          );

                          final base64Images = await uploadMultipleImages(images);

                          if (base64Images.isNotEmpty) {
                            setModalState(() {
                              uploadedImages.addAll(base64Images);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم رفع ${base64Images.length} صورة بنجاح'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('اختيار صور متعددة'),
                    ),
                    const SizedBox(height: 8),
                    if (uploadedImages.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: uploadedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Stack(
                                children: [
                                  Image.memory(
                                    base64Decode(uploadedImages[index]),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
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
                
                LabeledField(
                  label: 'وسوم (tags) مفصولة بفواصل',
                  controller: tagsCsv,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final tags = tagsCsv.text.trim().isEmpty
                        ? <String>[]
                        : tagsCsv.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                    final body = {
                      'title': titleAr.text.trim(),
                      'body': bodyAr.text.trim(),
                      'tags': tags,
                      'images': uploadedImages, // Store multiple images
                      'publishedAt': isEdit
                          ? (data['publishedAt'] ?? FieldValue.serverTimestamp())
                          : FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    final col = FirebaseFirestore.instance.collection('articles');
                    if (isEdit) {
                      await col.doc(doc.id).set(body, SetOptions(merge: true));
                    } else {
                      await col.add(body);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'حفظ' : 'نشر'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }