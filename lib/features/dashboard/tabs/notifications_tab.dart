
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../forms/notification_form.dart';
import '../widgets/dashboard_tools.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد إشعارات بعد'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data() as Map<String, dynamic>;
              
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.orange),
                  title: Text(d['title'] ?? 'إشعار'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['body'] ?? ''),
                      if (d['userId'] != null)
                        Text('مستخدم محدد: ${d['userId']}',
                          style: const TextStyle(fontSize: 12)),
                      if (d['topic'] != null)
                        const Text('للجميع 📢',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => confirmDelete(
                      context: context,
                      collection: 'notifications',
                      docId: doc.id,
                      title: 'حذف إشعار',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNotificationForm(context),
        icon: const Icon(Icons.send),
        label: const Text('إرسال إشعار'),
      ),
    );
  }
}