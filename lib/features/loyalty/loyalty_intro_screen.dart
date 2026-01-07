import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/loyalty/earn_points_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoyaltyIntroScreen extends StatefulWidget {
  const LoyaltyIntroScreen({super.key});

  @override
  State<LoyaltyIntroScreen> createState() => _LoyaltyIntroScreenState();
}

class _LoyaltyIntroScreenState extends State<LoyaltyIntroScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _error;

  List<_ActivityItem> _activities = [];
  List<_RewardItem> _rewards = [];
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // ===== Activities =====
      final activitiesSnap = await _db
          .collection('activities')
          .orderBy('points')
          .get();

      final activities = <_ActivityItem>[];
      for (final doc in activitiesSnap.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString();

        dynamic pointsRaw = data['points'];
        int points = 0;
        if (pointsRaw is num) {
          points = pointsRaw.toInt();
        } else if (pointsRaw is String) {
          points = int.tryParse(pointsRaw) ?? 0;
        }

        activities.add(_ActivityItem(title: title, points: points));
      }

      // ===== Rewards =====
      final rewardsSnap = await _db.collection('rewards').get();

      final rewards = <_RewardItem>[];
      for (final doc in rewardsSnap.docs) {
        final data = doc.data();
        final title = (data['title'] ?? data['name'] ?? '').toString();

        dynamic pointsRaw = data['requiredPoints'] ?? data['points'];
        int requiredPoints = 0;
        if (pointsRaw is num) {
          requiredPoints = pointsRaw.toInt();
        } else if (pointsRaw is String) {
          requiredPoints = int.tryParse(pointsRaw) ?? 0;
        }

        rewards.add(_RewardItem(title: title, requiredPoints: requiredPoints));
      }

      // ===== User points =====
      int userPoints = 0;
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        if (data != null) {
          final raw = data['points'];
          if (raw is num) {
            userPoints = raw.toInt();
          } else if (raw is String) {
            userPoints = int.tryParse(raw) ?? 0;
          }
        }
      }

      setState(() {
        _activities = activities;
        _rewards = rewards;
        _userPoints = userPoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const GlassBackButton(),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kAuthBackgroundImage),
              fit: BoxFit.cover,
              // colorFilter: ColorFilter.mode(
              //   Colors.black.withOpacity(0.25),
              //   BlendMode.srcATop,
              // ),
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const LoyaltyIntroShimmer()
                : _error != null
                ? Center(
                    child: Text(
                      'حدث خطأ في تحميل البيانات\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // SizedBox(height: 10.h),

                        // ===== Logo + Title =====
                        Container(
                          padding: EdgeInsets.all(8.r),
                          child: Image.asset(kLogoImage, height: 60, width: 60),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'نظام الولاء - ضاد بلس',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 80.h),

                        // ===== Intro paragraph =====
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'يهدف نظام الولاء إلى الترابط القوي بين ضاد وعملائها بهدف التعاون المثمر للطرفين، حيث يمنح للعملاء فرص وخصومات على الخدمات بشروط سلسة ومبسطة.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // ===== Activities section =====
                        _SectionCard(
                          title: 'آلية تجميع النقاط',
                          leftHeader: 'عدد النقاط',
                          rightHeader: 'النشاط',
                          rows: _activities
                              .map(
                                (a) => _TwoColumnRowData(
                                  right: a.title,
                                  left: '${a.points} نقاط',
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: 24.h),

                        // ===== Rewards section =====
                        _SectionCard(
                          title: 'المكافآت حسب عدد النقاط',
                          leftHeader: 'عدد النقاط',
                          rightHeader: 'المكافأة',
                          rows: _rewards
                              .map(
                                (r) => _TwoColumnRowData(
                                  right: r.title,
                                  left: '${r.requiredPoints} نقطة',
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: 24.h),

                        // ===== How it works =====
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'طريقة التسجيل والمتابعة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'يتم تسجيل عدد التفاعلات والمشاركات مع إرسال إثبات (سواء كان صورة أو لينك)، يتم حسابها بشكل مبدئي إلكترونياً، ثم يتم مراجعتها من خلال فريق المراجعة، يتمكن العميل من اختيار فرص الخصومات إذا وصل للحد المطلوب، ثم طلب اجتماع عاجل.',
                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.9,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 32.h),

                        // ===== New points button =====
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PointsRecordingScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                            ),
                            child: Text(
                              'تسجيل نقاط جديدة',
                              style: TextStyle(
                                color: const Color(0xFF5A1735),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Current user points
                        if (_auth.currentUser != null)
                          Text(
                            'نقاطك الحالية: $_userPoints',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final int points;

  _ActivityItem({required this.title, required this.points});
}

class _RewardItem {
  final String title;
  final int requiredPoints;

  _RewardItem({required this.title, required this.requiredPoints});
}

/// Glass card for sections - styled exactly like the screenshot
class _SectionCard extends StatelessWidget {
  final String title;
  final String rightHeader;
  final String leftHeader;
  final List<_TwoColumnRowData> rows;

  const _SectionCard({
    super.key,
    required this.title,
    required this.rightHeader,
    required this.leftHeader,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              // Title header with dark maroon background
              Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Column headers and data rows in a stack with continuous vertical line
              Stack(
                children: [
                  // Continuous vertical divider line
                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.58,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),

                  // Content
                  Column(
                    children: [
                      // Column headers
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 16.w,
                        ),
                        decoration: BoxDecoration(
                          // color: Colors.black.withOpacity(0.2),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                rightHeader,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            const SizedBox(width: 1), // Space for the line
                            SizedBox(width: 12.w),
                            Expanded(
                              flex: 2,
                              child: Text(
                                leftHeader,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Data rows
                      ...rows.asMap().entries.map((entry) {
                        // final isLast = entry.key == rows.length - 1;
                        final row = entry.value;
                        return Container(
                          decoration: const BoxDecoration(
                            // border: !isLast
                            //     ? Border(
                            //         bottom: BorderSide(
                            //           color: Colors.white.withOpacity(0.15),
                            //           width: 1,
                            //         ),
                            //       )
                            //     : null,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 16.w,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    row.right,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 9.sp,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                const SizedBox(width: 1), // Space for the line
                                SizedBox(width: 12.w),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    row.left,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 9.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TwoColumnRowData {
  final String right;
  final String left;

  _TwoColumnRowData({required this.right, required this.left});
}
