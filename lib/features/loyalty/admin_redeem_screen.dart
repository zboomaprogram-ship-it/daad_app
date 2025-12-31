// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:daad_app/core/widgets/app_text.dart';
// import 'package:flutter/material.dart';

// class AdminRedeemScreen extends StatelessWidget {
//   const AdminRedeemScreen({super.key});

//   Future<void> _approve(String requestId, String userId, int requiredPoints) async {
//     final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
//     final requestRef = FirebaseFirestore.instance.collection('redeem_requests').doc(requestId);

//     await FirebaseFirestore.instance.runTransaction((trx) async {
//       final userSnap = await trx.get(userRef);
//       final currentPoints = userSnap.data()?['points'] ?? 0;

//       if (currentPoints < requiredPoints) {
//         throw Exception("User does not have enough points anymore");
//       }

//       trx.update(userRef, {
//         "points": currentPoints - requiredPoints,
//       });

//       trx.update(requestRef, {
//         "status": "approved",
//         "approvedAt": FieldValue.serverTimestamp(),
//       });
//     });
//   }

//   Future<void> _reject(String requestId) async {
//     await FirebaseFirestore.instance.collection('redeem_requests').doc(requestId).update({
//       "status": "rejected",
//       "rejectedAt": FieldValue.serverTimestamp(),
//     });
//   }
// Future<Map<String, dynamic>> _getUserInfo(String uid) async {
//   final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
//   final data = snap.data() ?? {};

//   return {
//     "name": data['name'] ?? "مستخدم غير معروف",
//     "phone": data['phone'] ?? "بدون رقم",
//   };
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const  AppText(title:"طلبات الاستبدال")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('redeem_requests')
//             .orderBy('date', descending: true)
//             .snapshots(),
//         builder: (context, snap) {
//           if (!snap.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final docs = snap.data!.docs;

//           if (docs.isEmpty) {
//             return const Center(child:  AppText(title:"لا توجد طلبات حالياً"));
//           }

//           return ListView.builder(
//             padding: EdgeInsets.all(12.r),
//             itemCount: docs.length,
//             itemBuilder: (c, i) {
//               final d = docs[i].data() as Map<String, dynamic>;
//               final id = docs[i].id;
//               final uid = d['userId'];
//               final title = d['rewardTitle'];
//               final points = d['requiredPoints'];
//               final status = d['status'];
//               return  Card(
//                 // color: AppColors.secondaryColor.withOpacity(0.2),
                
//   child: FutureBuilder<Map<String, dynamic>>(
//     future: _getUserInfo(uid),
//     builder: (context, snapUser) {
//       final user = snapUser.data ?? {};
//       final username = user['name'] ?? "...";
//       final phone = user['phone'] ?? "...";

//       return ListTile(
//         title:  AppText(title:title),
//         subtitle:  AppText(title:
//           "المستخدم: $username\n"
//           "الهاتف: $phone\n"
//           "النقاط المطلوبة: $points\n"
//           "الحالة: $status",
//         ),
//         trailing: status == 'pending'
//             ? Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.check, color: Colors.green),
//                     onPressed: () async {
//                       await _approve(id, uid, points);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content:  AppText(title:"تم الموافقة")),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close, color: Colors.red),
//                     onPressed: () async {
//                       await _reject(id);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content:  AppText(title:"تم الرفض")),
//                       );
//                     },
//                   ),
//                 ],
//               )
//             :  AppText(title:status == 'approved' ? "✅ مقبول" : "❌ مرفوض"),
//       );
//     },
//   ),
// );

//             },
//           );
//         },
//       ),
//     );
//   }
// }
