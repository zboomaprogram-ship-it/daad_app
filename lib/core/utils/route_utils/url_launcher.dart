 
import 'package:daad_app/core/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherUtils {
  static Future<void> openExternalUrl(
    BuildContext context,
    String rawUrl,
  ) async {
    try {
      final encodedUrl = Uri.encodeFull(rawUrl);
      final url = Uri.parse(encodedUrl);

      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      showSnackBar('تعذر فتح الرابط', isError: true);
    }
  }

  static Future<void> openInApp(BuildContext context, String rawUrl) async {
    try {
      final encodedUrl = Uri.encodeFull(rawUrl);
      final url = Uri.parse(encodedUrl);

      final bool isLaunchable = await canLaunchUrl(url);
      if (!isLaunchable) {
        print('❌ Cannot launch URL: $url');
        showSnackBar('الرابط غير صالح', isError: true);
        return;
      }

      await launchUrl(
        url,
        mode: LaunchMode.inAppWebView, // داخل التطبيق
      );
    } catch (e) {
      print('🚨 Error launching URL: $e');
      showSnackBar('تعذر فتح الرابط', isError: true);
    }
  }
}
