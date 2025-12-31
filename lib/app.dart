import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'core/route_utils/route_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil

class DaadApp extends StatefulWidget {
  const DaadApp({super.key});

  @override
  _DaadAppState createState() => _DaadAppState();
}

class _DaadAppState extends State<DaadApp> {
  // Color? _primaryColor;
  // Color? _secondaryColor;
  // Color? _backgroundColor;

  @override
  void initState() {
    super.initState();
    // _fetchColorSettings(); // Fetch colors from Firestore when the app starts
  }

  // Fetch color settings from Firestore
  // Future<void> _fetchColorSettings() async {
  //   final docRef = FirebaseFirestore.instance.collection('app_settings').doc('public');
  //   final snap = await docRef.get();
  //   final data = snap.data();
  
  //   if (data != null) {
  //     setState(() {
  //       _primaryColor = Color(int.parse(data['primaryColor'] ?? '0xff000000'));
  //       _secondaryColor = Color(int.parse(data['secondaryColor'] ?? '0xff000000'));
  //       _backgroundColor = Color(int.parse(data['backgroundColor'] ?? '0xff5f1c32'));
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // You can use your design screen size here
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: RouteUtils.navigatorKey, // Use the custom navigatorKey
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
          colorScheme: const ColorScheme.light(
            primary:  AppColors.primaryColor,
            secondary: Colors.white,
          ),
          scaffoldBackgroundColor:   AppColors.primaryColor,
          fontFamily: 'NotoSansArabic',

        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
              primary:  AppColors.primaryColor,
            secondary: Colors.white,
          ),
          scaffoldBackgroundColor:  AppColors.primaryColor,
          fontFamily: 'NotoSansArabic',
        ),
        home: _getInitialScreen(),
      ),
    );
  }

  // Check if the user is logged in or not
  Widget _getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen(); // Show LoginScreen if the user is not logged in
    } else {
      return const HomeNavigationBar(); // Show the HomeNavigationBar if the user is logged in
    }
  }
}
