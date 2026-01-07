import 'dart:ui';

import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildGlassBottomSheet({
  required BuildContext context,
  required String title,
  required List<Widget> children,
}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7A4458), Color(0xFF5D3344), Color(0xFF4A2735)],
      ),
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.w),
              left: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
              right: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              right: 20,
              left: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  // Title
                  AppText(
                    title: title,

                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 24.h),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ==================== GLASS BUTTON ====================
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 50.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color != null
                  ? [color!.withOpacity(0.4), color!.withOpacity(0.3)]
                  : [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.w,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12.r),
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== GLASS SWITCH ====================
class GlassSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    String? subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: SwitchListTile(
            title: AppText(title: title),
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

// ==================== GLASS DROPDOWN ====================
class GlassDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const GlassDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: value,
              dropdownColor: const Color(0xFF5D3344),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.r),
              ),
              style: const TextStyle(color: Colors.white),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
