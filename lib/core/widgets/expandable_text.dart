
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;

  const ExpandableDescription({super.key, required this.description});

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool isExpanded = false;
  bool showToggle = false;
  

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLineOverflow();
  }
  

  void _checkLineOverflow() {

    final span = TextSpan(
      text: widget.description,
      style: TextStyle(fontSize: 12.sp, color: AppColors.textColor),
    );

    final tp = TextPainter(
      text: span,
      maxLines: 3,
      textDirection: TextDirection.rtl,
    );

    tp.layout(maxWidth: MediaQuery.of(context).size.width - 40.w);

    setState(() {
      showToggle = tp.didExceedMaxLines;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title: widget.description,
          fontSize: 12,
          color: AppColors.textColor,
          textAlign: TextAlign.right,
          maxLines: isExpanded ? null : 3,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (showToggle)
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                isExpanded ? 'عرض أقل' : 'عرض المزيد',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
