import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_button.dart';
import 'package:daad_app/features/auth/data/auth_service.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال البريد الإلكتروني', Colors.red);
      return;
    }

    // التحقق من صحة البريد الإلكتروني
    if (!_emailController.text.trim().contains('@')) {
      _showSnackBar('الرجاء إدخال بريد إلكتروني صحيح', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (success) {
        setState(() => _emailSent = true);
        _showSnackBar('تم إرسال رابط إعادة تعيين كلمة المرور', Colors.green);
      } else {
        _showSnackBar(
          'فشل إرسال البريد، تأكد من صحة البريد الإلكتروني',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('حدث خطأ: $e', Colors.red);
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
                  //  SizedBox(height: 30),
                  // Logo
                  Image.asset(kLogoImage, width: 62.18.w, height: 62.18.h),
                  SizedBox(height: 24.h),
                  const AppText(
                    title: 'نسيت كلمة السر',
                    color: AppColors.textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 120.h),

                  if (!_emailSent) ...[
                    AppText(
                        title: 
                      'أدخل بريدك الإلكتروني المسجل لديك لنتمكن من إرسال رابط لتعيين كلمة مرور جديدة',
                      textAlign: TextAlign.center,
                     
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                  
                    ),

                    SizedBox(height: 16.h),

                    // Email Field
                    GlassTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: 32.h),

                    // Send Button
                    // ContactGlassButton(
                    //   onPressed: _isLoading ? null : _sendResetEmail,
                    //   child: _isLoading
                    //       ? SizedBox(
                    //           height: 20.h,
                    //           width: 20.w,
                    //           child: CircularProgressIndicator(
                    //             color: Colors.white,
                    //             strokewidth: 2.w,
                    //           ),
                    //         )
                    //       : const Row(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Icon(Icons.send_rounded, size: 20),
                    //             SizedBox(width: 8.w),
                    //             Text(
                    //               'إرسال',
                    //               style: TextStyle(
                    //                 fontSize: 16,
                    //                 fontWeight: FontWeight.bold,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    // ),
                    AppButton(
                      btnText: 'إرسال',
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _sendResetEmail,
                      width: 150.w,
                      
                    ),
                  ] else ...[
                    // Success Message
                    GlassContainer(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16.h),
                          const AppText(
                        title: 
                            'تم إرسال البريد بنجاح!',
                        
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                          
                          ),
                          SizedBox(height: 8.h),
                         AppText(
                        title: 
                            'تحقق من بريدك الإلكتروني واتبع التعليمات لإعادة تعيين كلمة المرور',
                            textAlign: TextAlign.center,
                           
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                          
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Back to Login Button
                    ContactGlassButton(
                      onPressed: () => Navigator.of(context).pop(),
                      isOutlined: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back, size: 20),
                          SizedBox(width: 8.w),
                          const AppText(
                        title: 
                            'العودة لتسجيل الدخول',
                           
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                         
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Resend Email
                    TextButton(
                      onPressed: () {
                        setState(() => _emailSent = false);
                      },
                      child: AppText(
                        title: 
                        'لم تستلم البريد؟ إعادة الإرسال',
                         
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          textDecoration: TextDecoration.underline,
                    
                      ),
                    ),
                  ],
                ],
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
    super.dispose();
  }
}
