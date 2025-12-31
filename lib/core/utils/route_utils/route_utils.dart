import 'package:flutter/material.dart';

class RouteUtils {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext context = navigatorKey.currentState!.context;

  static Future<dynamic> push(Widget view) {
    return Navigator.of(context).push(_getRoute(view));
  }

  static void pop() {
    Navigator.of(context).pop();
  }

  static Future<dynamic> puAshReplacement(Widget view) {
    return Navigator.of(context).pushReplacement(_getRoute(view));
  }

  static Future<dynamic> pushAndPopAll(Widget view) {
    return Navigator.of(
      context,
    ).pushAndRemoveUntil(_getRoute(view), (route) => false);
  }

  static Route _getRoute(Widget view) {
    return MaterialPageRoute(builder: (context) => view);
  }
}
