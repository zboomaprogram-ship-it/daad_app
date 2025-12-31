import 'package:daad_app/app.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/widgets/custom_button.dart';
import 'package:daad_app/features/auth/presentation/sign_in_screen.dart';
import 'package:daad_app/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': kLogoImage,
      'text': 'Design your dream space with interiors that reflect your style!',
    },
    {
      'image': kLogoImage,
      'text':
          'Find the perfect gift in our selection of designer decorative objects.',
    },
    {
      'image': kLogoImage,
      'text': 'We Deliver The Products You Bought To Your Door',
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      RouteUtils.pushReplacement(LoginScreen());
    }
  }

  void _skip() {
    RouteUtils.pushReplacement(LoginScreen());
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(onboardingData.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == index ? 30 : 7,
          height: 8,
          decoration: BoxDecoration(
          
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.h, 0, 24.w, 100.h),
          child: Column(
            children: [
              //Skip
              Align(
                alignment: Alignment.centerRight,
                child:
                    _currentPage < onboardingData.length - 1
                        ? TextButton(
                          onPressed: _skip,
                          child: const Text(
                            "Skip",
                            style: TextStyle(
                              fontSize: 18,
                             ),
                          ),
                        )
                        : SizedBox(height: 48.h),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          onboardingData[index]['image']!,
                          height: 200.h,
                          width: 250.w,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            onboardingData[index]['text']!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'roboto',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dots and Next/Done
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDots(),
                  AppButton(
                    btnText:
                        _currentPage == onboardingData.length - 1
                            ? "Done"
                            : "Next",
                    onTap: _nextPage,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18.h,
                      weight: 18.w,
                    ),
                    width: 104.w,
                    height: 50.h,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}