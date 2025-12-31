// import 'dart:ui';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:daad_app/core/constants.dart';
// import 'package:daad_app/core/utils/app_colors/app_colors.dart';
// import 'package:daad_app/core/widgets/app_text.dart';
// import 'package:daad_app/core/widgets/daad_image.dart';
// import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// /// كارت حملة إعلانية لاستعراض نتائجها + فتح ملف PDF
// /// يستخدم ثيم الكارت اللي أرسلته في الصورة
// class PortfolioResultCard extends StatefulWidget {
//   final String docId;                 // id الوثيقة في Firestore
//   final Map<String, dynamic> data;    // بيانات الوثيقة كاملة

//   const PortfolioResultCard({
//     super.key,
//     required this.docId,
//     required this.data,
//   });

//   @override
//   State<PortfolioResultCard> createState() => _PortfolioResultCardState();
// }

// class _PortfolioResultCardState extends State<PortfolioResultCard> {
//   late String _title;
//   late String _body;
//   late String _industry;
//   late String _imageUrl;
//   late String _pdfUrl;

//   late int _views;
//   late int _likes;
//   late int _bookmarks;

//   late bool _isLiked;
//   late bool _isBookmarked;

//   @override
//   void initState() {
//     super.initState();
//     final data = widget.data;

//     _title = data['title'] ?? 'عنوان الحملة';
//     _body = data['body'] ?? '';
//     _industry = data['industry'] ?? '';

//     _imageUrl =
//         (data['images'] is List && (data['images'] as List).isNotEmpty)
//             ? data['images'][0]
//             : (data['imageUrl'] ?? kDefaultImage);

//     _pdfUrl = data['pdfUrl']?.toString() ?? '';

//     final dynamic rawViews = data['views'];
//     _views = rawViews is num ? rawViews.toInt() : 0;

//     final List likedBy = List.from(data['likedBy'] ?? []);
//     final List bookmarkedBy = List.from(data['bookmarkedBy'] ?? []);

//     final currentUid = FirebaseAuth.instance.currentUser?.uid;

//     _likes = likedBy.length;
//     _bookmarks = bookmarkedBy.length;
//     _isLiked = currentUid != null && likedBy.contains(currentUid);
//     _isBookmarked = currentUid != null && bookmarkedBy.contains(currentUid);
//   }

//   /// ✅ زيادة المشاهدات مرة واحدة لكل مستخدم + فتح ملف الـ PDF
//   Future<void> _openPdf() async {
//     if (_pdfUrl.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: AppText(title: 'رابط الملف غير متوفر'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return;
//     }

//     final user = FirebaseAuth.instance.currentUser;
//     final docRef =
//         FirebaseFirestore.instance.collection('portfolio').doc(widget.docId);

//     if (user != null) {
//       final uid = user.uid;

//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         final snap = await transaction.get(docRef);
//         if (!snap.exists) return;

//         final data = snap.data() as Map<String, dynamic>? ?? {};

//         final int currentViews =
//             (data['views'] is num) ? (data['views'] as num).toInt() : 0;
//         final List<dynamic> viewedBy =
//             List<dynamic>.from(data['viewedBy'] ?? []);

//         if (!viewedBy.contains(uid)) {
//           transaction.update(docRef, {
//             'views': currentViews + 1,
//             'viewedBy': FieldValue.arrayUnion([uid]),
//           });

//           // حدّث القيمة في الواجهة
//           setState(() {
//             _views = currentViews + 1;
//           });
//         }
//       });
//     }

