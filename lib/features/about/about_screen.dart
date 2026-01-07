import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/daad_image.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText(title: 'من نحن'),
        leading: CustomBackButton(),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            DaadImage(null, height: 160.h),
            SizedBox(height: 12.h),
            const AppText(
              title:
                  'شركة ضاد للتسويق — نبني لك حلولًا تسويقية متخصصة عبر المنطقة...',
            ),
          ],
        ),
      ),
    );
  }
}
