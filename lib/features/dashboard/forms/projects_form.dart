import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/labeled_field.dart';

Future<void> showProjectForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};
  
  final titleCtrl = TextEditingController(text: data['title'] ?? '');
  final userIdCtrl = TextEditingController(text: data['userId'] ?? '');
  
  String status = (data['status'] ?? 'pending') as String;

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
                isEdit ? 'تعديل مشروع' : 'إضافة مشروع',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(label: 'عنوان المشروع', controller: titleCtrl),
              LabeledField(label: 'معرف المستخدم', controller: userIdCtrl),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'حالة المشروع',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('معلق')),
                  DropdownMenuItem(value: 'in_progress', child: Text('جاري العمل')),
                  DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                ],
                onChanged: (v) => setModalState(() => status = v ?? 'pending'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final body = {
                    'title': titleCtrl.text.trim(),
                    'userId': userIdCtrl.text.trim(),
                    'status': status,
                    'milestones': data['milestones'] ?? [],
                    'files': data['files'] ?? [],
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  final col = FirebaseFirestore.instance.collection('projects');
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