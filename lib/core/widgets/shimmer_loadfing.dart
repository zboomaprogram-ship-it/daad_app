import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// =====================
/// SHIMMER LOADING BASE
/// =====================
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// =====================
/// REUSABLE COMPONENTS
/// =====================
class ShimmerComponents {
  static Widget box({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height ?? 50.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
      ),
    );
  }

  static Widget circle({double size = 50}) {
    return Container(
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget textLine({
    double width = double.infinity,
    double height = 16,
  }) {
    return Container(
      width: width.w,
      height: height.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  static Widget glassTextField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.45),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: Colors.white.withOpacity(0.3), size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(child: textLine(width: double.infinity)),
        ],
      ),
    );
  }

  static Widget loginFormShimmer() {
    return Column(
      children: [
        glassTextField(),
        SizedBox(height: 16.h),
        glassTextField(),
        SizedBox(height: 32.h),
        box(width: double.infinity, height: 50.h),
      ],
    );
  }

  static Widget signupFormShimmer() {
    return Column(
      children: [
        glassTextField(),
        SizedBox(height: 16.h),
        glassTextField(),
        SizedBox(height: 16.h),
        glassTextField(),
        SizedBox(height: 16.h),
        glassTextField(),
        SizedBox(height: 16.h),
        glassTextField(),
        SizedBox(height: 24.h),
        box(width: double.infinity, height: 50.h),
        SizedBox(height: 16.h),
        box(width: double.infinity, height: 50.h),
      ],
    );
  }
}

/// =====================
/// FIXED SHIMMER BOX
/// =====================
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool isCircle;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.isCircle = false,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle
                ? null
                : (widget.borderRadius ?? BorderRadius.circular(12.r)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// =====================
/// LIST SHIMMER ITEM
/// =====================
class ShimmerListItem extends StatelessWidget {
  final double height;

  const ShimmerListItem({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120.w, height: 16.h),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: 80.w, height: 12.h),
                  SizedBox(height: 12.h),
                  ShimmerBox(width: double.infinity, height: 10.h),
                  SizedBox(height: 6.h),
                  ShimmerBox(width: double.infinity, height: 10.h),
                  const Spacer(),
                  Row(
                    children: [
                      ShimmerBox(width: 40.w, height: 20.h),
                      SizedBox(width: 14.w),
                      ShimmerBox(width: 40.w, height: 20.h),
                      SizedBox(width: 14.w),
                      ShimmerBox(width: 40.w, height: 20.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// GRID SHIMMER ITEM
/// =====================
class ShimmerGridItem extends StatelessWidget {
  const ShimmerGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBox(width: 60.w, height: 60.h, isCircle: true),
          SizedBox(height: 14.h),
          ShimmerBox(width: 100.w, height: 16.h),
        ],
      ),
    );
  }
}
class LearnDaadShimmerList extends StatelessWidget {
  const LearnDaadShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, i) {
        return _ShimmerLearnCard();
      },
    );
  }
}

class _ShimmerLearnCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double thumb = 150.w;

    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(26.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160.w, height: 20.h),
                    SizedBox(height: 8.h),
                    ShimmerBox(width: 100.w, height: 14.h),
                    SizedBox(height: 14.h),
                    ShimmerBox(width: double.infinity, height: 14.h),
                    SizedBox(height: 6.h),
                    ShimmerBox(width: double.infinity, height: 14.h),
                    SizedBox(height: 6.h),
                    ShimmerBox(width: double.infinity, height: 14.h),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        ShimmerBox(width: 40.w, height: 20.h),
                        SizedBox(width: 10.w),
                        ShimmerBox(width: 40.w, height: 20.h),
                        SizedBox(width: 10.w),
                        ShimmerBox(width: 40.w, height: 20.h),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              ShimmerBox(width: thumb, height: thumb, borderRadius: BorderRadius.circular(40.r)),
            ],
          ),
        ),
      ),
    );
  }
}
class LearnDetailsShimmer extends StatelessWidget {
  const LearnDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaH = 180.h;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        ShimmerBox(
          width: double.infinity,
          height: mediaH,
          borderRadius: BorderRadius.circular(26.r),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
            SizedBox(width: 20.w),
            ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
            SizedBox(width: 20.w),
            ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
          ],
        ),
        SizedBox(height: 24.h),
        ShimmerBox(width: double.infinity, height: 200.h),
      ],
    );
  }
}
class PointsRecordingShimmer extends StatelessWidget {
  const PointsRecordingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ...List.generate(2, (_) => _ActivityShimmer()),
          SizedBox(height: 20.h),
          _SummaryShimmer(),
          SizedBox(height: 20.h),
          _RewardsShimmer(),
        ],
      ),
    );
  }
}

class _ActivityShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.white.withOpacity(0.06),
        ),
        child: Column(
          children: [
            ShimmerBox(width: 200.w, height: 20.h),
            SizedBox(height: 20.h),
            ShimmerBox(width: double.infinity, height: 60.h),
            SizedBox(height: 20.h),
            ShimmerBox(width: double.infinity, height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _SummaryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ShimmerBox(width: double.infinity, height: 80.h),
    );
  }
}

class _RewardsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ShimmerBox(width: double.infinity, height: 60.h),
        ),
      ),
    );
  }
}
class LoyaltyIntroShimmer extends StatelessWidget {
  const LoyaltyIntroShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          ShimmerBox(width: 80.w, height: 80.h, isCircle: true),
          SizedBox(height: 20.h),
          ShimmerBox(width: 200.w, height: 25.h),
          SizedBox(height: 30.h),
          _TableShimmer(),
          SizedBox(height: 24.h),
          _TableShimmer(),
          SizedBox(height: 24.h),
          ShimmerBox(width: double.infinity, height: 50.h),
        ],
      ),
    );
  }
}

class _TableShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: ShimmerBox(width: double.infinity, height: 20.h),
            ),
          ),
        ),
      ),
    );
  }
}
