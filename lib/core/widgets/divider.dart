import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key, required this.text, this.textColor});
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Divider(color: AppColors.textColor, thickness: 1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: AppText(
              title: text,
              fontWeight: FontWeight.w400,
              color: textColor ?? AppColors.textColor,
              fontSize: 16,
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.textColor, thickness: 1),
          ),
        ],
      ),
    );
  }
}
