import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/labeled_field.dart';

Future<void> showBookingForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};
  
  final userIdCtrl = TextEditingController(text: data['userId'] ?? '');
  final notesCtrl = TextEditingController(text: data['notes'] ?? '');
  
  String type = (data['type'] ?? 'strategy_call') as String;
  String status = (data['status'] ?? 'pending') as String;
  DateTime? datetime = (data['datetime'] is Timestamp)
      ? (data['datetime'] as Timestamp).toDate()
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
                isEdit ? 'تعديل حجز' : 'إضافة حجز',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(label: 'معرف المستخدم', controller: userIdCtrl),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'نوع الحجز',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'strategy_call',
                    child: Text('استشارة استراتيجية'),
                  ),
                  DropdownMenuItem(
                    value: 'consultation',
                    child: Text('استشارة عامة'),
                  ),
                ],
                onChanged: (v) => setModalState(() => type = v ?? 'strategy_call'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('معلق')),
                  DropdownMenuItem(value: 'confirmed', child: Text('مؤكد')),
                  DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                  DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                ],
                onChanged: (v) => setModalState(() => status = v ?? 'pending'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  datetime == null
                      ? 'اختر تاريخ ووقت الحجز'
                      : 'الموعد: ${datetime.toString().split('.')[0]}',
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: datetime ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(datetime ?? DateTime.now()),
                    );
                    if (time != null) {
                      setModalState(() {
                        datetime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              LabeledField(
                label: 'ملاحظات',
                controller: notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final body = {
                    'userId': userIdCtrl.text.trim(),
                    'type': type,
                    'status': status,
                    'datetime': datetime != null 
                        ? Timestamp.fromDate(datetime!) 
                        : FieldValue.serverTimestamp(),
                    'notes': notesCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  final col = FirebaseFirestore.instance.collection('bookings');
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