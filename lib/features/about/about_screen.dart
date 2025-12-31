import 'package:daad_app/core/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/daad_image.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('من نحن'),leading: CustomBackButton(),),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            DaadImage(null, height: 160),
            SizedBox(height: 12),
            Text('شركة ضاد للتسويق — نبني لك حلولًا تسويقية متخصصة عبر المنطقة...'),
          ],
        ),
      ),
    );
  }
}
