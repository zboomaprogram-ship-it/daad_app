import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPrimary
                ? [
                    Colors.transparent.withOpacity(0.2),
                    Colors.transparent.withOpacity(0.2),
                  ]
                : [
                    Colors.transparent.withOpacity(0.2),
                    Colors.transparent.withOpacity(0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.transparent, width: 1.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 6.w),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
