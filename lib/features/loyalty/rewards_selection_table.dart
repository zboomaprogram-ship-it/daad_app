import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class RewardsSelectionTable extends StatefulWidget {
  final int userPoints;
  final List<Map<String, dynamic>> rewards;
  final Function(List<Map<String, dynamic>>) onSelectionChanged;

  const RewardsSelectionTable({
    super.key,
    required this.userPoints,
    required this.rewards,
    required this.onSelectionChanged,
  });

  @override
  State<RewardsSelectionTable> createState() => _RewardsSelectionTableState();
}

class _RewardsSelectionTableState extends State<RewardsSelectionTable> {
  final Set<int> _selectedIndexes = {};
  int _temporaryDeductedPoints = 0;

  int _calculateAvailabilityPercent(int required, int available) {
    if (required <= 0) return 0;
    return ((available / required) * 100).clamp(0, 100).toInt();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }

      _temporaryDeductedPoints = 0;
      for (var idx in _selectedIndexes) {
        final reward = widget.rewards[idx];
        final rawReq = reward['requiredPoints'] ?? reward['points'] ?? 0;
        int required;
        if (rawReq is num) {
          required = rawReq.toInt();
        } else if (rawReq is String) {
          required = int.tryParse(rawReq) ?? 0;
        } else {
          required = 0;
        }
        _temporaryDeductedPoints += required;
      }

      final selectedRewards = _selectedIndexes
          .map((idx) => widget.rewards[idx])
          .toList();
      widget.onSelectionChanged(selectedRewards);
    });
  }

  @override
  Widget build(BuildContext context) {
    final availablePoints = widget.userPoints - _temporaryDeductedPoints;

    return _GlassPanel(
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1.w),
              ),
            ),
            child: Row(
              children: [
                // Left: Percentage badge
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        widget.rewards.isEmpty
                            ? '0%'
                            : '${_calculateAvailabilityPercent((widget.rewards.first['requiredPoints'] ?? 100) is num ? (widget.rewards.first['requiredPoints'] ?? 100).toInt() : int.tryParse(widget.rewards.first['requiredPoints'].toString()) ?? 100, availablePoints)}%',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                // Divider
                Container(height: 40.h, width: 1.5.w, color: Colors.white24),
                // Right: Title
                Expanded(
                  child: Center(
                    child: Text(
                      'الفرص المتاحة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Compact Rewards list
          ...List.generate(widget.rewards.length, (index) {
            final reward = widget.rewards[index];
            final rawReq = reward['requiredPoints'] ?? reward['points'] ?? 0;
            int required;
            if (rawReq is num) {
              required = rawReq.toInt();
            } else if (rawReq is String) {
              required = int.tryParse(rawReq) ?? 0;
            } else {
              required = 0;
            }

            final percent = _calculateAvailabilityPercent(
              required,
              availablePoints,
            );
            final title = reward['title'] ?? reward['name'] ?? 'مكافأة';
            final isSelected = _selectedIndexes.contains(index);
            final canAfford = availablePoints >= required;

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: index < widget.rewards.length - 1
                      ? BorderSide(color: Colors.white24, width: 1.w)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  // Left: Compact Progress bar
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Column(
                        children: [
                          // Smaller Progress bar
                          Stack(
                            children: [
                              // Background
                              Container(
                                height: 24.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              // Progress fill
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerRight,
                                    widthFactor: percent / 100,
                                    child: Container(
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: [
                                            AppColors.secondaryTextColor,
                                            AppColors.primaryColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Percentage text
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, c) {
                                    const pillW = 40.0;
                                    final maxRight = (c.maxWidth - pillW).clamp(
                                      0.0,
                                      double.infinity,
                                    );
                                    final rightPos =
                                        (maxRight * (percent / 100)).clamp(
                                          0.0,
                                          maxRight,
                                        );

                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: rightPos,
                                        ),
                                        child: SizedBox(
                                          width: pillW,
                                          child: Text(
                                            '$percent%',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: percent > 40
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          // Smaller required points text
                          Text(
                            'مطلوب: $required نقطة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Divider
                  Container(height: 60.h, width: 1.5.w, color: Colors.white24),
                  // Right: Compact Title + Checkbox
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 15.h,
                      ),
                      child: Row(
                        children: [
                          // Title
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Expanded(
                              child: Text(
                                title,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: canAfford
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 10.sp,
                                  height: 1.3,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // SizedBox(width: 3.w),
                          // Smaller Checkbox
                          Transform.scale(
                            scale: 0.75,
                            child: Theme(
                              data: ThemeData(
                                unselectedWidgetColor: Colors.white54,
                              ),
                              child: Checkbox(
                                value: isSelected,
                                onChanged: canAfford
                                    ? (bool? value) {
                                        _toggleSelection(index);
                                      }
                                    : null,
                                activeColor: Colors.green,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white54,
                                  width: 1.5.w,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Compact Footer
          if (_temporaryDeductedPoints > 0) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: Colors.white24, width: 1.w),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نقاطك الحالية: ${widget.userPoints}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        'سيُخصم: $_temporaryDeductedPoints',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'المتبقي: $availablePoints',
                    style: TextStyle(
                      color: availablePoints >= 0 ? Colors.green : Colors.red,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.4.w,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
