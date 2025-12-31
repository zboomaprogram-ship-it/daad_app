import 'dart:ui';
import 'package:flutter/material.dart';

// شاشاتك
import 'package:daad_app/features/home/home_screen.dart';
import 'package:daad_app/features/services/services_screen.dart';
import 'package:daad_app/features/articles/articles_screen.dart';
import 'package:daad_app/features/chatbot/presentation/chatbot_view.dart';

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
  final PageController _pageController = PageController();

  // فقط الصفحات الثلاثة اللي يقدر يسوايب بينهم
  final List<Widget> _pages = const [
    HomeScreen(),
    ServicesScreen(),
    ArticlesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
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

  void _onItemTapped(int index) {
    if (index == 3) {
      // اضغط على الشات بوت = Push لصفحة جديدة بدون Navbar
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const FloatingChatbot(),
        ),
      );
    } else {
      jumpToTab(index);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // الصفحات الثلاثة فقط
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _pages,
            ),
          ),

          // البار العائم بتأثير Liquid Glass
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + bottomPadding,
            child: _LiquidGlassBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _LiquidGlassBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottom > 0 ? 4 : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // المجموعة المتصلة بتأثير Liquid Glass
            Expanded(
              child: _AdaptiveLiquidGlassGroup(
                radius: 32,
                selectedIndex: selectedIndex,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavBarItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: selectedIndex == 0,
                      onTap: () => onItemTapped(0),
                    ),
                    _NavBarItem(
                      icon: Icons.apps_rounded,
                      label: 'Services',
                      isActive: selectedIndex == 1,
                      onTap: () => onItemTapped(1),
                    ),
                    _NavBarItem(
                      icon: Icons.article_rounded,
                      label: 'Articles',
                      isActive: selectedIndex == 2,
                      onTap: () => onItemTapped(2),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // زر الشات بوت منفصل بتأثير Liquid
            _LiquidGlassPill(
              width: 64,
              height: 64,
              radius: 22,
              child: GestureDetector(
                onTap: () => onItemTapped(3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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

/// Adaptive Liquid Glass Group - يتغير حسب التاب النشط
class _AdaptiveLiquidGlassGroup extends StatelessWidget {
  final Widget child;
  final double radius;
  final int selectedIndex;

  const _AdaptiveLiquidGlassGroup({
    required this.child,
    required this.selectedIndex,
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    // ألوان مختلفة لكل تاب - iOS 26 style

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox(height: 64, width: double.infinity),
          ),
          
          // Main container with adaptive gradient
          Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
    
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.8,
              ),
      
            ),
            child: Stack(
              children: [
                // Shine effect overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
                // Liquid ripple effect
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LiquidRipplePainter(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }


}

/// Liquid Glass Pill للشات بوت
class _LiquidGlassPill extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const _LiquidGlassPill({
    required this.child,
    this.width,
    this.height = 64,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: SizedBox(width: width, height: height),
          ),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
         
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 0.8,
              ),
           
            ),
            child: Stack(
              children: [
                // Top shine
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: (height ?? 64) * 0.4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.45),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter للتأثير السائل
class _LiquidRipplePainter extends CustomPainter {
  final Color color;

  _LiquidRipplePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 18 : 14,
          vertical: isActive ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: Colors.white,
                size: isActive ? 22 : 20,

              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isActive ? 0.3 : 0,
   
              ),
            ),
          ],
        ),
      ),
    );
  }
}