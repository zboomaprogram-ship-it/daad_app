import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              Text(
                isEdit ? 'تعديل عرض' : 'إضافة عرض',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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
                title: const Text('مفعل'),
                value: isActive,
                onChanged: (v) => setModalState(() => isActive = v),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        startsAt == null
                            ? 'تاريخ البداية'
                            : 'من: ${startsAt!.toString().split(' ')[0]}',
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
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
              const SizedBox(height: 16),
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
                      SnackBar(content: Text(isEdit ? 'تم التحديث' : 'تم الإضافة')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'حفظ' : 'إضافة'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}