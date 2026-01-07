import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DaadImage extends StatelessWidget {
  final dynamic url; // Can be a string or an array of strings
  final double? height;
  final double? width;
  final BoxFit fit;

  const DaadImage(
    this.url, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  bool _isBase64(String str) {
    if (str.startsWith('data:image')) return true;
    if (str.startsWith('http://') || str.startsWith('https://')) return false;

    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _cleanBase64(String base64String) {
    return base64String
        .replaceAll('"', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    // Null or empty URL → placeholder
    if (url == null ||
        (url is String && url.isEmpty) ||
        (url is List && url.isEmpty)) {
      return _buildShimmerPlaceholder();
    }

    // Multiple images → carousel
    if (url is List) {
      return _buildCarousel(url);
    }

    // Single string image
    final cleanUrl = url.toString().trim();

    if (_isBase64(cleanUrl)) {
      return _buildBase64Image(cleanUrl);
    }

    return _buildNetworkImage(cleanUrl);
  }

  // ------------------------------------------
  // 🔄 Carousel with shimmer support
  // ------------------------------------------
  Widget _buildCarousel(List images) {
    final PageController controller = PageController();
    final bool showIndicator = images.length > 1;

    return SizedBox(
      height: height ?? double.infinity,
      width: width ?? double.infinity,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              itemBuilder: (_, index) {
                final img = images[index];
                return _isBase64(img)
                    ? _buildBase64Image(img)
                    : _buildNetworkImage(img);
              },
            ),
          ),

          if (showIndicator) ...[
            SizedBox(height: 6.h),
            SmoothPageIndicator(
              controller: controller,
              count: images.length,
              effect: CustomizableEffect(
                spacing: 6,
                dotDecoration: DotDecoration(
                  width: 10.w,
                  height: 4.h,
                  color: AppColors.secondaryColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                activeDotDecoration: DotDecoration(
                  width: 26.w,
                  height: 4.h,
                  color: AppColors.secondaryTextColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------
  // 🧩 Base64 Image (with shimmer)
  // ------------------------------------------
  Widget _buildBase64Image(String base64String) {
    try {
      final cleanBase64 = _cleanBase64(base64String);
      final imageBytes = base64Decode(cleanBase64);

      return Image.memory(
        imageBytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildShimmerPlaceholder(),
      );
    } catch (e) {
      return _buildShimmerPlaceholder();
    }
  }

  // ------------------------------------------
  // 🌐 Network Image (shimmer while loading)
  // ------------------------------------------
  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (_, __) => _buildShimmerPlaceholder(),
      errorWidget: (_, __, ___) => _buildErrorWidget(),
    );
  }

  // ------------------------------------------
  // ✨ Shimmer Placeholder
  // ------------------------------------------
  Widget _buildShimmerPlaceholder() {
    return ShimmerLoading(
      child: ShimmerBox(
        width: width ?? double.infinity,
        height: height ?? 180.h,
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }

  // ------------------------------------------
  // ❌ Error Placeholder
  // ------------------------------------------
  Widget _buildErrorWidget() {
    return ShimmerLoading(
      child: ShimmerBox(
        width: width ?? double.infinity,
        height: height ?? 180.h,
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }
}
