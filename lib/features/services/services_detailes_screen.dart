import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:flutter/material.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final dynamic imageUrl; // This can be String or List<dynamic>
  final List<dynamic> priceTiers;

  const ServiceDetailScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.priceTiers,
  }) : super(key: key);

  // Function to handle image rendering (either Base64 or URL)
  Widget _buildImage() {
    if (imageUrl == null || imageUrl == '') {
      return _buildPlaceholderImage();  // Placeholder if no image
    }

    // If imageUrl is a list, use the first image URL or Base64 string
    if (imageUrl is List) {
      final firstImage = imageUrl.isNotEmpty ? imageUrl[0] : null;
      if (firstImage == null) return _buildPlaceholderImage();
      return DaadImage(firstImage);
    }

    // If imageUrl is a String, handle it (URL or Base64)
    return DaadImage(imageUrl);
  }

  // Placeholder image if no image URL is provided
  Widget _buildPlaceholderImage() {
    return CachedNetworkImage(
      imageUrl: kDefaultImage,  // Use a default placeholder image
      height: 200,  // Adjust as needed
      width: double.infinity,  // Adjust as needed
      fit: BoxFit.cover,
      placeholder: (_, __) => _buildLoadingWidget(),
      errorWidget: (_, __, ___) => _buildErrorWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: const Icon(Icons.broken_image, size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display image (Base64 or URL)
            _buildImage(),
            const SizedBox(height: 16),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Price Tiers
            Text(
              'السعر:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (var tier in priceTiers)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier['name'] ?? 'غير محدد',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'السعر: ${tier['price']} ريال',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (tier['features'] != null && tier['features'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'المميزات:',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        for (var feature in tier['features'])
                          Text(
                            '- $feature',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
