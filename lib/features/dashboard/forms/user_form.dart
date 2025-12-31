import 'dart:ui';

import 'package:daad_app/features/dashboard/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/labeled_field.dart';

Future<void> showUserForm(
  BuildContext context, {
  DocumentSnapshot? doc,
}) async {
  final isEdit = doc != null;
  final data = doc?.data() as Map<String, dynamic>;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7A4458).withOpacity(0.9),
                  const Color(0xFF5D3344).withOpacity(0.9),
                  const Color(0xFF4A2735).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['name'] ?? 'معلومات المستخدم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGlassInfoRow('📧 البريد', data['email'] ?? '-'),
                  _buildGlassInfoRow('📱 الهاتف', data['phone'] ?? '-'),
                  _buildGlassInfoRow('🏷️ الدور', data['role'] ?? 'client'),
                  _buildGlassInfoRow('⭐ النقاط', data['points']?.toString() ?? '0'),
                  _buildGlassInfoRow('🆔 ID', doc!.id),
                  _buildGlassInfoRow(
                    '📅 تاريخ التسجيل',
                    _formatTimestamp(data['createdAt']),
                  ),
                  _buildGlassInfoRow(
                    '🕐 آخر ظهور',
                    _formatTimestamp(data['lastSeenAt']),
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
Widget _buildGlassInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }
  return '-';
}