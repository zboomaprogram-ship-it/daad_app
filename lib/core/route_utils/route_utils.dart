import 'package:flutter/material.dart';

class RouteUtils {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // الدالة push لانتقال بين الصفحات
  static Future<dynamic> push(Widget view) {
    return navigatorKey.currentState!.push(_getRoute(view));
  }

  // الدالة pop للتراجع عن الصفحة
  static void pop() {
    navigatorKey.currentState!.pop();
  }

  // دالة لتبديل الصفحة الحالية
  static Future<dynamic> pushReplacement(Widget view) {
    return navigatorKey.currentState!.pushReplacement(_getRoute(view));
  }

  // دالة للتنقل بين الصفحات وازالة جميع الصفحات السابقة
  static Future<dynamic> pushAndPopAll(Widget view) {
    return navigatorKey.currentState!.pushAndRemoveUntil(_getRoute(view), (route) => false);
  }

  // توليد الـ Route مع الصفحة المطلوبة
  static Route _getRoute(Widget view) {
    return MaterialPageRoute(builder: (context) => view);
  }
}
