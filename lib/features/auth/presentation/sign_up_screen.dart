import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_button.dart';
import 'package:daad_app/features/auth/data/auth_service.dart';
import 'package:daad_app/features/auth/presentation/email_verification_screen.dart';
import 'package:daad_app/features/auth/presentation/privacy_policy_screen.dart';
import 'package:daad_app/features/auth/presentation/sign_in_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  final _role = 'client';

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الاسم الكامل';
    }
    if (value.trim().length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  // Phone is now required and must be a Saudi Arabian number
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    // Remove spaces, dashes, and parentheses
    String cleanPhone = value.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Saudi phone validation:
    // - Starts with 966 (country code without +) followed by 5 and 8 digits = 12 digits total
    // - Or starts with 05 followed by 8 digits = 10 digits total
    // - Or starts with 5 followed by 8 digits = 9 digits total

    final saudiWithCountryCode = RegExp(r'^966[5][0-9]{8}$'); // 9665XXXXXXXX
    final saudiWithZero = RegExp(r'^0[5][0-9]{8}$'); // 05XXXXXXXX
    final saudiWithoutZero = RegExp(r'^[5][0-9]{8}$'); // 5XXXXXXXX

    if (!saudiWithCountryCode.hasMatch(cleanPhone) &&
        !saudiWithZero.hasMatch(cleanPhone) &&
        !saudiWithoutZero.hasMatch(cleanPhone)) {
      return 'الرجاء إدخال رقم هاتف سعودي صحيح (مثال: 05XXXXXXXX)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (!value.contains(RegExp(r'[A-Za-z]'))) {
      return 'كلمة المرور يجب أن تحتوي على حروف';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'كلمة المرور يجب أن تحتوي على أرقام';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  Future<void> _signUp() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      _showSnackBar('يجب الموافقة على الشروط والأحكام للمتابعة', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final user = await AuthService.signUpWithEmailPassword(email, password);

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(), // Required field
          'role': _role,
          'points': 0,
          'emailVerified': false,
          'acceptedTerms': true,
          'acceptedTermsAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        });

        final sent = await AuthService.sendEmailVerification();
        if (sent) {
          _showSnackBar('تم إرسال بريد التحقق إلى $email', Colors.green);
        } else {
          _showSnackBar('حدث خطأ أثناء إرسال بريد التحقق', Colors.red);
        }

        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          RouteUtils.pushReplacement(EmailVerificationScreen(email: email));
        }
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'حدث خطأ: $e';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'كلمة المرور ضعيفة جداً';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'البريد الإلكتروني غير صحيح';
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? const GlassBackButton() : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(kAuthBackgroundImage, fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 30.h),
                    Image.asset(kLogoImage, width: 65.18.w, height: 65.18.h),
                    SizedBox(height: 35.h),

                    const AppText(
                      title: 'إنشاء حساب',
                      color: AppColors.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 110.h),

                    GlassTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person_outline_rounded,
                      validator: _validateName,
                    ),
                    SizedBox(height: 16.h),

                    GlassTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 16.h),

                    // Phone is required - Saudi number
                    GlassTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف (سعودي)',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    SizedBox(height: 16.h),

                    GlassTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white.withOpacity(0.8),
                          size: 20.sp,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    GlassTextField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white.withOpacity(0.8),
                          size: 20.sp,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _acceptedTerms
                              ? Colors.white.withOpacity(0.4)
                              : Colors.red.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) => setState(
                                () => _acceptedTerms = value ?? false,
                              ),
                              activeColor: AppColors.secondaryColor,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.6),
                                width: 1.5.w,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'Cairo',
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'أوافق على شروط الاستخدام، سياسة الخصوصية ومعالجة البيانات ',
                                  ),
                                  TextSpan(
                                    text: 'قراءة السياسة',
                                    style: const TextStyle(
                                      color: AppColors.secondaryTextColor,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PrivacyPolicyScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    AppButton(
                      btnText: 'إكمال البيانات',
                      onTap: _isLoading ? null : _signUp,
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: 20.h),

                    ContactGlassButton(
                      onPressed: () => RouteUtils.push(const LoginScreen()),
                      isOutlined: true,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            title: 'لديك حساب بالفعل؟ ',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          AppText(
                            title: 'تسجيل الدخول',
                            color: AppColors.secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            textDecoration: TextDecoration.underline,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
