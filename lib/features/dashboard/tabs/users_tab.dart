import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_loading_indicator.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/presentation/user_contracts_screen.dart';
import 'package:daad_app/features/dashboard/forms/show_add_contract_dialog.dart';
import 'package:daad_app/features/dashboard/forms/show_add_package_dialog.dart';
import 'package:daad_app/features/dashboard/forms/show_user_info_dialog.dart';
import 'package:daad_app/features/dashboard/widgets/points_history_dialog.dart';
import 'package:daad_app/features/auth/presentation/user_packages_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  // Removed Pagination for Admin to allow Search to work correctly
  List<DocumentSnapshot> _users = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  String? _currentUserRole;
  List<String> _assignedUserIds = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      _currentUserId = user.uid;
      _currentUserRole = userDoc.data()?['role'] ?? 'client';

      if (_currentUserRole == 'sales') {
        _assignedUserIds = List<String>.from(
            userDoc.data()?['assignedUsers'] ?? []
        );
      }
    });

    _loadUsers();
  }

  // ✅ FIX: Load users robustly without strict pagination for Admin
  Future<void> _loadUsers() async {
    if (_isLoading || _currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      List<DocumentSnapshot> loadedDocs = [];

      if (_currentUserRole == 'sales') {
        // --- SALES LOGIC ---
        if (_assignedUserIds.isEmpty) {
          setState(() { _users = []; _isLoading = false; });
          return;
        }

        // Batch load assigned users (Firestore limit 10 per batch)
        final batchSize = 10;
        for (int i = 0; i < _assignedUserIds.length; i += batchSize) {
          final batch = _assignedUserIds.skip(i).take(batchSize).toList();
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          loadedDocs.addAll(snapshot.docs);
        }
      } else {
        // --- ADMIN LOGIC (FIXED) ---
        // 1. Removed 'limit(10)' -> Fetches all so Search works.
        // 2. Removed 'orderBy(lastSeenAt)' -> Fixes missing Admins.
        
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            // You can uncomment this if you are SURE all users have createdAt
            // .orderBy('createdAt', descending: true) 
            .get();

        loadedDocs = snapshot.docs;
      }

      if (mounted) {
        setState(() {
          _users = loadedDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DocumentSnapshot> _getFilteredUsers() {
    return _users.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = data['role'] ?? 'client';

      final matchesSearch =
          _searchQuery.isEmpty ||
              name.contains(_searchQuery) ||
              email.contains(_searchQuery);

      final matchesRole = _roleFilter == 'all' || role == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  // ... (Keep existing _showPointsDialog, _showAssignToSalesDialog, etc.)
  // I will include the manage clients dialog here for completeness

Future<void> _showManageAssignedClientsDialog(
      BuildContext context,
      String salesId,
      List<String> currentAssignedIds,
      ) async {
    
    // ✅ FIX: Removed .where('role', isEqualTo: 'client') to show EVERYONE (Admins included)
    final allUsersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    if (!mounted) return;

    // Filter out the Sales Agent themselves (prevent assigning themselves)
    List<DocumentSnapshot> allUsers = allUsersSnapshot.docs
        .where((doc) => doc.id != salesId)
        .toList();
        
    List<String> selectedIds = List.from(currentAssignedIds);
    String dialogSearchQuery = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Filter based on search text
            final filteredUsers = allUsers.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              final role = (data['role'] ?? 'client').toString().toLowerCase(); // Optional: Search by role too
              
              final query = dialogSearchQuery.toLowerCase();
              
              return name.contains(query) || 
                     email.contains(query) || 
                     role.contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
              title: const AppText(title: 'إدارة المستخدمين المعينين'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400.h,
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'بحث (اسم، ايميل، أو دور)...',
                        hintStyle: TextStyle(color: Colors.white60),
                        prefixIcon: Icon(Icons.search, color: Colors.white60),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          dialogSearchQuery = val;
                        });
                      },
                    ),
                    SizedBox(height: 10.h),
                    // List
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? const Center(child: AppText(title: 'لا يوجد مستخدمين'))
                          : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final doc = filteredUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isSelected = selectedIds.contains(doc.id);
                          
                          // Show Role Label next to name
                          String roleLabel = '';
                          if (data['role'] == 'admin') roleLabel = ' (Admin)';
                          if (data['role'] == 'sales') roleLabel = ' (Sales)';

                          return CheckboxListTile(
                            side: const BorderSide(color: Colors.white),
                            activeColor: AppColors.primaryColor,
                            checkColor: Colors.white,
                            title: Row(
                              children: [
                                AppText(
                                  title: (data['name'] ?? 'مستخدم') + roleLabel,
                                  fontSize: 14,
                                  color: data['role'] == 'admin' ? Colors.amber : Colors.white, // Highlight Admins
                                ),
                              ],
                            ),
                            subtitle: AppText(
                              title: data['email'] ?? '',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  selectedIds.add(doc.id);
                                } else {
                                  selectedIds.remove(doc.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const AppText(title: 'إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(salesId)
                          .update({
                        'assignedUsers': selectedIds,
                      });
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: AppText(title: 'تم تحديث القائمة بنجاح')),
                        );
                        _loadUsers(); // Refresh main list
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: AppText(title: 'خطأ: $e')),
                        );
                      }
                    }
                  },
                  child: const AppText(title: 'حفظ التغييرات'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper dialogs needed for the UI
  Future<void> _showPointsDialog(BuildContext context, String userId) async {
    int change = 0;
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: const AppText(title: 'تعديل النقاط'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textColor),
              decoration: const InputDecoration(labelText: 'عدد النقاط (+/-)', labelStyle: TextStyle(color: AppColors.textColor)),
              onChanged: (v) => change = int.tryParse(v) ?? 0,
            ),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textColor),
              decoration: const InputDecoration(labelText: 'السبب', labelStyle: TextStyle(color: AppColors.textColor)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const AppText(title: 'إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (change != 0) {
                await FirebaseService.updateUserPoints(userId: userId, change: change, reason: reasonController.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const AppText(title: 'حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignToSalesDialog(BuildContext context, String userId, String userName) async {
    final salesUsers = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'sales').get();
    if (!mounted) return;
    if (salesUsers.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText(title: 'لا يوجد مندوبي مبيعات')));
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: const AppText(title: 'اختر مندوب المبيعات'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: salesUsers.docs.length,
            itemBuilder: (context, index) {
              final sales = salesUsers.docs[index];
              return ListTile(
                title: AppText(title: sales.data()['name'] ?? 'مندوب'),
                subtitle: AppText(title: sales.data()['email'] ?? ''),
                onTap: () => Navigator.pop(context, sales.id),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null) {
      await FirebaseFirestore.instance.collection('users').doc(selected).update({'assignedUsers': FieldValue.arrayUnion([userId])});
      if (mounted) _loadUsers();
    }
  }

  Future<void> _showChangeRoleDialog(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    String currentRole = data['role'] ?? 'client';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
        title: const AppText(title: 'تغيير الدور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['client', 'sales', 'admin'].map((role) => RadioListTile<String>(
            title: AppText(title: role),
            value: role,
            groupValue: currentRole,
            onChanged: (v) => Navigator.pop(context, v),
          )).toList(),
        ),
      ),
    );
    if (result != null && result != currentRole) {
      await FirebaseService.updateUserRole(doc.id, result);
      if (result == 'sales') await FirebaseFirestore.instance.collection('users').doc(doc.id).update({'assignedUsers': []});
      if (mounted) _loadUsers();
    }
  }

  Future<void> _confirmDelete(BuildContext context, DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: const AppText(title: 'تأكيد الحذف'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const AppText(title: 'إلغاء')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const AppText(title: 'حذف')),
        ],
      ),
    );
    if (confirmed == true) {
      await doc.reference.delete();
      setState(() { _users.removeWhere((u) => u.id == doc.id); });
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin': return 'مسؤول 👨‍💼';
      case 'sales': return 'مبيعات 💼';
      case 'client': return 'عميل 👤';
      default: return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();
    final isAdmin = _currentUserRole == 'admin';
    final isSales = _currentUserRole == 'sales';

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0.r),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'بحث عن مستخدم...',
                      hintStyle: TextStyle(color: AppColors.textColor),
                      prefixIcon: Icon(Icons.search, color: AppColors.textColor),
                      border: UnderlineInputBorder(borderSide: BorderSide.none),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                if (isAdmin) ...[
                  DropdownButton<String>(
                    dropdownColor: AppColors.secondaryColor.withOpacity(0.2),
                    iconEnabledColor: AppColors.textColor,
                    value: _roleFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: AppText(title: 'الكل')),
                      DropdownMenuItem(value: 'client', child: AppText(title: 'عميل')),
                      DropdownMenuItem(value: 'admin', child: AppText(title: 'مسؤول')),
                      DropdownMenuItem(value: 'sales', child: AppText(title: 'مبيعات')),
                    ],
                    onChanged: (value) => setState(() => _roleFilter = value ?? 'all'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'تصدير Excel',
                    onPressed: () => ExcelExportService.exportUsersToExcel(context),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isSales ? Icons.people_outline : Icons.search_off, size: 64, color: Colors.white38),
                        SizedBox(height: 16.h),
                        AppText(title: isSales ? 'لا يوجد عملاء' : 'لا توجد نتائج', color: Colors.white60),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8.r),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final doc = filteredUsers[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        color: AppColors.secondaryColor.withOpacity(0.2),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor,
                            child: AppText(title: (data['name'] ?? 'U')[0].toUpperCase()),
                          ),
                          title: AppText(title: data['name'] ?? 'مستخدم', fontWeight: FontWeight.bold),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(title: '📧 ${data['email'] ?? '-'}'),
                              AppText(title: '📱 ${data['phone'] ?? '-'}'),
                              if (isAdmin) AppText(title: '🏷️ ${_getRoleLabel(data['role'])}'),
                              AppText(title: '⭐ نقاط: ${data['points'] ?? 0}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            color: AppColors.secondaryColor.withOpacity(0.9),
                            iconColor: AppColors.textColor,
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'info', child: AppText(title: 'معلومات كاملة')),
                              if (isAdmin && data['role'] == 'sales')
                                const PopupMenuItem(value: 'manage-clients', child: AppText(title: 'إدارة العملاء')),
                              if (isAdmin && data['role'] != 'sales')
                                const PopupMenuItem(value: 'assign-sales', child: AppText(title: 'تعيين لمندوب')),
                              const PopupMenuItem(value: 'contracts', child: AppText(title: 'العقود')),
                              const PopupMenuItem(value: 'add-contract', child: AppText(title: 'إضافة عقد')),
                              const PopupMenuItem(value: 'points', child: AppText(title: 'إدارة النقاط')),
                              const PopupMenuItem(value: 'history', child: AppText(title: 'سجل النقاط')),
                              const PopupMenuItem(value: 'packages', child: AppText(title: 'الباقات')),
                              const PopupMenuItem(value: 'add-package', child: AppText(title: 'إضافة باقة')),
                              if (isAdmin) ...[
                                const PopupMenuItem(value: 'role', child: AppText(title: 'تغيير الدور')),
                                const PopupMenuItem(value: 'delete', child: AppText(title: 'حذف', color: Colors.red)),
                              ],
                            ],
                            onSelected: (value) {
                              if (value == 'info') showUserInfoDialog(context, doc, isAdmin: isAdmin, currentUserId: _currentUserId ?? '');
                              if (value == 'manage-clients') {
                                List<String> current = List<String>.from(data['assignedUsers'] ?? []);
                                _showManageAssignedClientsDialog(context, doc.id, current);
                              }
                              if (value == 'assign-sales') _showAssignToSalesDialog(context, doc.id, data['name'] ?? '');
                              if (value == 'contracts') Navigator.push(context, MaterialPageRoute(builder: (_) => UserContractsScreen(userId: doc.id, userName: data['name'] ?? '', isAdmin: isAdmin || isSales)));
                              if (value == 'add-contract') showAddContractDialog(context, userId: doc.id, userName: data['name'] ?? '', currentAdminId: _currentUserId ?? '');
                              if (value == 'points') _showPointsDialog(context, doc.id);
                              if (value == 'history') showPointsHistoryDialog(context, doc.id);
                              if (value == 'packages') Navigator.push(context, MaterialPageRoute(builder: (_) => UserPackagesScreen(userId: doc.id, userName: data['name'] ?? '', isAdmin: isAdmin || isSales)));
                              if (value == 'add-package') showAddPackageDialog(context, userId: doc.id, userName: data['name'] ?? '', currentAdminId: _currentUserId ?? '');
                              if (value == 'role') _showChangeRoleDialog(context, doc);
                              if (value == 'delete') _confirmDelete(context, doc);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}