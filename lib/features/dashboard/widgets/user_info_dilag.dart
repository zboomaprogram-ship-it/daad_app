import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void showUserInfoDialog(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(data['name'] ?? 'معلومات المستخدم'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('📧 البريد', data['email'] ?? '-'),
            _buildInfoRow('📱 الهاتف', data['phone'] ?? '-'),
            _buildInfoRow('🏷️ الدور', data['role'] ?? 'client'),
            _buildInfoRow('⭐ النقاط', data['points']?.toString() ?? '0'),
            _buildInfoRow('🆔 ID', doc.id),
            _buildInfoRow(
              '📅 تاريخ التسجيل',
              _formatTimestamp(data['createdAt']),
            ),
            _buildInfoRow(
              '🕐 آخر ظهور',
              _formatTimestamp(data['lastSeenAt']),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }
  return '-';
}