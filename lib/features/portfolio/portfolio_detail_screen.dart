import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:flutter/material.dart';

class PortfolioDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final dynamic imageUrl;   // ✅ allow list or single
  final String industry;
  final String createdAt;

  const PortfolioDetailScreen({
    Key? key,
    required this.title,
    required this.body,
    required this.imageUrl,  // ✅ dynamic works
    required this.industry,
    required this.createdAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(title: title,),
        backgroundColor: AppColors.backgroundColor,
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DaadImage(
              imageUrl,
              height: 300,
              width: double.infinity,
            ),
            const SizedBox(height: 16),

            AppText(
              title: title,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),

            AppText(
              title: 'الصناعة: $industry',
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            const SizedBox(height: 8),

            AppText(
              title: body,
              fontSize: 14,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
