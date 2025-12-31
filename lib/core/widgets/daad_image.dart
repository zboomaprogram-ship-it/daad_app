import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

class DaadImage extends StatelessWidget {
  final dynamic url;  // Can be a string or an array of strings
  final double? height;
  final double? width;
  final BoxFit fit;

  const DaadImage(
    this.url, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  bool _isBase64(String str) {
    // Check if string is Base64 (starts with common Base64 patterns)
    if (str.startsWith('data:image')) return true;
    if (str.startsWith('http://') || str.startsWith('https://')) return false;
    
    // Try to decode as Base64
    try {
      base64Decode(str);
      return true;
    } catch (e) {
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
    // Handle null or empty URL
    if (url == null || (url is String && url.isEmpty) || (url is List && url.isEmpty)) {
      return _buildPlaceholder();
    }

    // If the URL is an array (List), handle the first URL in the array
    if (url is List) {
      final firstUrl = url.first;
      if (_isBase64(firstUrl)) {
        return _buildBase64Image(firstUrl);
      } else {
        return _buildNetworkImage(firstUrl);
      }
    }

    // If it's a string, check if it's Base64 or a network URL
    final cleanUrl = url.toString().trim();
    if (_isBase64(cleanUrl)) {
      return _buildBase64Image(cleanUrl);
    }

    return _buildNetworkImage(cleanUrl);
  }

  Widget _buildBase64Image(String base64String) {
    try {
      final cleanBase64 = _cleanBase64(base64String);
      final imageBytes = base64Decode(cleanBase64);
      
      return Image.memory(
        imageBytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading Base64 image: $error');
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      debugPrint('Error decoding Base64: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (_, __) => _buildLoadingWidget(),
      errorWidget: (_, __, ___) => _buildErrorWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: height,
      width: width,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return CachedNetworkImage(
      imageUrl: kDefaultImage,
      height: height,
      width: width,
      fit: fit,
      errorWidget: (_, __, ___) => SizedBox(
        height: height,
        width: width,
        child: const Icon(Icons.broken_image, size: 50),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return CachedNetworkImage(
      imageUrl: kDefaultImage,
      height: height,
      width: width,
      fit: fit,
      placeholder: (_, __) => _buildLoadingWidget(),
      errorWidget: (_, __, ___) => SizedBox(
        height: height,
        width: width,
        child: const Icon(Icons.image, size: 50),
      ),
    );
  }
}
