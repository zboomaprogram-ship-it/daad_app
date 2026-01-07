import 'package:flutter/material.dart';

class CurvedNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double height = size.height;
    double width = size.width;

    Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..moveTo(0, height * 0.35) // بداية الانحناء
      ..quadraticBezierTo(
        width * 0.10,
        height * 0.10,
        width * 0.30,
        height * 0.20,
      )
      ..quadraticBezierTo(width * 0.50, height * 0.35, width * 0.50, 0)
      ..quadraticBezierTo(
        width * 0.50,
        height * 0.35,
        width * 0.70,
        height * 0.20,
      )
      ..quadraticBezierTo(width * 0.90, height * 0.10, width, height * 0.35)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
