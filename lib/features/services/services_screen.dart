import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:daad_app/features/home/widegts/home_app_bar.dart';
import 'package:daad_app/features/services/services_detailes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with AutomaticKeepAliveClientMixin {
  DocumentSnapshot? _cachedUserData;
  bool _isInitialized = false;
  List<DocumentSnapshot>? _cachedServices;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        FirebaseFirestore.instance
            .collection('services')
            .where('category', isEqualTo: 'main')
            .get(),
      ]);

      _cachedUserData = results[0] as DocumentSnapshot;
      _cachedServices = (results[1] as QuerySnapshot).docs;

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  void _viewServiceDetails(BuildContext context, String serviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(serviceId: serviceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kBackgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: _buildShimmerLoading(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                HomeAppBar(cachedUserData: _cachedUserData),
                SliverPadding(
                  padding: EdgeInsets.all(0.r),
                  sliver: _cachedServices == null || _cachedServices!.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: AppText(
                              title: "لا توجد خدمات",
                              color: Colors.white,
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final doc = _cachedServices![i];
                              final data = doc.data() as Map<String, dynamic>;

                              return _ServiceCard(
                                data: data,
                                serviceId: doc.id,
                                onTap: () => _viewServiceDetails(context, doc.id),
                              );
                            },
                            childCount: _cachedServices!.length,
                          ),
                        ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 60.h)),
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
                  ShimmerBox(width: 120.w, height: 20.h),
                  ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const ShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                ),
                childCount: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add _ShimmerBox widget from previous examples
// Add _ServiceCard widget (same as original)

// Separated widget for better performance
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String serviceId;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.data,
    required this.serviceId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'خدمة';
    final desc = data['desc'] ?? '';
    final imageUrl = data['images'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.20),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: SizedBox(
                height: 150.h,
                child: DaadImage(imageUrl, fit: BoxFit.cover),
              ),
            ),

            // CONTENT
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title: title,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    const AppText(
                      title: "الخدمات",
                      fontSize: 10,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: 2.h),
                    AppText(
                      title: desc,
                      fontSize: 10,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: "التفاصيل",
                            onTap: onTap,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _ActionButton(
                            text: "اشترك",
                            isPrimary: false,
                            onTap: onTap,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.text,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:   EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primaryColor
              : AppColors.textColor,
          borderRadius: BorderRadius.circular(8.r),
          // border: isPrimary
              // ? null
              // : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: AppText(
          title: text,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isPrimary
              ? AppColors.textColor
              : AppColors.primaryColor,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}