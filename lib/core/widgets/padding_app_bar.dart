import 'package:flutter/material.dart';

class PaddingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppBar appBar;
  final double height;

  const PaddingAppBar({super.key, required this.appBar, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: appBar,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}