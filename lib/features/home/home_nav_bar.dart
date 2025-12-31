import 'dart:ui';

import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/route_utils/url_launcher.dart';
import 'package:daad_app/features/articles/articles_screen.dart';
import 'package:daad_app/features/chatbot/presentation/chatbot_view.dart';
import 'package:daad_app/features/home/home_screen.dart';
import 'package:daad_app/features/services/services_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeNavigationBar extends StatefulWidget {
  const HomeNavigationBar({super.key, this.selectedIndex = 0});
  final int selectedIndex;

  static _HomeNavigationBarState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HomeNavigationBarState>();

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar> {
  late int _selectedIndex;
  late final PageController _pageController;
  bool _isSocialOpen = false;

  final List<Widget> _pages = const [
    HomeScreen(),
    ServicesScreen(),
    ArticlesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void jumpToTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _toggleSocial() => setState(() => _isSocialOpen = !_isSocialOpen);

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChatBotScreen()));
      return;
    }
    jumpToTab(index);
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _pages,
              ),
            ),

            // ✅ Overlay شفاف فقط (بدون سواد)، ويكون تحت الـ BottomNav
            if (_isSocialOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleSocial,
                  child: const SizedBox.expand(),
                ),
              ),

            // ✅ مهم: نعطي مساحة كافية للـ hit-test عشان أزرار السوشيال تنضغط
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: _isSocialOpen ? 520.h : 110.h,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CustomBottomNavBar(
                    selectedIndex: _selectedIndex,
                    onItemTapped: _onItemTapped,
                    isSocialOpen: _isSocialOpen,
                    onSocialToggle: _toggleSocial,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isSocialOpen;
  final VoidCallback onSocialToggle;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isSocialOpen,
    required this.onSocialToggle,
  });

  @override
  Widget build(BuildContext context) {
    const barOuterPadding = 16.0;

    final barHeight = 70.h;
    final fabSize = 66.w;

    // ✅ نزّل/ارفع الـ FAB شوي لو تحتاج
    final fabBottom =
        (barOuterPadding + (barHeight - fabSize / 2)).h; // تقريبًا مثل 55h

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // ===================== NAV BAR (WAVE NOTCH) =====================
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.all(barOuterPadding.r),
            child: SizedBox(
              height: barHeight,
              child: ClipPath(
                clipper: WaveNotchClipper(
                  cornerRadius: 28.r,

                  // ✅ هنا تعدّل شكل النوتش (الأهم)
                  notchWidth: 50.w,
                  notchDepth: 14.h,

                  shoulderWidth: 80.w,
                  shoulderDepth: 24.h,

                  // ✅ يزيل “pin” في المنتصف (سطح صغير بدل نقطة)
                  plateauWidth: 36.w,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xff3F091B).withOpacity(0.55),
                            const Color(0xff1C020B).withOpacity(0.12),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.25),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            image: 'assets/icons/home1.png',
                            label: 'الصفحة الرئيسية',
                            index: 0,
                          ),
                          _buildNavItem(
                            image: 'assets/icons/services1.png',
                            label: 'الخدمات',
                            index: 1,
                          ),
                          SizedBox(width: 66.w), // Space for FAB
                          _buildNavItem(
                            image: 'assets/icons/content.png',
                            label: 'المقالات',
                            index: 2,
                          ),
                          _buildNavItem(
                            image: 'assets/icons/message.png',
                            label: 'مساعد ضاد',
                            index: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ===================== SOCIAL STACK + FAB =====================
        Positioned(
          bottom: fabBottom,
          child: SizedBox(
            width: 80.w,
            height: isSocialOpen ? 420.h : 80.h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                if (isSocialOpen) ...[
                  _buildSocialButton(
                    context: context,
                    icon: FontAwesomeIcons.globe,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.textColor],
                    ),
                    bottom: 350.h,
                    url: 'https://daadagency.com/',
                  ),
                  _buildSocialButton(
                    context: context,
                    icon: FontAwesomeIcons.linkedin,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0077B5), Color(0xFF00A0DC)],
                    ),
                    bottom: 280.h,
                    url: 'https://www.linkedin.com/company/daadagency/',
                  ),
                  _buildSocialButton(
                    context: context,
                    icon: FontAwesomeIcons.instagram,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFCAF45),
                        Color(0xFFF77737),
                        Color(0xFFE1306C),
                        Color(0xFFC13584),
                        Color(0xFF833AB4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    bottom: 210.h,
                    url:
                        'https://www.instagram.com/daad_agency_official?igsh=MWxyYWM5YjRjdDkxZg==',
                  ),
                  _buildSocialButton(
                    context: context,
                    icon: FontAwesomeIcons.facebookF,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1877F2), Color(0xFF1877F2)],
                    ),
                    bottom: 140.h,
                    url: 'https://www.facebook.com/daaadagency/',
                  ),
                  _buildSocialButton(
                    context: context,
                    icon: FontAwesomeIcons.tiktok,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF000000), Color(0xFF010101)],
                    ),
                    bottom: 70.h,
                    url: 'https://www.tiktok.com/@daad_agency',
                  ),
                ],

                // MAIN FAB
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSocialToggle,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 66.h,
                        width: 66.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF670A27), Color(0xFF361620)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10.0.h),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 250),
                            turns: isSocialOpen ? 0.125 : 0,
                            child: Image.asset(
                              'assets/icons/social-media.png',
                              width: 28.w,
                              height: 28.h,

                              color: Colors.white,
                              scale: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required String image,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onItemTapped(index),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                image,
                height: isSelected ? 26.h : 22.h,
                width: isSelected ? 26.w : 22.w,
                color: isSelected ? const Color(0xffDFD8BC) : Colors.white70,
              ),
              SizedBox(height: 4.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xffDFD8BC)
                        : Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: 'Arial',
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required Gradient gradient,
    required double bottom,
    required String url,
  }) {
    return Positioned(
      bottom: bottom,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (_, v, child) => Transform.scale(
          scale: v,
          child: Opacity(opacity: v, child: child),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              try {
                // ✅ افتح الرابط (بدون canLaunchUrl لأنه أحيانًا يرجّع false)
                await UrlLauncherUtils.openExternalUrl(context, url);
              } catch (_) {}
              // ✅ اقفل القائمة بعد الفتح (اختياري)
              onSocialToggle();
            },
            child: Container(
              height: 56.h,
              width: 56.w,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===================== WAVE NOTCH CLIPPER =====================
/// ✅ موجة ناعمة + plateau لمنع “pin” في الوسط
class WaveNotchClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchWidth;
  final double notchDepth;
  final double shoulderWidth;
  final double shoulderDepth;
  final double plateauWidth;

  WaveNotchClipper({
    required this.cornerRadius,
    required this.notchWidth,
    required this.notchDepth,
    required this.shoulderWidth,
    required this.shoulderDepth,
    required this.plateauWidth,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final c = w / 2;
    final half = notchWidth / 2;

    final left = c - half;
    final right = c + half;

    final plateauHalf = plateauWidth / 2;

    final p = Path();

    // Top-left rounded corner
    p.moveTo(0, cornerRadius);
    p.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Flat top to left shoulder
    p.lineTo(left - shoulderWidth, 0);

    // Shoulder dip down
    p.quadraticBezierTo(left - shoulderWidth * 0.45, 0, left, shoulderDepth);

    // Main wave down to plateau (left side)
    p.cubicTo(
      left + half * 0.20,
      shoulderDepth + (notchDepth - shoulderDepth) * 0.85,
      c - plateauHalf - half * 0.10,
      notchDepth,
      c - plateauHalf,
      notchDepth,
    );

    // ✅ Plateau (prevents the pointy pin)
    p.lineTo(c + plateauHalf, notchDepth);

    // Main wave up (right side)
    p.cubicTo(
      c + plateauHalf + half * 0.10,
      notchDepth,
      right - half * 0.20,
      shoulderDepth + (notchDepth - shoulderDepth) * 0.85,
      right,
      shoulderDepth,
    );

    // Shoulder back to top
    p.quadraticBezierTo(
      right + shoulderWidth * 0.45,
      0,
      right + shoulderWidth,
      0,
    );

    // Top-right rounded corner
    p.lineTo(w - cornerRadius, 0);
    p.quadraticBezierTo(w, 0, w, cornerRadius);

    // Right side down
    p.lineTo(w, h - cornerRadius);
    p.quadraticBezierTo(w, h, w - cornerRadius, h);

    // Bottom
    p.lineTo(cornerRadius, h);
    p.quadraticBezierTo(0, h, 0, h - cornerRadius);

    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant WaveNotchClipper old) {
    return cornerRadius != old.cornerRadius ||
        notchWidth != old.notchWidth ||
        notchDepth != old.notchDepth ||
        shoulderWidth != old.shoulderWidth ||
        shoulderDepth != old.shoulderDepth ||
        plateauWidth != old.plateauWidth;
  }
}
