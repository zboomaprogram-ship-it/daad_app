// lib/screens/rewards_screen.dart
import 'dart:ui';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/loyalty/services/loyalty_service.dart';
import 'package:daad_app/features/home/widegts/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RewardsScreen extends StatelessWidget {
  RewardsScreen({Key? key}) : super(key: key);

  final service = LoyaltyService();

  void _showRedeemDialog(
    BuildContext context,
    String rewardId,
    String title,
    int required,
    int userPoints,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r)
,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r)
,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5.w
,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.white, size: 48),
                    SizedBox(height: 16.h
),
                    AppText(
                      title: 'استبدال: $title',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h
),
                    AppText(
                      title: 'سيتم خصم $required نقطة من رصيدك فوراً عند إرسال الطلب.',
                      fontSize: 14,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h
),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r)
,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 8.w
),
                          AppText(
                            title: 'النقاط الحالية: $userPoints',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h
),
                    AppText(
                      title: 'الرصيد بعد الاستبدال: ${userPoints - required}',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    SizedBox(height: 24.h
),
                    Row(
                      children: [
                        Expanded(
                          child: _GlassButton(
                            text: 'إلغاء',
                            onPressed: () => Navigator.pop(ctx),
                            isPrimary: false,
                          ),
                        ),
                         SizedBox(width: 12.w
),
                        Expanded(
                          child: _GlassButton(
                            text: 'تأكيد',
                            onPressed: () async {
                              final uid = FirebaseAuth.instance.currentUser!.uid;
                              final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
                              
                              try {
                                await FirebaseFirestore.instance.runTransaction((trx) async {
                                  final userSnap = await trx.get(userRef);
                                  final currentPoints = userSnap.data()?['points'] ?? 0;

                                  if (currentPoints < required) {
                                    throw Exception('رصيد النقاط غير كافٍ');
                                  }

                                  // Deduct points immediately
                                  trx.update(userRef, {'points': currentPoints - required});

                                  // Create redeem request
                                  final requestRef = FirebaseFirestore.instance.collection('redeem_requests').doc();
                                  trx.set(requestRef, {
                                    'userId': uid,
                                    'rewardId': rewardId,
                                    'rewardTitle': title,
                                    'requiredPoints': required,
                                    'status': 'pending',
                                    'date': FieldValue.serverTimestamp(),
                                  });
                                });

                                // Add history
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection('points_history')
                                    .add({
                                  'points': -required,
                                  'type': 'pending_redeem',
                                  'note': 'طلب استبدال قيد المراجعة: $title',
                                  'date': FieldValue.serverTimestamp(),
                                });

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: AppText(title: 'تم خصم النقاط وإرسال طلبك للمراجعة'),
                                    backgroundColor: Colors.green.withOpacity(0.8),
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: AppText(title: 'خطأ: ${e.toString()}'),
                                    backgroundColor: Colors.red.withOpacity(0.8),
                                  ),
                                );
                              }
                            },
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kBackgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, color: Colors.white, size: 48),
                  SizedBox(height: 16.h
),
                  AppText(
                    title: 'تسجيل الدخول مطلوب',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r)
,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r)
,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5.w
,
                              ),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                     SizedBox(width: 16.w
),
                    Expanded(
                      child: AppText(
                        title: 'المكافآت',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // User Points Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: service.userStream(user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return GlassCard(
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    final userData = snap.data?.data() as Map<String, dynamic>? ?? {};
                    final int userPoints = (userData['points'] as num?)?.toInt() ?? 0;

                    return GlassCard(
                      child: Column(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 48),
                          SizedBox(height: 12.h
),
                          AppText(
                            title: 'نقاطك',
                            fontSize: 14,
                          ),
                          SizedBox(height: 4.h
),
                          AppText(
                            title: '$userPoints',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: 8.h
),
                          AppText(
                            title: 'استبدل نقاطك بمكافآت رائعة',
                            fontSize: 12,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 16.h
),

              // Rewards List
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final userPoints = (userData['points'] as num?)?.toInt() ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rewards')
                        .snapshots(),
                    builder: (context, rewardsSnap) {
                      if (!rewardsSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final rewardDocs = rewardsSnap.data!.docs;

                      if (rewardDocs.isEmpty) {
                        return Center(
                          child: AppText(
                            title: "لا توجد مكافآت متاحة الآن",
                            fontSize: 16,
                          ),
                        );
                      }

                      return Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.all(12.r),
                          itemCount: rewardDocs.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h
),
                          itemBuilder: (ctx, i) {
                            final r = rewardDocs[i].data() as Map<String, dynamic>;
                            final rewardId = rewardDocs[i].id;
                            final title = r['title'] ?? "مكافأة";
                            final points = r['points'] ?? "points";
                            final required = (r['points'] as num).toInt();
                            final des = r['description'];
                            final percent = (userPoints / required * 100).clamp(0, 100).round();
                            final canRedeem = userPoints >= required;

                            return GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                       SizedBox(width: 12.w
),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              title: title,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            AppText(
                                              title: des,
                                              fontSize: 14,
                                            ),
                                            AppText(
                                              title: points.toString(),
                                              fontSize: 14,
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),

                                  SizedBox(height: 12.h
),

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r)
,
                                    child: LinearProgressIndicator(
                                      value: percent / 100,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        canRedeem ? Colors.green : Colors.amber,
                                      ),
                                      minHeight: 8.h
,
                                    ),
                                  ),

                                  SizedBox(height: 8.h
),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppText(
                                        title: 'نسبة الإتاحة: $percent%',
                                        fontSize: 12,
                                      ),
                                      _GlassButton(
                                        text: canRedeem ? 'استبدال' : 'غير متاح',
                                        onPressed: canRedeem
                                            ? () {
                                                _showRedeemDialog(
                                                  context,
                                                  rewardId,
                                                  title,
                                                  required,
                                                  userPoints,
                                                );
                                              }
                                            : null,
                                        isPrimary: canRedeem,
                                        isSmall: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isSmall;

  const _GlassButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r)
,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: isSmall ? 8 : 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: onPressed == null
                      ? [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ]
                      : isPrimary
                          ? [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.2),
                            ]
                          : [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                ),
                borderRadius: BorderRadius.circular(12.r)
,
                border: Border.all(
                  color: Colors.white.withOpacity(onPressed == null ? 0.1 : 0.2),
                  width: 1.5.w
,
                ),
              ),
              child: AppText(
                title: text,
                color: onPressed == null
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white,
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}