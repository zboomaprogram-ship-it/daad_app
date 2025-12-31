// import 'package:angelina_app/core/utils/route_utils/route_utils.dart';
 import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppAppBar extends StatelessWidget {
  final String title;
  const AppAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // bool canPop = Navigator.of(context).canPop();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // if (canPop)
        //   IconButton(
        //     onPressed: () => RouteUtils.pop(),
        //     icon: const Icon(CupertinoIcons.back),
        //     iconSize: 30.sp,
        //   )
        // else
          SizedBox(width: 48.w
.w),
        AppText(title: title, fontSize: 24, fontWeight: FontWeight.bold),

        // UserAvatar(),
        SizedBox(width: 46.w
.w),
      ],
    );
  }
}
