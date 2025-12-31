import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> openActivityForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};

  final titleController = TextEditingController(text: data['title'] ?? '');
  final typeController = TextEditingController(text: data['type'] ?? '');
  final pointsController =
      TextEditingController(text: (data['points'] ?? '').toString());

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
             AppText(title:
                isEdit ? 'تعديل النشاط' : 'إضافة نشاط',
             
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
              
              ),
              SizedBox(height: 12.h
),
              LabeledField(label: 'عنوان النشاط', controller: titleController),
              LabeledField(label: 'نوع النشاط', controller: typeController),
              LabeledField(
                label: 'النقاط',
                controller: pointsController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h
),
              ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final type = typeController.text.trim();
                  final points = int.tryParse(pointsController.text.trim()) ?? 0;

                  if (title.isEmpty || type.isEmpty) return;

                  final col = FirebaseFirestore.instance.collection('activities');
                  if (isEdit) {
                    await col.doc(doc.id).set({
                      'title': title,
                      'type': type,
                      'points': points,
                    }, SetOptions(merge: true));
                  } else {
                    await col.add({
                      'title': title,
                      'type': type,
                      'points': points,
                    });
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: AppText(title:isEdit ? 'حفظ' : 'إضافة'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
