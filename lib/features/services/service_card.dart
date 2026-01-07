import 'dart:ui';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String serviceId;
  final VoidCallback onViewDetails;

  const ServiceCard({
    super.key,
    required this.data,
    required this.serviceId,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? 'خدمة';
    final String desc = data['desc'] ?? '';
    final dynamic imageUrl = data['imageUrl'];

    return GestureDetector(
      onTap: onViewDetails,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.transparent, width: 1.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// IMAGE — same style as PortfolioCard
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: DaadImage(imageUrl, fit: BoxFit.cover),
                  ),
                ),

                /// TEXT AREA
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          title: title,

                          fontWeight: FontWeight.bold,

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          title: desc,

                          fontSize: 13,

                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
