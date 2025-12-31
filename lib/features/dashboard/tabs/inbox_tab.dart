import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  final TextEditingController _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inbox')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          
          final messages = snapshot.data?.docs ?? [];
          
          if (messages.isEmpty) {
            return const Center(child: Text('لا توجد رسائل'));
          }
          
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final doc = messages[index];
              final message = doc.data() as Map<String, dynamic>;
              final status = message['status'] ?? 'pending';
              final adminResponse = message['adminResponse'] ?? '';
              final createdAt = message['createdAt'] as Timestamp?;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  leading: Icon(
                    status == 'تم الرد' ? Icons.check_circle : Icons.pending,
                    color: status == 'تم الرد' ? Colors.green : Colors.orange,
                  ),
                  title: Text(message['message'] ?? 'رسالة'),
                  subtitle: Text(
                    'من: ${message['userName'] ?? 'مستخدم'}\n'
                    'تاريخ: ${createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate()) : '-'}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (adminResponse.isNotEmpty) ...[
                            const Text(
                              'رد المسؤول:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(adminResponse),
                            const Divider(),
                          ],
                          if (status != 'تم الرد')
                            ElevatedButton.icon(
                              onPressed: () => _openResponseForm(context, doc.id),
                              icon: const Icon(Icons.reply),
                              label: const Text('الرد على الرسالة'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openResponseForm(BuildContext context, String messageId) async {
    _responseController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          right: 16,
          left: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'رد المسؤول',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              decoration: const InputDecoration(
                labelText: 'الرد على الرسالة',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (_responseController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('inbox')
                      .doc(messageId)
                      .update({
                    'status': 'تم الرد',
                    'adminResponse': _responseController.text.trim(),
                    'answeredAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال الرد بنجاح')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('إرسال الرد'),
            ),
          ],
        ),
      ),
    );
  }
}