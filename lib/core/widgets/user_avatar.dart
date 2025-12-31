 import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40.r,
      backgroundColor: AppColors.primaryColor,
      // backgroundImage: const AssetImage('assets/images/user_placeholder.jpg'),
    );
  }
}
