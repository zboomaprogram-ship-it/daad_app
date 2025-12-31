// // import 'dart:ui';

// // import 'package:daad_app/core/widgets/app_text.dart';
// // import 'package:flutter/material.dart';

// // class GlassNavigationCard extends StatelessWidget {
// //   final String title;
// //   final String titleAr;
// //   final IconData icon;
// //   final VoidCallback onTap;

// //   const GlassNavigationCard({
// //     required this.title,
// //     required this.titleAr,
// //     required this.icon,
// //     required this.onTap,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Material(
// //       color: Colors.transparent,
// //       child: InkWell(
// //         onTap: onTap,
// //         borderRadius: BorderRadius.circular(20.r)
// ,
// //         splashColor: const Color.fromARGB(0, 255, 255, 255).withOpacity(0.1),
// //         highlightColor: Colors.white.withOpacity(0.05),
// //         child: ClipRRect(
// //           borderRadius: BorderRadius.circular(20.r)
// ,
// //           child: BackdropFilter(
// //             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
// //             child: Container(
// //               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     Colors.transparent,
// //                     Colors.transparent,
// //                     Colors.transparent,
// //                   ],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                   stops: const [0.0, 0.5, 1.0],
// //                 ),
// //                 borderRadius: BorderRadius.circular(20.r)
// ,
// //                 border: Border.all(
// //                   color: Colors.transparent,
// //                   width: 1.w
// // ,
// //                 ),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black.withOpacity(0.3),
// //                     blurRadius: 20,
// //                     offset: const Offset(0, 8),
// //                   ),
// //                 ],
// //               ),
// //               child: Stack(
// //                 children: [
            
// //                   Row(
// //                     children: [
// //                       Container(
// //                         padding: EdgeInsets.all(10.r),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white.withOpacity(0.15),
// //                           borderRadius: BorderRadius.circular(12.r)
// ,
// //                         ),
// //                         child: Icon(
// //                           icon,
// //                           color: Colors.white,
// //                           size: 24,
// //                         ),
// //                       ),
// //                       SizedBox(width: 16.w
// // ),
// //                       Expanded(
// //                         child: Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                           AppText(
// //                           title: 
// //                               title,
                           
// //                                 color: Colors.white,
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
                            
// //                             ),
// //                            AppText(
// //                           title: 
// //                               titleAr,
                            
                                
// //                                 fontSize: 12,
// //                                 fontWeight: FontWeight.w400,
                           
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                       Icon(
// //                         Icons.arrow_forward_ios_rounded,
// //                         color: Colors.white.withOpacity(0.8),
// //                         size: 18,
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
