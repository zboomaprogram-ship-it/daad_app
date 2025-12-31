import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

import 'firebase_service.dart';

class ExcelExportService {
  static Future<void> exportUsersToExcel(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get users (List<Map<String, dynamic>>)
      final users = await FirebaseService.getAllUsers();

      // ✅ Collect ALL keys from all users + flatten socialLinks.*
      final Set<String> columnsSet = {};
      for (final user in users) {
        for (final key in user.keys) {
          if (key == 'socialLinks' && user['socialLinks'] is Map) {
            final map = Map<String, dynamic>.from(user['socialLinks'] as Map);
            for (final sk in map.keys) {
              columnsSet.add('socialLinks.$sk');
            }
          } else {
            columnsSet.add(key.toString());
          }
        }
      }

      // ✅ Stable/clean column order (put common fields first, then the rest)
      final preferredOrder = <String>[
        'uid',
        'name',
        'email',
        'phone',
        'role',
        'points',
        'isDaadClient',
        'address',
        'city',
        'storelink',
        'photoURL',
        'createdAt',
        'updatedAt',
        'lastSeenAt',
      ];

      final columns = <String>[
        ...preferredOrder.where(columnsSet.contains),
        ...columnsSet.difference(preferredOrder.toSet()).toList()..sort(),
      ];

      // Create Excel
      final excel = Excel.createExcel();
      final Sheet sheet = excel['المستخدمون'];

      // Headers
      sheet.appendRow(columns.map((c) => TextCellValue(c)).toList());

      // Rows
      for (final user in users) {
        final map = Map<String, dynamic>.from(user);

        // flatten socialLinks.* into a flat map
        final flat = <String, dynamic>{...map};
        final social = map['socialLinks'];
        if (social is Map) {
          final socialMap = Map<String, dynamic>.from(social);
          for (final e in socialMap.entries) {
            flat['socialLinks.${e.key}'] = e.value;
          }
        }
        flat.remove('socialLinks'); // keep only the flattened version

        sheet.appendRow(
          columns.map((col) {
            final value = _readValueForColumn(flat, col);
            return TextCellValue(value);
          }).toList(),
        );
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/users_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final file = File(filePath);
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel file');
      await file.writeAsBytes(bytes);

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Open file
      await OpenFile.open(filePath);

      // Share file
      // await Share.shareXFiles(
      //   [XFile(filePath)],
      //   text: 'قائمة المستخدمين',
      // );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(title: 'خطأ: $e')),
        );
      }
    }
  }

  /// ✅ Read value by column name (supports flattened paths like socialLinks.facebook)
  static String _readValueForColumn(Map<String, dynamic> user, String column) {
    dynamic value;

    // If column has dot path (already flattened, but keep safe)
    if (column.contains('.')) {
      value = user[column]; // because we flattened to keys like socialLinks.facebook
    } else {
      value = user[column];
    }

    return _stringify(value);
  }

  /// ✅ Convert any value (Timestamp/Map/List/etc) to clean string for Excel
  static String _stringify(dynamic v) {
    if (v == null) return '';

    if (v is Timestamp) {
      // local string (you can format it as you like)
      return v.toDate().toIso8601String();
    }

    if (v is DateTime) return v.toIso8601String();

    if (v is bool || v is num) return v.toString();

    if (v is List) {
      try {
        return jsonEncode(v);
      } catch (_) {
        return v.join(', ');
      }
    }

    if (v is Map) {
      try {
        return jsonEncode(v);
      } catch (_) {
        return v.toString();
      }
    }

    return v.toString();
  }
}
