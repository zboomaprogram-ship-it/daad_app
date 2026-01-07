// ============================================
// ADD TO USERS TAB - SALES ASSIGNMENT DIALOG
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Add this to your UsersTab PopupMenu
// PopupMenuItem(
//   value: 'assign-sales',
//   child: Row(
//     children: [
//       Icon(Icons.person_add),
//       SizedBox(width: 8.w),
//       AppText(title: 'تعيين مندوب مبيعات'),
//     ],
//   ),
// ),

// Add this case to the onSelected handler in UsersTab:
// case 'assign-sales':
//   _showAssignSalesDialog(context, doc.id, data['name'] ?? 'مستخدم');
//   break;

Future<void> showAssignSalesDialog(
  BuildContext context,
  String userId,
  String userName,
) async {
  // Get all sales users
  final salesSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'sales')
      .get();

  if (!context.mounted) return;

  // Get current assignment
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  final currentSalesId = userDoc.data()?['assignedSalesId'];

  String? selectedSalesId = currentSalesId;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: AppText(title: 'تعيين مندوب مبيعات لـ $userName', fontSize: 16),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (salesSnapshot.docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: AppText(
                    title: 'لا يوجد مندوبي مبيعات',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...salesSnapshot.docs.map((doc) {
                  final data = doc.data();
                  final salesName = data['name'] ?? 'مندوب';
                  final salesEmail = data['email'] ?? '';

                  return RadioListTile<String>(
                    title: AppText(title: salesName),
                    subtitle: AppText(
                      title: salesEmail,
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    value: doc.id,
                    groupValue: selectedSalesId,
                    activeColor: AppColors.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        selectedSalesId = value;
                      });
                    },
                  );
                }),
              if (currentSalesId != null) ...[
                const Divider(),
                ListTile(
                  title: const AppText(
                    title: 'إلغاء التعيين',
                    color: Colors.red,
                  ),
                  leading: const Icon(Icons.clear, color: Colors.red),
                  onTap: () {
                    setState(() {
                      selectedSalesId = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(title: 'إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            onPressed: () async {
              try {
                if (selectedSalesId == null && currentSalesId != null) {
                  // Remove assignment
                  await FirebaseService.removeUserFromSales(
                    userId: userId,
                    salesId: currentSalesId,
                  );
                } else if (selectedSalesId != null) {
                  // Remove old assignment if exists
                  if (currentSalesId != null &&
                      currentSalesId != selectedSalesId) {
                    await FirebaseService.removeUserFromSales(
                      userId: userId,
                      salesId: currentSalesId,
                    );
                  }

                  // Add new assignment
                  final salesDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(selectedSalesId)
                      .get();

                  await FirebaseService.assignUserToSales(
                    userId: userId,
                    salesId: selectedSalesId!,
                    salesName: salesDoc.data()?['name'] ?? 'مندوب',
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: AppText(title: 'تم التحديث بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText(title: 'خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const AppText(title: 'حفظ'),
          ),
        ],
      ),
    ),
  );
}

// ============================================
// FIREBASE SERVICE ADDITIONS
// ============================================

class FirebaseService {
  // Assign user to sales representative
  static Future<void> assignUserToSales({
    required String userId,
    required String salesId,
    required String salesName,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // Update user document
    batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
      'assignedSalesId': salesId,
      'assignedSalesName': salesName,
      'assignedAt': FieldValue.serverTimestamp(),
    });

    // Update sales document - add to assigned users array
    batch.update(FirebaseFirestore.instance.collection('users').doc(salesId), {
      'assignedUsers': FieldValue.arrayUnion([userId]),
    });

    // Update existing support chat if exists
    final chatQuery = await FirebaseFirestore.instance
        .collection('support_chats')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      batch.update(chatQuery.docs.first.reference, {
        'assignedSalesId': salesId,
        'assignedSalesName': salesName,
      });
    }

    await batch.commit();
  }

  // Remove user from sales representative
  static Future<void> removeUserFromSales({
    required String userId,
    required String salesId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // Update user document
    batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
      'assignedSalesId': FieldValue.delete(),
      'assignedSalesName': FieldValue.delete(),
      'assignedAt': FieldValue.delete(),
    });

    // Update sales document - remove from assigned users array
    batch.update(FirebaseFirestore.instance.collection('users').doc(salesId), {
      'assignedUsers': FieldValue.arrayRemove([userId]),
    });

    // Update support chat
    final chatQuery = await FirebaseFirestore.instance
        .collection('support_chats')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      batch.update(chatQuery.docs.first.reference, {
        'assignedSalesId': FieldValue.delete(),
        'assignedSalesName': FieldValue.delete(),
      });
    }

    await batch.commit();
  }

  // Update existing methods to include role management
  static Future<void> updateUserRole(String userId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If changing from sales role, remove all assignments
    if (newRole != 'sales') {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final assignedUsers = userDoc.data()?['assignedUsers'] as List?;

      if (assignedUsers != null && assignedUsers.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        for (final assignedUserId in assignedUsers) {
          batch.update(
            FirebaseFirestore.instance.collection('users').doc(assignedUserId),
            {
              'assignedSalesId': FieldValue.delete(),
              'assignedSalesName': FieldValue.delete(),
              'assignedAt': FieldValue.delete(),
            },
          );
        }

        batch.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {'assignedUsers': FieldValue.delete()},
        );

        await batch.commit();
      }
    }
  }

  // Existing method - update user points
  static Future<void> updateUserPoints({
    required String userId,
    required int change,
    required String reason,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // Update user points
    batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
      'points': FieldValue.increment(change),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add to points history
    batch.set(
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('points_history')
          .doc(),
      {
        'change': change,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'adminId': FirebaseAuth.instance.currentUser?.uid,
      },
    );

    await batch.commit();
  }
}

// ============================================
// UPDATE CONTACT SCREEN (USER SIDE)
// ============================================

// When user creates a support chat, include sales assignment
Future<void> createSupportChat({
  required String userId,
  required String userName,
  required String userPhone,
  required String userEmail,
  required String firstMessage,
}) async {
  // Get user's assigned sales rep
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  final assignedSalesId = userDoc.data()?['assignedSalesId'];
  final assignedSalesName = userDoc.data()?['assignedSalesName'];

  // Check if chat already exists
  final existingChat = await FirebaseFirestore.instance
      .collection('support_chats')
      .where('userId', isEqualTo: userId)
      .limit(1)
      .get();

  String chatId;

  if (existingChat.docs.isNotEmpty) {
    chatId = existingChat.docs.first.id;

    // Update chat with new message
    await existingChat.docs.first.reference.update({
      'lastMessage': firstMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadByAdmin': FieldValue.increment(1),
      if (assignedSalesId != null) 'unreadBySales': FieldValue.increment(1),
    });
  } else {
    // Create new chat
    final chatRef = FirebaseFirestore.instance
        .collection('support_chats')
        .doc();
    chatId = chatRef.id;

    await chatRef.set({
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'lastMessage': firstMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadByAdmin': 1,
      'unreadByUser': 0,
      if (assignedSalesId != null) ...{
        'assignedSalesId': assignedSalesId,
        'assignedSalesName': assignedSalesName,
        'unreadBySales': 1,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Add first message
  await FirebaseFirestore.instance
      .collection('support_chats')
      .doc(chatId)
      .collection('messages')
      .add({
        'text': firstMessage,
        'senderId': userId,
        'isFromAdmin': false,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
}
