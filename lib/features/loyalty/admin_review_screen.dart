// // // lib/screens/admin_review_screen.dart
// // import 'package:daad_app/features/loyalty/admin_redeem_screen.dart';
// // import 'package:daad_app/features/loyalty/services/loyalty_service.dart';
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:intl/intl.dart';

// // class AdminReviewScreen extends StatefulWidget {
// //   const AdminReviewScreen({Key? key}) : super(key: key);

// //   @override
// //   State<AdminReviewScreen> createState() => _AdminReviewScreenState();
// // }

// // class _AdminReviewScreenState extends State<AdminReviewScreen> {
// //   final LoyaltyService service = LoyaltyService();
// //   final DateFormat df = DateFormat.yMd().add_Hm();
// //   bool _processing = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: 
// //       const AppText(title:'مراجعة طلبات النقاط'),

// //       ),
// //       body: Stack(
// //         children: [

          
// //           StreamBuilder<QuerySnapshot>(
// //             stream: service.pendingActivitiesStream(),
// //             builder: (ctx, snap) {
// //               if (snap.connectionState == ConnectionState.waiting) {
// //                 return const Center(child: CircularProgressIndicator());
// //               }
// //               if (!snap.hasData || snap.data!.docs.isEmpty) {
// //                 return const Center(child: AppText(title:'لا توجد طلبات قيد المراجعة'));
// //               }
// //               final docs = snap.data!.docs;
// //               return ListView.separated(
// //                 padding: EdgeInsets.all(12.r),
// //                 separatorBuilder: (_, __) => SizedBox(height: 8.h
// ),
// //                 itemCount: docs.length,
// //                 itemBuilder: (c, i) {
// //                   final d = docs[i];
// //                   final data = d.data() as Map<String, dynamic>;
// //                   final date = (data['date'] as Timestamp?)?.toDate();
// //                   final link = data['link'] as String?;
// //                   final type = data['type'] as String?;
// //                   final points = (data['points'] as num?)?.toInt() ?? 0;
// //                   final userId = data['userId'] as String?;

// //                   return Card(
// //                     elevation: 2,
// //                     child: ListTile(
// //                       title: AppText(title:'${type ?? 'نشاط'} • $points نقطة'),
// //                       subtitle: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           if (link != null) SelectableAppText(title:'رابط: $link'),
// //                           if (date != null) AppText(title:'تاريخ: ${df.format(date)}'),
// //                           if (userId != null) AppText(title:'المستخدم: $userId'),
// //                         ],
// //                       ),
// //                       trailing: Wrap(
// //                         spacing: 6,
// //                         children: [
// //                           IconButton(
// //                             icon: const Icon(Icons.check, color: Colors.green),
// //                             onPressed: _processing
// //                                 ? null
// //                                 : () => _approve(d.id),
// //                           ),
// //                           IconButton(
// //                             icon: const Icon(Icons.close, color: Colors.red),
// //                             onPressed: _processing
// //                                 ? null
// //                                 : () => _reject(d.id),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               );
// //             },
// //           ),
          

// //           if (_processing)
// //             Positioned.fill(
// //               child: Container(
// //                 color: Colors.black.withOpacity(0.25),
// //                 child: const Center(child: CircularProgressIndicator()),
// //               ),
// //             ),
// //             IconButton( onPressed: () {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(builder: (_) => const AdminRedeemScreen()),
// //     );
// //   }, icon: Icon(Icons.add_ic_call_rounded))

            
// //         ],
// //       ),
// //     );
// //   }

// //   Future<void> _approve(String activityId) async {
// //     setState(() => _processing = true);
// //     try {
// //       await service.approveActivity(activityId: activityId);
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText(title:'تمت الموافقة وزيادة النقاط')));
// //     } catch (e) {
// //       // Detailed error message helps debug transaction assertion errors
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: AppText(title:'خطأ في الموافقة: ${e.toString()}')));
// //     } finally {
// //       if (mounted) setState(() => _processing = false);
// //     }
// //   }

// //   Future<void> _reject(String activityId) async {
// //     setState(() => _processing = true);
// //     try {
// //       await service.rejectActivity(activityId: activityId);
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText(title:'تم رفض الطلب')));
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: AppText(title:'خطأ في الرفض: ${e.toString()}')));
// //     } finally {
// //       if (mounted) setState(() => _processing = false);
// //     }
// //   }
// // }
