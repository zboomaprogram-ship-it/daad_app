
  import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> confirmDelete({
  required BuildContext context,
  required String collection,
  required String docId,
  String? title,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title ?? 'تأكيد الحذف'),
      content: const Text('هل أنت متأكد من الحذف؟ لا يمكن التراجع عن هذا الإجراء.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف بنجاح')),
      );
    }
  }
}