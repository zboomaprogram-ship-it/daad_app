 import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppText extends StatelessWidget {
  const AppText({
    super.key,
    required this.title,
    this.maxLines,
    this.color ,
    this.fontSize = 14,
    this.height = 0,
    this.fontWeight = FontWeight.w400,
    this.textDecoration = TextDecoration.none,
    this.overflow,
    this.textAlign,
    this.cutoff,
    this.textDirection,
  });

  final String title;
  final int? maxLines;
  final Color? color;
  final double fontSize;
  final double? height;
  final FontWeight fontWeight;
  final TextDecoration textDecoration;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final int? cutoff;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    String displayTitle = title;
    if (cutoff != null) {
      displayTitle = truncateWithEllipsis(cutoff!, title);
    }
    // final brightness = Theme.of(context).brightness;
    return Text(
      displayTitle,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      style: TextStyle(
        color: color??AppColors.textColor,
        fontSize: kIsWeb ? fontSize : fontSize.sp, 
        fontWeight: fontWeight,
        fontFamily: 'TheYearOfCamel',
        decoration: textDecoration,
        overflow: overflow,
        height: height,
      ),
      
    );
  }
}

String truncateWithEllipsis(int cutoff, String myString) {
  return (myString.length <= cutoff)
      ? myString
      : '${myString.substring(0, cutoff)}...';
}
