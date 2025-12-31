import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/widgets/app_loading_indicator.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/data/auth_service.dart';
import 'package:daad_app/features/auth/data/user_utils.dart';
import 'package:daad_app/features/auth/presentation/sign_up_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/auth/presentation/complete_profile_screen.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isVerified = false;
  bool _isResending = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await AuthService.reloadUser();
      if (AuthService.isEmailVerified()) {
        timer.cancel();
        setState(() => _isVerified = true);
        
        // ✅ Update Firestore emailVerified status
        final uid = AuthService.getCurrentUser()?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'emailVerified': true});
        }
        
        _navigateToProfile();
      }
    });
  }

  Future<void> _sendVerificationEmail() async {
    final success = await AuthService.sendEmailVerification();
    if (success && mounted) {
      _showSnackBar('تم إرسال بريد التحقق بنجاح', Colors.green);
      _startResendCooldown();
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);
    await _sendVerificationEmail();
    setState(() => _isResending = false);
  }

  /// ✅ Navigate to Complete Profile or Home based on profile completion
  Future<void> _navigateToProfile() async {
    await UserManager().init();
    await NotificationService.setExternalUserId(UserManager().uid);

    if (mounted) {
      final uid = UserManager().uid;
      // 🔹 Check if profile already completed
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();

      final profileCompleted = data?['profileCompleted'] == true;

      if (profileCompleted) {
        // Already completed — go home
        RouteUtils.pushReplacement(const HomeNavigationBar());
      } else {
        // Go to CompleteProfileScreen first
        RouteUtils.pushReplacement(
          CompleteProfileScreen(
            userId: uid,
          ),
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? const GlassBackButton() : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kAuthBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Logo
                  Image.asset(kLogoImage, width: 62.18.w, height: 62.18.h),
                  SizedBox(height: 24.h),
                  const AppText(
                    title: 'تأكيد البريد الإلكتروني',
                    color: AppColors.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 120.h),
                  AppText(
                    title: 'الرجاء التحقق من البريد الإلكتروني المرسل إلى',
                    textAlign: TextAlign.center,
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    title: widget.email,
                    textAlign: TextAlign.center,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  AppText(
                    title: 'واضغط على رابط التحقق للمتابعة',
                    textAlign: TextAlign.center,
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  SizedBox(height: 48.h),
                  GlassContainer(
                    child: Column(
                      children: [
                        if (_isVerified)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64.sp,
                          )
                        else
                          SizedBox(
                            width: 64.w,
                            height: 64.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.w,
                            ),
                          ),
                        SizedBox(height: 16.h),
                        AppText(
                          title: _isVerified
                              ? 'تم التحقق بنجاح!'
                              : 'جاري الانتظار للتحقق...',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  ContactGlassButton(
                    onPressed: (_isResending || _resendCooldown > 0)
                        ? null
                        : _resendVerificationEmail,
                    isOutlined: true,
                    child: _isResending
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const AppLoadingIndicator(),
                          )
                        : AppText(
                            title: _resendCooldown > 0
                                ? 'إعادة الإرسال بعد $_resendCooldown ثانية'
                                : 'إعادة إرسال البريد',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  SizedBox(height: 16.h),
                  AppText(
                    title: 'لم تستلم البريد؟ تحقق من مجلد البريد المزعج (Spam)'  ,
                    textAlign: TextAlign.center,
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                   SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () => RouteUtils.push(SignUpScreen()),
                    child: AppText(
                      title: 'العوده الي إنشاء الحساب',
                      textDecoration: TextDecoration.underline,
                      
                      textAlign: TextAlign.center,
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}