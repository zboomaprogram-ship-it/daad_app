import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/labeled_field.dart';

Future<void> showDealForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};
  
  final labelCtrl = TextEditingController(text: data['label'] ?? '');
  final codeCtrl = TextEditingController(text: data['code'] ?? '');
  final discountCtrl = TextEditingController(
    text: (data['discountPercent'] ?? '').toString(),
  );
  final weightCtrl = TextEditingController(
    text: (data['weight'] ?? 1).toString(),
  );
  
  bool isActive = (data['isActive'] ?? true) as bool;
  DateTime? startsAt = (data['startsAt'] is Timestamp)
      ? (data['startsAt'] as Timestamp).toDate()
      : null;
  DateTime? endsAt = (data['endsAt'] is Timestamp)
      ? (data['endsAt'] as Timestamp).toDate()
      : null;

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
              AppText(title:
                isEdit ? 'تعديل عرض' : 'إضافة عرض',
                
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
          
              ),
              SizedBox(height: 16.h
),
              LabeledField(label: 'التسمية', controller: labelCtrl),
              LabeledField(label: 'كود الخصم', controller: codeCtrl),
              LabeledField(
                label: 'نسبة الخصم %',
                controller: discountCtrl,
                keyboardType: TextInputType.number,
              ),
              LabeledField(
                label: 'الوزن (احتمالية الظهور)',
                controller: weightCtrl,
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: AppText(title:'مفعل'),
                value: isActive,
                onChanged: (v) => setModalState(() => isActive = v),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: AppText(title:
                        startsAt == null
                            ? 'تاريخ البداية'
                            : 'من: ${startsAt!.toString().split(' ')[0]}'
                            ,color: AppColors.primaryColor,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startsAt ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => startsAt = picked);
                        }
                      },
                    ),
                  ),
                    SizedBox(width: 8.w
),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label:AppText(title:
                        endsAt == null
                            ? 'تاريخ النهاية'
                            : 'إلى: ${endsAt!.toString().split(' ')[0]}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endsAt ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => endsAt = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h
),
              ElevatedButton.icon(
                onPressed: () async {
                  final body = {
                    'label': labelCtrl.text.trim(),
                    'code': codeCtrl.text.trim(),
                    'discountPercent': double.tryParse(discountCtrl.text) ?? 0,
                    'weight': int.tryParse(weightCtrl.text) ?? 1,
                    'isActive': isActive,
                    'startsAt': startsAt != null 
                        ? Timestamp.fromDate(startsAt!) 
                        : null,
                    'endsAt': endsAt != null 
                        ? Timestamp.fromDate(endsAt!) 
                        : null,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  final col = FirebaseFirestore.instance.collection('deals_wheel');
                  if (isEdit) {
                    await col.doc(doc.id).set(body, SetOptions(merge: true));
                  } else {
                    body['createdAt'] = FieldValue.serverTimestamp();
                    await col.add(body);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: AppText(title:isEdit ? 'تم التحديث' : 'تم الإضافة')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: AppText(title:isEdit ? 'حفظ' : 'إضافة',color: AppColors.primaryColor,),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}