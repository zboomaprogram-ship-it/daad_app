import 'dart:ui';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlassBackButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onPressed;

  const GlassBackButton({this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.all(8.r),
          child: GlassIconButton(
            icon: icon ?? Icons.arrow_back_ios_rounded,
            onPressed: onPressed ?? () => _handleBackPress(context),
          ),
        ),
      ],
    );
  }

  /// ✅ Smart back navigation - handles deep links
  void _handleBackPress(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      // Normal back navigation if there's a previous screen
      Navigator.of(context).pop();
    } else {
      // If no previous screen (came from deep link), go to home
      print('📱 No previous screen - navigating to home');
      RouteUtils.pushAndPopAll(  HomeNavigationBar());
    }
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.45),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.transparent, width: 1.w),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12.r),
              child: Icon(icon, color: Colors.white, size: 18.sp),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassImageButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;
  final bool white;

  const GlassImageButton({
    required this.imagePath,
    required this.onPressed,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 40.w,
          height: 40.h,
          padding: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            color: white
                ? Colors
                      .white // ← إذا white = true → خلفية بيضاء
                : null, // خلاف ذلك → نستخدم التصميم الأصلي
            gradient: white
                ? null
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.45),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: white ? Colors.white : Colors.transparent,
              width: 1.w,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: Image.asset(
                  imagePath,
                  width: 20.w,
                  height: 20.h,
                  color: white
                      ? Colors.black
                      : null, // ← يفضل تغيّر لون الصورة عند خلفية بيضاء
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff922D4E), Color(0xff480118)],
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.45),
              width: 1.w,
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.transparent.withOpacity(0.4),
            //     blurRadius: 15,
            //     offset: const Offset(0, 5),
            //   ),
            // ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final finalMaxLines = obscureText ? 1 : (maxLines ?? 1);

    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end, // عربي
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9.78.r),
              child: Container(
                height: kIsWeb ? 55: 50.sp,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.45),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9.78.r),
                  border: Border.all(
                    color: state.hasError
                        ? Colors.red.withOpacity(0.6)
                        : Colors.white.withOpacity(0.28),
                    width: 1.w,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  maxLines: finalMaxLines,
                  keyboardType: keyboardType,
                  onChanged: (v) => state.didChange(v),
                  style: TextStyle(color: Colors.white, fontSize: kIsWeb ? 15: 15.sp),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: kIsWeb ? 12: 12.sp,
                    ),
                    prefixIcon: Icon(
                      icon,
                      color: Colors.white.withOpacity(0.8),
                      size: kIsWeb ? 20: 20.sp,
                    ),
                    suffixIcon: suffixIcon,
                    border: InputBorder.none,

                    // ✅ مهم: لا تعرض error داخل الحقل
                    errorText: null,
                  ),
                ),
              ),
            ),

            // ✅ error تحت الحقل (خارج الكونتينر)
            if (state.hasError) ...[
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  state.errorText ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12.sp,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}


class ContactGlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isOutlined;

  const ContactGlassButton({
    required this.onPressed,
    required this.child,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            gradient: isOutlined
                ? null
                : LinearGradient(
                    colors: [
                      Colors.transparent.withOpacity(0.2),
                      Colors.transparent.withOpacity(0.2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.transparent,
              width: isOutlined ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16.r),
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.transparent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title: title, fontSize: 12),
                SizedBox(height: 4.h),
                AppText(
                  title: value,

                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String serviceName;
  final String date;

  const PlanCard({required this.serviceName, required this.date});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title: serviceName,

                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 4.h),
                AppText(title: 'أضيفت في: $date', fontSize: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final String message;
  final String date;
  final String status;
  final String adminResponse;

  const MessageCard({
    required this.message,
    required this.date,
    required this.status,
    required this.adminResponse,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText(
                  title: isPending ? 'قيد المراجعة' : 'تم الرد',

                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              AppText(title: date, fontSize: 10),
            ],
          ),
          SizedBox(height: 12.h),
          AppText(title: message, color: Colors.white, fontSize: 14),
          if (adminResponse.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.transparent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title: 'رد المسؤول:',

                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  AppText(title: adminResponse, fontSize: 13),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PortfolioCard extends StatelessWidget {
  final String title;
  final String industry;
  final String imageUrl;
  final VoidCallback onTap;

  const PortfolioCard({
    required this.title,
    required this.industry,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent.withOpacity(0.2),
                  Colors.transparent.withOpacity(0.2),
                  Colors.transparent.withOpacity(0.2),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.transparent, width: 1.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Section
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: DaadImage(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // Gradient Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.transparent.withOpacity(0.2),
                                Colors.transparent.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Industry Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 0.5.w,
                                ),
                              ),
                              child: AppText(
                                title: industry,

                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          title: title,

                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,

                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            SizedBox(width: 4.w),
                            AppText(
                              title: 'عرض التفاصيل',

                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
