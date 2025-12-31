import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:flutter/material.dart';

class PortfolioDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String imageUrl;
  final String industry;
  final String createdAt;

  const PortfolioDetailScreen({
    Key? key,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.industry,
    required this.createdAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض الصورة
            DaadImage(imageUrl),
            const SizedBox(height: 16),

            // العنوان
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),

            // الصناعة
            Text(
              'الصناعة: $industry',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            // الوصف
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // تاريخ الإنشاء
            Text(
              'تاريخ الإنشاء: $createdAt',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
