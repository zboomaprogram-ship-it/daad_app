import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/features/articles/articles_screen.dart';
import 'package:daad_app/features/auth/presentation/profile_screen.dart';
import 'package:daad_app/features/chatbot/presentation/chatbot_view.dart';
import 'package:daad_app/features/contact/contact_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/glass_card.dart';
import 'package:daad_app/features/home/widegts/glass_circle_avatar.dart';
import 'package:daad_app/features/home/widegts/glass_navigation_card.dart';
import 'package:daad_app/features/portfolio/portfolio_screen.dart';
import 'package:daad_app/features/services/remote_config_service.dart';
import 'package:daad_app/features/services/services_screen.dart';
import 'package:daad_app/features/works/works_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/daad_image.dart';
import '../deals_wheel/deals_wheel.dart';
import '../loyalty/points_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  Future<DocumentSnapshot> fetchUserData(String uid) async {
    final _db = FirebaseFirestore.instance;
    final maxRetries = 3;
    int retries = 0;
    int backoff = 1;

    while (retries < maxRetries) {
      try {
        final snap = await _db.collection('users').doc(uid).get();
        if (snap.exists) {
          return snap;
        } else {
          throw 'No data found';
        }
      } catch (e) {
        if (retries == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: backoff));
        retries++;
        backoff *= 2;
      }
    }
    throw 'Failed to fetch data after retries';
  }

  Future<void> _refreshData() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      await fetchUserData(uid);
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final rc = RemoteConfigService.instance;
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Nadia';

    return Scaffold(
      
      body: Container(
         decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage("assets/images/background3.jpg"),
      fit: BoxFit.cover,

    ),
  ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.white,
          child: CustomScrollView(
            slivers: [
              // Custom App Bar with User Info - Glass Effect
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => RouteUtils.push(ProfileScreen()),
                        child: GlassCircleAvatar(
                          radius: 24,
                          child: user?.photoURL != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.photoURL!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              :  Icon(Icons.person, size: 28, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassIconButton(
                        icon: Icons.star,
                        onPressed: () => RouteUtils.push(ProfileScreen()),
                      ),
                      // PointsBadge(),
                    ],
                  ),
                ),
              ),

              // Recently Viewed Section - Glass Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recently Viewed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('articles')
                              .orderBy('publishedAt', descending: true)
                              .limit(5)
                              .snapshots(),
                          builder: (c, s) {
                            if (!s.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                            final docs = s.data!.docs;
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final d = docs[i].data() as Map<String, dynamic>;
                                return GestureDetector(
                                  onTap: () => RouteUtils.push(ArticlesScreen()),
                                  child: GlassCard(
                                    width: 120,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.article_outlined,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            d['title'] ?? 'Article',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Home Banner with Glass Effect
              if (rc.showHomeBanner)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: DaadImage(
                          rc.homeBannerImage.isEmpty ? null : rc.homeBannerImage,
                          height: 160,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),

              // Deals Wheel with Glass Effect
              if (rc.showDealsWheel)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'عجلة العروض',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          DealsWheel(),
                        ],
                      ),
                    ),
                  ),
                ),

              // Main Navigation Cards with Glass Effect
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GlassNavigationCard(
                      title: 'Our Works',
                      titleAr: 'أعمالنا',
                      icon: Icons.work_outline_rounded,
                      onTap: () => RouteUtils.push(const PortfolioScreen()),
                    ),
                    const SizedBox(height: 12),
                    GlassNavigationCard(
                      title: 'Services',
                      titleAr: 'الخدمات',
                      icon: Icons.design_services_rounded,
                      onTap: () => RouteUtils.push(const ServicesScreen()),
                    ),
                    const SizedBox(height: 12),
                    GlassNavigationCard(
                      title: 'Articles',
                      titleAr: 'مقالات',
                      icon: Icons.article_rounded,
                      onTap: () => RouteUtils.push(ArticlesScreen()),
                    ),
                    const SizedBox(height: 12),
                    GlassNavigationCard(
                      title: 'Contact',
                      titleAr: 'تواصل معنا',
                      icon: Icons.contact_mail_rounded,
                      onTap: () => RouteUtils.push(const ContactScreen()),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

