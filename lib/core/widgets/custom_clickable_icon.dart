 import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomClickableIcon extends StatelessWidget {
  final void Function()? onPressed;
  final IconData? icon;
  final double? width, height;
  final Color? color, iconColor;

  const CustomClickableIcon({
    super.key,
    this.onPressed,
    required this.icon,
    this.width,
    this.height,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 35,
      height: height ?? 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.white, spreadRadius: .3.r, blurRadius: 10.r),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          fill: double.infinity,
          color: iconColor ?? AppColors.primaryColor,
        ),
      ),
    );
  }
}
