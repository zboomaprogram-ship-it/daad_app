import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/features/dashboard/widgets/user_info_dilag.dart';
import 'package:flutter/material.dart';
import '../forms/user_form.dart';
import '../services/firebase_service.dart';
import '../services/excel_export_service.dart';


class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _searchQuery = '';
  String _roleFilter = 'all';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // شريط البحث والفلاتر
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'بحث عن مستخدم...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _roleFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'client', child: Text('عميل')),
                    DropdownMenuItem(value: 'admin', child: Text('مسؤول')),
                  ],
                  onChanged: (value) {
                    setState(() => _roleFilter = value ?? 'all');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'تصدير إلى Excel',
                  onPressed: () async {
                    await ExcelExportService.exportUsersToExcel(context);
                  },
                ),
              ],
            ),
          ),
          
          // عرض المستخدمين
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('lastSeenAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];
                
                // تطبيق الفلاتر
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final role = data['role'] ?? 'client';
                  
                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                  
                  final matchesRole = _roleFilter == 'all' || role == _roleFilter;
                  
                  return matchesSearch && matchesRole;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (data['name']?.isNotEmpty ?? false) 
                                ? (data['name'] ?? 'U')[0].toUpperCase() 
                                : 'U', // Fallback to 'U' if name is empty or null
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'مستخدم',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📧 ${data['email'] ?? '-'}'),
                            Text('📱 ${data['phone'] ?? '-'}'),
                            Text('🏷️ ${_getRoleLabel(data['role'])}'),
                            Text('⭐ نقاط: ${data['points'] ?? 0}'),
                            Text('📅 آخر زيارة: ${data['lastSeenAt']?.toDate().toString() ?? '-'}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'info',
                              child: Row(
                                children: [
                                  Icon(Icons.info),
                                  SizedBox(width: 8),
                                  Text('معلومات كاملة'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'role',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings),
                                  SizedBox(width: 8),
                                  Text('تغيير الدور'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'info':
                                showUserInfoDialog(context, doc);
                                break;
                              case 'edit':
                                showUserForm(context, doc: doc);
                                break;
                              case 'role':
                                _showChangeRoleDialog(context, doc);
                                break;
                              case 'delete':
                                _confirmDelete(context, doc);
                                break;
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUserForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مستخدم'),
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'مسؤول 👨‍💼';
      case 'client':
        return 'عميل 👤';
      default:
        return 'غير محدد';
    }
  }

  Future<void> _showChangeRoleDialog(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    String currentRole = data['role'] ?? 'client';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير دور المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('عميل'),
              value: 'client',
              groupValue: currentRole,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('مسؤول'),
              value: 'admin',
              groupValue: currentRole,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != currentRole) {
      await FirebaseService.updateUserRole(doc.id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الدور بنجاح')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا المستخدم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await doc.reference.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستخدم')),
        );
      }
    }
  }
}
