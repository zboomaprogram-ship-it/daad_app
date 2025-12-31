 import 'package:cached_network_image/cached_network_image.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CustomCachedNetworkImage extends StatelessWidget {
  const CustomCachedNetworkImage({super.key, required this.url, this.height});

  final String url;
  final double? height;

  @override
  Widget build(BuildContext context) {

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      progressIndicatorBuilder:
          (context, url, downloadProgress) =>
              SpinKitFadingCircle(color: AppColors.textColor, size: 20.sp),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}
