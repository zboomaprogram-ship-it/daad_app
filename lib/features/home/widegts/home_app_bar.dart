import 'dart:ui';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/presentation/profile_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/search_screen_view.dart';
import 'package:daad_app/features/home/widegts/user_notifications_screen.dart';
import 'package:daad_app/features/loyalty/earn_points_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeAppBar extends StatelessWidget {
  final DocumentSnapshot? cachedUserData;

  HomeAppBar({super.key, this.cachedUserData});

  final TextEditingController _searchController = TextEditingController();

  Stream<int> _getUnreadNotificationsCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(2) // ✅ Limit query size
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final targetUserId = data['userId'];
            final readBy = List<String>.from(data['readBy'] ?? []);

            // Count if notification is for this user (or global) and not read
            if ((targetUserId == null || targetUserId == userId) &&
                !readBy.contains(userId)) {
              count++;
            }
          }
          return count;
        });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ Use cached data if available, otherwise show loading
    final userData = cachedUserData?.data() as Map<String, dynamic>?;
    final userName = userData?['name'] ?? 'مستخدم';
    final userPoints = userData?['points'] ?? 0;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // -------- User header --------
          Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              MediaQuery.of(context).padding.top + 10,
              0,
              16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar + Name
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: user?.photoURL != null
                              ? Image.network(
                                  user!.photoURL!,
                                  fit: BoxFit.cover,
                                  // ✅ Add caching
                                  cacheWidth: 50.w.toInt(),
                                  cacheHeight: 50.h.toInt(),
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 28.sp,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const AppText(
                          //   title: "صباح الخير!",
                          //   fontSize: 14,
                          //   color: Colors.white54,
                          //   fontWeight: FontWeight.w700,
                          // ),
                          AppText(
                            title: userName,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Points & Diamond
                Row(
                  children: [
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PointsRecordingScreen(),
                        ),
                      ),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 15,
                            ),
                            SizedBox(width: 4.w),
                            const AppText(
                              title: "نقاط الولاء",
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 6.w),
                            AppText(
                              title: userPoints.toString(),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // -------- Search bar + notification --------
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UnifiedSearchScreen(),
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    child: GlassSearchField(
                      controller: _searchController,
                      label: "ابحث عن المحتوى...",
                      icon: Icons.search,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              StreamBuilder<int>(
                stream: _getUnreadNotificationsCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GlassImageButton(
                        white: true,
                        imagePath: "assets/icons/bell.png",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserNotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.w,
                              ),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20.w,
                              minHeight: 20.h,
                            ),
                            child: Center(
                              child: AppText(
                                title: unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

// ============================================
// GLASS TEXT FIELD (Optimized)
// ============================================

class GlassSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final int? maxLines;
  final TextInputType? keyboardType;

  const GlassSearchField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final radius = 12.r;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.33),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            textAlign: TextAlign.right,
            onTap: onTap,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              hintText: label,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13.sp,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 18.sp,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 42.w,
                minHeight: 30.h,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
        ),
      ),
    );
  }
}
