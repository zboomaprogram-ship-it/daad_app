
  import 'package:daad_app/core/widgets/app_text.dart';
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
      title:  AppText(title:title ?? 'تأكيد الحذف'),
      content: const  AppText(title:'هل أنت متأكد من الحذف؟ لا يمكن التراجع عن هذا الإجراء.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const  AppText(title:'إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const  AppText(title:'حذف'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:  AppText(title:'تم الحذف بنجاح')),
      );
    }
  }
}