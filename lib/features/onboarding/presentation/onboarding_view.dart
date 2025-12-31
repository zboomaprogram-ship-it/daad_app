import 'dart:ui';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  static const _pages = [
    OnboardingData(
      image: kOnboarding2,
      title: 'نظـــام الولاء',
      description:
         'يمنحك تطبيق ضاد فرصة كبيرة للحصول على خصومات لخدماتنا تصل إلى ١٠٠٪ من خلال نظام الولاء ، والذي يعمل على منح عملائنا المميزين خطط طويلة المدى لنجاح أعمالهم',
      showButton: true,
    ),
    OnboardingData(
      image: kOnboarding1,
      title: 'خدماتنا',
      description:
         'نساعدك على تحويل رؤيتك إلى قصة نجاح تلهم الجميع من خلال خدماتنا: إنشاء المتاجر - إنشاء هوية بصرية  - تحسين محركات البحث -  إدارة الحملات التسويقية- إدارة منصات التواصل الاجتماعي - خدمة ال UG والكثير..',
      showButton: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(
              ),
            ),
          );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: Image(
              image: AssetImage(kBackgroundImage),
              fit: BoxFit.cover,
            ),
          ),

          // Full-screen PageView
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];

                return Stack(
                  children: [
                    // Top image (same layout)
                    Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.65,
                        widthFactor: 1,
                        child: Image.asset(
                          page.image,
                          fit: BoxFit.cover,
                          cacheHeight: (MediaQuery.of(context).size.height *
                                  0.65 *
                                  MediaQuery.of(context).devicePixelRatio)
                              .toInt(),
                        ),
                      ),
                    ),

                    // Glass card inside page (so swipe works everywhere)
                    Positioned(
                      left: 30,
                      right: 30,
                      bottom: 60,
                      child: _GlassContentCard(
                        page: page,
                        currentPage: _currentPage,
                        pageCount: _pages.length,
                        onNavigateToLogin: _navigateToLogin,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassContentCard extends StatelessWidget {
  final OnboardingData page;
  final int currentPage;
  final int pageCount;
  final VoidCallback onNavigateToLogin;

  const _GlassContentCard({
    required this.page,
    required this.currentPage,
    required this.pageCount,
    required this.onNavigateToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.45),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5.w,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                title: page.title,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              AppText(
                title: page.description,
                fontSize: 15,
                color: Colors.white.withOpacity(0.95),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // ✅ Fast, responsive tap (no nested GestureDetector)
              
              // ✅ Lightweight tap button
              if (page.showButton) ...[
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textColor.withOpacity(0.45),width: 1),
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: GestureDetector(
                        onTap: onNavigateToLogin,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 12.sp,
                              // weight: 200,
                              
                            ),
                            SizedBox(width: 5.w),
                            const AppText(
                              title: 'ابدأ الدخول',
                              fontSize: 9.38,
                              fontWeight: FontWeight.w900,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ] else
                SizedBox(height: 24.h),

              _PageIndicators(
                currentPage: currentPage,
                pageCount: pageCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicators({
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: currentPage == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;
  final bool showButton;

  const OnboardingData({
    required this.image,
    required this.title,
    required this.description,
    this.showButton = false,
  });
}
