  import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
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
                  isEdit ? 'تعديل خدمة' : 'إضافة خدمة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LabeledField(label: 'العنوان (عربي)', controller: titleAr),
                LabeledField(
                  label: 'الوصف (عربي)',
                  controller: descAr,
                  maxLines: 3,
                ),

                // Multiple Images Upload Section
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
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  title: const Text('مُفعل'),
                  value: isActive,
                  onChanged: (v) => setModalState(() => isActive = v),
                ),
                const Divider(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('السعر (Tier واحد افتراضي):'),
                ),
                LabeledField(
                  label: 'السعر',
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                ),
                LabeledField(
                  label: 'المميزات (مفصولة بفواصل)',
                  controller: featuresCsv,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final price = double.tryParse(priceCtrl.text.trim());
                    final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
                    final features = featuresCsv.text.trim().isEmpty
                        ? <String>[]
                        : featuresCsv.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                    final body = {
                      'title': titleAr.text.trim(),
                      'desc': descAr.text.trim(),
                      'images': uploadedImages, // Store multiple images
                      'isActive': isActive,
                      'order': order,
                      'priceTiers': [
                        {
                          'name': 'Basic',
                          'price': price ?? 0,
                          'features': features,
                        },
                      ],
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    final col = FirebaseFirestore.instance.collection(
                      'services',
                    );
                    if (isEdit) {
                      await col.doc(doc.id).set(body, SetOptions(merge: true));
                    } else {
                      body['createdAt'] = FieldValue.serverTimestamp();
                      await col.add(body);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }