import 'package:flutter/material.dart';
import 'points_service.dart';

class PointsBadge extends StatefulWidget {
  const PointsBadge({super.key});
  @override
  State<PointsBadge> createState() => _PointsBadgeState();
}

class _PointsBadgeState extends State<PointsBadge> {
  int _points = 0;

  Future<void> _load() async {
    final p = await PointsService.getUserPoints();
    if (mounted) setState(() => _points = p);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: ActionChip(
        backgroundColor: Colors.transparent,
        label: Text('نقاطك: $_points'),
        avatar: const Icon(Icons.star),
        onPressed: () => _load(),
      ),
    );
  }
}
