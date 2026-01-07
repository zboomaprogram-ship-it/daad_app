// // lib/features/loyalty/widgets/points_badge.dart
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/data/user_utils.dart';
import 'package:daad_app/features/loyalty/earn_points_screen.dart';
import 'package:daad_app/features/loyalty/loyalty_intro_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class PointsBadge extends StatelessWidget {
  const PointsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.secondaryColor, width: 1.w),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryColor.withOpacity(0.2),
                    AppColors.secondaryColor.withOpacity(0.2),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.0.r),
                child: GestureDetector(
                  onTap: () => RouteUtils.push(const LoyaltyIntroScreen()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        title: UserManager().points.toString(),

                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(width: 6.w),
                      const Icon(Icons.stars, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
