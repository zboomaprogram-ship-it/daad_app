import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:daad_app/features/dashboard/widgets/colletion_tab_builder.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/dashboard_tools.dart';

class PortfolioTab extends StatelessWidget {
  const PortfolioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return buildCollectionTab(
      title: 'عمل',
      collection: 'portfolio',
      onAddPressed: () async {
        await _openDealForm(context, null); // For adding new portfolio item
      },
      tileBuilder: (doc) {
        final d = doc.data() as Map<String, dynamic>;
        final imageCount = d['images'] is List ? (d['images'] as List).length : 0;
        return Card(
          child: ListTile(
            title: Text(d['title'] ?? 'عمل'),
            subtitle: Text('قطاع: ${d['industry'] ?? '-'} • صور: $imageCount'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Icon
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    // Open the form for editing the existing portfolio item
                    await _openDealForm(context, doc);
                  },
                ),
                // Delete Icon
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(
                    context: context,
                    collection: 'portfolio',
                    docId: doc.id,
                    title: 'حذف عمل',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDealForm(BuildContext context, DocumentSnapshot? doc) async {
    final isEdit = doc != null;
    final titleAr = TextEditingController();
    final body = TextEditingController();
    final industry = TextEditingController();
    List<String> uploadedImages = [];
    final order = TextEditingController(text: '1');


    if (isEdit) {
      final data = doc.data() as Map<String, dynamic>;
      titleAr.text = data['title'] ?? '';
      body.text = data['body'] ?? '';
      industry.text = data['industry'] ?? '';
      uploadedImages = List<String>.from(data['images'] ?? []);
      order.text = data['order']?.toString() ?? '1';
    }

    await showModalBottomSheet(
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
                  isEdit ? 'تعديل عمل' : 'إضافة عمل',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                LabeledField(
                  label: 'العنوان',
                  controller: titleAr,
                ),
                LabeledField(
                  label: 'المحتوى (body)',
                  controller: body,
                ),
                LabeledField(
                  label: 'القطاع (industry)',
                  controller: industry,
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
                  label: 'الترتيب',
                  controller: order,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newPortfolioData = {
                      'title': titleAr.text.trim(),
                      'body': body.text.trim(),
                      'industry': industry.text.trim(),
                      'images': uploadedImages,
                      'featured': false,
                      'order': int.tryParse(order.text) ?? 1,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    final col = FirebaseFirestore.instance.collection('portfolio');
                    if (isEdit) {
                      // If it's an edit, update the document
                      await col.doc(doc.id).update(newPortfolioData);
                    } else {
                      // If it's a new portfolio item, add it
                      newPortfolioData['createdAt'] = FieldValue.serverTimestamp();
                      await col.add(newPortfolioData);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
