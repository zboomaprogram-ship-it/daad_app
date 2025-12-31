import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_button.dart';
import 'package:daad_app/features/auth/data/auth_service.dart';
import 'package:daad_app/features/auth/data/user_utils.dart';
import 'package:daad_app/features/auth/presentation/sign_up_screen.dart';
import 'package:daad_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:daad_app/features/auth/presentation/email_verification_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/dashboard/dashboard_screen.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ✅ Updated login logic with strict email verification
// Update only the _login method in your LoginScreen:

Future<void> _login(BuildContext context) async {
  if (_emailController.text.trim().isEmpty ||
      _passwordController.text.isEmpty) {
    _showSnackBar(context, 'الرجاء ملء جميع الحقول', Colors.red);
    return;
  }
  setState(() => _isLoading = true);

  try {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final user = await AuthService.signInWithEmailPassword(email, password);

    if (user == null) {
      if (mounted) {
        _showSnackBar(context, 'بيانات الدخول غير صحيحة أو تم تسجيل خروجك من جميع الأجهزة', Colors.red);
      }
      setState(() => _isLoading = false);
      return;
    }

    // Reload to ensure verified status is updated
    await user.reload();
    final currentUser = AuthService.getCurrentUser();

    // ⛔ Block if email is not verified
    if (currentUser == null || !currentUser.emailVerified) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          context,
          'يجب تأكيد بريدك الإلكتروني قبل تسجيل الدخول',
          Colors.orange,
        );

        await AuthService.signOut(logoutAllDevices: false);
        RouteUtils.pushReplacement(EmailVerificationScreen(email: email));
      }
      return;
    }

    // 🔍 Fetch Firestore user document
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // Create Firestore record automatically
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'client',
        'points': 0,
        'emailVerified': true,
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'emailVerified': true});
    }

    // ⚠️ IMPORTANT: Role check for WEB ONLY
    final role = userDoc.data()?['role'] ?? 'client';

    if (kIsWeb && role != "admin") {
      // kick user out
      await AuthService.signOut(logoutAllDevices: false);

      if (mounted) {
        _showSnackBar(
          context,
          "🚫 لا يمكن الدخول عبر الويب إلا للمسؤولين (Admin)",
          Colors.red,
        );
      }
      return;
    }

    // 🟢 Allow login if role is valid
    if (mounted) {
      await UserManager().init();

      if (!kIsWeb) {
        await NotificationService.setExternalUserId(UserManager().uid);
      }

      RouteUtils.pushAndPopAll(
        kIsWeb ? const DashboardScreen() : const HomeNavigationBar(),
      );
    }
  } catch (e) {
    if (mounted) {
      String errorMessage = 'حدث خطأ: $e';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'المستخدم غير موجود';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'كلمة المرور غير صحيحة';
      } else if (e.toString().contains('invalid-credential')) {
        errorMessage = 'بيانات الدخول غير صحيحة';
      }
      _showSnackBar(context, errorMessage, Colors.red);
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  void _showSnackBar(BuildContext context, String message, Color color) {
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
        child: SingleChildScrollView(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Logo
                    Image.asset(kLogoImage, width: 65.18.w, height: 65.18.h),

                    SizedBox(height: 35.h),

                    const AppText(
                      title: 'تسجيل الدخول',
                      color: AppColors.textColor,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),

                    SizedBox(height: 130.h),

                    // Email Field
                    GlassTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: 16.h),

                    // Password Field
                    GlassTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white.withOpacity(0.8),
                          size: kIsWeb ? 20: 20.sp,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    if(!kIsWeb)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            RouteUtils.push(const ForgotPasswordScreen());
                          },
                          child: const AppText(
                            title: 'نسيت كلمة المرور؟',
                            fontSize: 14,
                            textDecoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    AppButton(
                      btnText: 'تسجيل الدخول',
                      onTap: _isLoading ? null : () => _login(context),
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: 16.h),

                    // Sign Up Button
                    if(!kIsWeb)
                    ContactGlassButton(
                      onPressed: () => RouteUtils.push(SignUpScreen()),
                      isOutlined: true,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            title: 'ليس لديك حساب؟ ',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          AppText(
                            title: 'إنشاء حساب',
                            color: AppColors.secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            textDecoration: TextDecoration.underline,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 1000.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}