//     // 👈 هنا يفتح شاشة الـ PDF فقط (بدون صفحة تفاصيل)
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PdfContractPage(
//           pdfUrl: _pdfUrl,
//           title: _title,          // العنوان في الـ AppBar
//           showAgreementButton: false,
//         ),
//       ),
//     );
//   }

//   Future<void> _toggleLike() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     final uid = user.uid;

//     final docRef =
//         FirebaseFirestore.instance.collection('portfolio').doc(widget.docId);

//     setState(() {
//       if (_isLiked) {
//         _isLiked = false;
//         _likes = (_likes - 1).clamp(0, 1 << 31);
//       } else {
//         _isLiked = true;
//         _likes++;
//       }
//     });

//     await docRef.update({
//       'likedBy':
//           _isLiked ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
//     });
//   }

//   Future<void> _toggleBookmark() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     final uid = user.uid;

//     final docRef =
//         FirebaseFirestore.instance.collection('portfolio').doc(widget.docId);

//     setState(() {
//       if (_isBookmarked) {
//         _isBookmarked = false;
//         _bookmarks = (_bookmarks - 1).clamp(0, 1 << 31);
//       } else {
//         _isBookmarked = true;
//         _bookmarks++;
//       }
//     });

//     await docRef.update({
//       'bookmarkedBy': _isBookmarked
//           ? FieldValue.arrayUnion([uid])
//           : FieldValue.arrayRemove([uid]),
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(32.r)
// ,
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.06),
//             borderRadius: BorderRadius.circular(32.r)
// ,
//             border: Border.all(
//               color: Colors.white.withOpacity(0.25),
//               width: 1.4.w
// ,
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // -------- صورة الحملة --------
//               ClipRRect(
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(32),
//                 ),
//                 child: SizedBox(
//                   height: 180.h
// ,
//                   width: double.infinity,
//                   child: Stack(
//                     fit: StackFit.expand,
//                     children: [
//                       DaadImage(
//                         _imageUrl,
//                         fit: BoxFit.cover,
//                       ),
//                       Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               Colors.black.withOpacity(0.2),
//                               Colors.black.withOpacity(0.5),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 24,
//                         right: 24,
//                         bottom: 16,
//                         child: AppText(
//                           title: _title,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           maxLines: 2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               SizedBox(height: 8.h
// ),

//               // -------- مؤشرات السلايدر --------
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildIndicatorDot(true),
//                    SizedBox(width: 6.w
// ),
//                   _buildIndicatorDot(false),
//                    SizedBox(width: 6.w
// ),
//                   _buildIndicatorDot(false),
//                 ],
//               ),

//               SizedBox(height: 8.h
// ),

//               // -------- نصوص + إحصائيات --------
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppText(
//                       title: _body,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       fontSize: 13,
//                     ),
//                     SizedBox(height: 4.h
// ),
//                     if (_industry.isNotEmpty)
//                       AppText(
//                         title: _industry,
//                         fontSize: 11,
//                         color: Colors.white70,
//                       ),
//                     SizedBox(height: 6.h
// ),
//                     AppText(
//                       title: _body,
//                       fontSize: 12,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       color: Colors.white.withOpacity(0.9),
//                     ),
//                     SizedBox(height: 12.h
// ),

//                     // ---- المفضلة / الحفظ / المشاهدات ----
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildIconStat(
//                           icon: _isBookmarked
//                               ? Icons.bookmark
//                               : Icons.bookmark_border,
//                           count: _bookmarks,
//                           onTap: _toggleBookmark,
//                         ),
//                         _buildIconStat(
//                           icon: _isLiked ? Icons.favorite : Icons.favorite_border,
//                           count: _likes,
//                           onTap: _toggleLike,
//                         ),
//                         _buildIconStat(
//                           icon: Icons.remove_red_eye_outlined,
//                           count: _views,
//                           onTap: null, // للمشاهدة فقط
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 16.h
// ),

//                     // ---- زر فتح PDF ----
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _openPdf,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black.withOpacity(0.7),
//                           padding: EdgeInsets.symmetric(
//                             vertical: 14,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(24.r)
// ,
//                           ),
//                         ),
//                         icon: const Icon(
//                           Icons.picture_as_pdf,
//                           color: Colors.white,
//                         ),
//                         label: const AppText(
//                           title: 'عرض نتائج الحملة (PDF)',
//                           color: Colors.white,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: 12.h
// ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildIndicatorDot(bool active) {
//     return Container(
//       width: active ? 22 : 8,
//       height: 4.h
// ,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(active ? 0.9 : 0.4),
//         borderRadius: BorderRadius.circular(4.r)
// ,
//       ),
//     );
//   }

//   Widget _buildIconStat({
//     required IconData icon,
//     required int count,
//     VoidCallback? onTap,
//   }) {
//     final child = Row(
//       children: [
//         AppText(
//           title: '$count',
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//         ),
//          SizedBox(width: 4.w
// ),
//         Icon(
//           icon,
//           size: 18,
//           color: Colors.white,
//         ),
//       ],
//     );

//     if (onTap == null) return child;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20.r)
// ,
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//         child: child,
//       ),
//     );
//   }
// }
