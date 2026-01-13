// // DISABLED: Voice messaging feature temporarily disabled due to iOS crash bug in audioplayers plugin
// // import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class VoiceMessageBubble extends StatelessWidget {
//   final String audioUrl;
//   final bool isSender;

//   const VoiceMessageBubble({
//     super.key,
//     required this.audioUrl,
//     required this.isSender,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Disabled widget - shows a simple message instead
//     return Container(
//       width: 230.w,
//       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.volume_off, size: 20.sp, color: Colors.grey),
//           SizedBox(width: 8.w),
//           Expanded(
//             child: Text(
//               'Voice messages temporarily disabled',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12.sp,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
