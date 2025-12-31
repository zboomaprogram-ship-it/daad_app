import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';

import 'package:daad_app/features/auth/data/auth_service.dart';
import 'package:daad_app/features/auth/presentation/sign_up_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';

import 'package:flutter/material.dart';


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

  Future<void> _login(BuildContext context) async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(context, 'الرجاء ملء جميع الحقول', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final user = await AuthService.signInWithEmailPassword(email, password);

      if (user != null) {
        final isAdmin = await _checkIfAdmin(user.uid);
        if (mounted) {
          RouteUtils.pushReplacement(const HomeNavigationBar());
        }
      } else {
        if (mounted) {
          _showSnackBar(context, 'بيانات الدخول غير صحيحة', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkIfAdmin(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.exists && userDoc.data()?['role'] == 'admin';
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        leading: Navigator.canPop(context) ? GlassBackButton() : null,
      ),
      body: Container(
        // decoration: const BoxDecoration(
        //   color: AppColors.primaryColor,
        // ),
             decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage("assets/images/background3.jpg"),
      fit: BoxFit.cover,

    ),
  ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  const GlassContainer(
                    width: 100,
                    height: 100,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // const Text(
                  //   'مرحباً بك',
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 32,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  const AppText(title: 'مرحباً بك',color: AppColors.textColor, fontSize: 32, fontWeight: FontWeight.bold,),

                  const SizedBox(height: 8),

                  Text(
                    'سجل دخولك للمتابعة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email Field
                  GlassTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  GlassTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  ContactGlassButton(
                    onPressed: _isLoading ? null : () => _login(context),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Sign Up Button
                  ContactGlassButton(
                    onPressed: () => RouteUtils.push(const SignUpScreen()),
                    isOutlined: true,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      // Navigate to forgot password
                    },
                    child: Text(
                      'هل نسيت كلمة المرور؟',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

