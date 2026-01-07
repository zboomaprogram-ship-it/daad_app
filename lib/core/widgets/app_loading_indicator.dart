import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.textColor,
        // strokewidth: 3.w,
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
//         width: 40.w
// .w,
//         height: 15.h
// .h,
//         fit: BoxFit.fill,
//       ),
//     );
//   }
// }
