import 'package:daad_app/features/auth/presentation/email_verification_screen.dart';
import 'package:daad_app/features/onboarding/presentation/onboarding_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:flutter/material.dart';

Widget getStartupScreen() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // No user logged in - show onboarding
    return const OnboardingScreen();
  } else {
    // User is logged in - check email verification
    if (user.emailVerified) {
      // Email verified - allow access to home
      return const HomeNavigationBar();
    } else {
      // Email not verified - redirect to verification screen
      return EmailVerificationScreen(email: user.email ?? '');
    }
  }
}
