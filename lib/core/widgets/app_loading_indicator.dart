import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        // color: AppColors.primaryColor,
        strokeWidth: 3,
      ),
    );
  }
}

// import 'package:lottie/lottie.dart';

// class AppLoadingIndicator extends StatelessWidget {
//   const AppLoadingIndicator({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Lottie.asset(
//         'assets/lottie/Animation - 1746358977110.json',
//         width: 40.w,
//         height: 15.h,
//         fit: BoxFit.fill,
//       ),
//     );
//   }
// }
