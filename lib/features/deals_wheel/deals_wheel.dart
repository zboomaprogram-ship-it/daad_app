// lib/features/deals_wheel/deals_wheel.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class DealsWheel extends StatefulWidget {
  const DealsWheel({super.key});
  @override
  State<DealsWheel> createState() => _DealsWheelState();
}

class _DealsWheelState extends State<DealsWheel> {
  final _selected = StreamController<int>();
  List<Map<String, dynamic>> items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final snap = await FirebaseFirestore.instance
        .collection('deals_wheel')
        .where('isActive', isEqualTo: true)
        .get();

    items = snap.docs.map((d) => d.data()).where((e) {
      final ts = e['startsAt'];
      final te = e['endsAt'];
      final okStart = ts == null || (ts is Timestamp && ts.toDate().isBefore(now));
      final okEnd = te == null || (te is Timestamp && te.toDate().isAfter(now));
      return okStart && okEnd;
    }).toList();

    setState(() => _loading = false);
  }

  int _pickWeightedIndex(List<num> weights) {
    final total = weights.fold<num>(0, (a, b) => a + b);
    final r = Random().nextDouble() * total;
    num cum = 0;
    for (var i = 0; i < weights.length; i++) {
      cum += weights[i];
      if (r <= cum) return i;
    }
    return 0;
  }

  void _giveReward(Map<String, dynamic> win) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('مبروك! خصم ${win['discountPercent'] ?? ''}%'),
        content: Text('العرض: ${win['label'] ?? 'عرض'}\nالكود: ${win['code'] ?? 'سيتم إرساله'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
      ),
    );
    // TODO: سجل الاستفادة + أضف نقاط إن رغبت
    // PointsService.addPoints(5, reason: 'wheel_spin');
  }

  void _spin() {
    if (items.length < 2) return; // حماية إضافية
    final weights = items.map<num>((e) => (e['weight'] ?? 1) as num).toList();
    final idx = _pickWeightedIndex(weights);
    _selected.add(idx);
    Future.delayed(const Duration(seconds: 2), () => _giveReward(items[idx]));
  }

  @override
  void dispose() {
    _selected.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (items.isEmpty) {
      // لا توجد عروض
      return const Text('لا توجد عروض متاحة الآن');
    }

    if (items.length == 1) {
      // خيار 1: امنح العرض مباشرة (بدون عجلة)
      final only = items.first;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(only['label'] ?? 'عرض', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('خصم ${only['discountPercent'] ?? ''}%'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _giveReward(only),
                child: const Text('احصل على العرض'),
              ),
              const SizedBox(height: 6),
              Text('**نصيحة**: أضف أكثر من عرض لتفعيل عجلة الحظ 😉',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );

      // خيار 2 (بديل): كرّر العنصر ليصبح 2 عناصر ويشتغل FortuneWheel
      // items = [only, {...only}];
    }

    // >= 2 عناصر → استخدم العجلة
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: FortuneWheel(
            animateFirst: false,
            selected: _selected.stream,
            items: [
              for (final e in items)
                FortuneItem(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(e['label'] ?? 'عرض', textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _spin, child: const Text('لف العجلة')),
      ],
    );
  }
}
