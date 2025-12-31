import 'dart:async';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/features/auth/data/auth_service.dart';
import 'package:daad_app/features/dashboard/dashboard_screen.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:daad_app/features/loyalty/loyalty_intro_screen.dart';
import 'package:daad_app/features/loyalty/my_activities_screen.dart';
import 'package:daad_app/features/loyalty/reward_screen.dart';
import 'package:daad_app/features/splash/splash_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'core/route_utils/route_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DaadApp extends StatefulWidget {
  const DaadApp({super.key});

  @override
  _DaadAppState createState() => _DaadAppState();
}

class _DaadAppState extends State<DaadApp> {
  StreamSubscription<bool>? _logoutSubscription;

  @override
  void initState() {
    super.initState();
    _setupLogoutListener();
  }

  // ✅ Setup listener for force logout
  void _setupLogoutListener() {
    _logoutSubscription = AuthService.watchForceLogout().listen((shouldLogout) {
      if (shouldLogout) {
        _handleForceLogout();
      }
    });
  }

  // ✅ Handle force logout
  Future<void> _handleForceLogout() async {
    await AuthService.signOut(logoutAllDevices: false);
    
    if (mounted) {
      // Show message
      ScaffoldMessenger.of(RouteUtils.navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل خروجك من هذا الجهاز'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate to login
      RouteUtils.pushAndPopAll(const LoginScreen());
    }
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    super.dispose();
  }

  // ✅ Pre-cache images
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  Future<void> _precacheImages() async {
    await Future.wait([
      precacheImage(const AssetImage(kBackgroundImage), context),
      precacheImage(const AssetImage(kAuthBackgroundImage), context),
      precacheImage(const AssetImage(kOnboarding1), context),
      precacheImage(const AssetImage(kOnboarding2), context),
      precacheImage(const AssetImage(kLogoImage), context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(402, 987),
      builder: (context, child) => MaterialApp(
        initialRoute: '/',
        routes: {
          '/earn': (_) => const LoyaltyIntroScreen(),
          '/rewards': (_) => RewardsScreen(),
          '/my_activities': (_) => MyActivitiesScreen(),
        },
        debugShowCheckedModeBanner: false,
        navigatorKey: RouteUtils.navigatorKey,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: const Color(0xFF6F1D36),
          iconTheme: const IconThemeData(color: AppColors.textColor),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: AppColors.textColor,
            selectionColor: AppColors.secondaryTextColor,
          ),
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryColor,
            secondary: Colors.white,
            surface: AppColors.primaryColor,
          ),
          scaffoldBackgroundColor: AppColors.primaryColor,
          fontFamily: 'NotoSansArabic',
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryColor,
            secondary: AppColors.primaryColor,
          ),
          scaffoldBackgroundColor: AppColors.primaryColor,
          fontFamily: 'NotoSansArabic',
        ),
        home: kIsWeb ? const LoginScreen() : const SplashView(),
      ),
    );
  }
}