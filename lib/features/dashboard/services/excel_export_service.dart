import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'firebase_service.dart';

class ExcelExportService {
  static Future<void> exportUsersToExcel(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get users
      final users = await FirebaseService.getAllUsers();

      // Create Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['المستخدمون'];

      // Headers
      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('البريد الإلكتروني'),
        TextCellValue('الهاتف'),
        TextCellValue('الدور'),
        TextCellValue('النقاط'),
        TextCellValue('تاريخ التسجيل'),
      ]);

      // Data
      for (var user in users) {
        sheet.appendRow([
          TextCellValue(user['name']?.toString() ?? ''),
          TextCellValue(user['email']?.toString() ?? ''),
          TextCellValue((user['phone'] ?? '').toString()),
          TextCellValue(user['role']?.toString() ?? 'client'),
          TextCellValue((user['points'] ?? 0).toString()),
          TextCellValue(user['createdAt'] != null
              ? user['createdAt'].toDate().toString()
              : ''),
        ]);
      }
 // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/users_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Open the Excel file
      OpenFile.open(filePath);  // This will open the file in the default app

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'قائمة المستخدمين',
      );
    } catch (e) {
      if (context.mounted) {
        print('Error: $e');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}