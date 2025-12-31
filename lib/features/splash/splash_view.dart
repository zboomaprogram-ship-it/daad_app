import 'dart:async';
import 'package:daad_app/features/splash/setup.dart';
import 'package:flutter/material.dart';
import 'package:daad_app/core/constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Start navigation immediately after minimal delay
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Minimal splash duration - just enough to show logo
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Get next screen synchronously (no async operations)
    final nextScreen = getStartupScreen();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: SizedBox(
            height: 150.h,
            width: 150.w,
            child: Image.asset(kLogoImage),
          ),
        ),
      ),
    );
  }
}