import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/features/home/home_screen.dart';
import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // الرجوع إلى الصفحة السابقة
        } else {
          RouteUtils.push(const HomeScreen()); // العودة إلى الصفحة الرئيسية إذا لم يكن هناك صفحات سابقة
        }
      },
    );
  }
}
