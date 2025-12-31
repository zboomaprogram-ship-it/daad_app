import 'package:daad_app/features/dashboard/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/labeled_field.dart';

Future<void> showPortfolioForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = (doc?.data() as Map<String, dynamic>?) ?? {};
  
  final titleCtrl = TextEditingController(text: data['title'] ?? '');
  final bodyCtrl = TextEditingController(text: data['body'] ?? '');
  final industryCtrl = TextEditingController(text: data['industry'] ?? '');
  final orderCtrl = TextEditingController(text: (data['order'] ?? 1).toString());
  
  bool featured = (data['featured'] ?? false) as bool;

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
          LabeledField(label: 'القطاع/المجال', controller: industryCtrl),
          LabeledField(
            label: 'الترتيب',
            controller: orderCtrl,
            keyboardType: TextInputType.number,
          ),
          GlassSwitchTile(
            title: 'عمل مميز',
            value: featured,
            onChanged: (v) => setModalState(() => featured = v),
          ),
          const SizedBox(height: 16),
          GlassButton(
            onPressed: () async {
              final body = {
                'title': titleCtrl.text.trim(),
                'body': bodyCtrl.text.trim(),
                'industry': industryCtrl.text.trim(),
                'order': int.tryParse(orderCtrl.text) ?? 1,
                'featured': featured,
                'images': data['images'] ?? [],
                'updatedAt': FieldValue.serverTimestamp(),
              };

              final col = FirebaseFirestore.instance.collection('portfolio');
              if (isEdit) {
                await col.doc(doc.id).set(body, SetOptions(merge: true));
              } else {
                body['createdAt'] = FieldValue.serverTimestamp();
                await col.add(body);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'تم التحديث' : 'تم الإضافة'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, size: 20),
                const SizedBox(width: 8),
                Text(isEdit ? 'حفظ' : 'إضافة'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}