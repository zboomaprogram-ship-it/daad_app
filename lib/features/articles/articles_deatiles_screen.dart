import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/recently_viewed_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> doc;
  final String docId;

  const ArticleDetailsScreen({
    super.key,
    required this.doc,
    required this.docId,
  });

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final _recentlyViewedService = RecentlyViewedService();
  bool _hasTrackedView = false;
  Map<String, dynamic>? _cachedArticle;

  @override
  void initState() {
    super.initState();
    _cachedArticle = widget.doc;
    _initializeArticle();
  }

  Future<void> _initializeArticle() async {
    // Run both operations in parallel
    await Future.wait([
      _increaseViewsOnce(),
      _loadArticleAndTrack(),
    ]);
  }

  Future<void> _loadArticleAndTrack() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        if (mounted) {
          setState(() => _cachedArticle = data);
        }

        await _recentlyViewedService.addRecentlyViewed(
          itemId: widget.docId,
          collection: 'articles',
          title: data['title'] ?? '',
          imageUrl: (data['images'] as List?)?.first ?? '',
          body: data['body'] ?? '',
        );
      }
    } catch (e) {
      print('Error loading article: $e');
    }
  }

  Future<void> _increaseViewsOnce() async {
    if (_hasTrackedView) return;
    _hasTrackedView = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.docId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) return;

        final data = snap.data() as Map<String, dynamic>;
        final viewedBy = List<String>.from(data['viewedBy'] ?? []);
        final int views = (data['views'] is int) ? data['views'] : 0;

        if (!viewedBy.contains(user.uid)) {
          transaction.update(docRef, {
            'viewedBy': FieldValue.arrayUnion([user.uid]),
            'views': views + 1,
          });
        }
      });
    } catch (e) {
      print('Error tracking view: $e');
    }
  }

  Future<void> _toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.docId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(docRef, {'likedBy': likedBy});
    });
  }

  Future<void> _toggleBookmark() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.docId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);

      if (bookmarkedBy.contains(userId)) {
        bookmarkedBy.remove(userId);
      } else {
        bookmarkedBy.add(userId);
      }

      transaction.update(docRef, {'bookmarkedBy': bookmarkedBy});
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Use cached data as initial value
    final title = (_cachedArticle?['title'] ?? '').toString();
    final body = (_cachedArticle?['body'] ?? '').toString();
    final imageUrl = _cachedArticle?['images'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: AppText(
          title: title.isEmpty ? 'المقالات' : title,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              kBackgroundImage,
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            top: 230,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textColor.withOpacity(0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('articles')
                  .doc(widget.docId)
                  .snapshots(),
              builder: (context, snapshot) {
                final doc = snapshot.data?.data() as Map<String, dynamic>? ??
                    _cachedArticle ??
                    widget.doc;

                final liveTitle = (doc['title'] ?? '').toString();
                final liveBody = (doc['body'] ?? '').toString();
                final liveImageUrl = doc['images'];

                final views = (doc['viewedBy'] as List?)?.length ?? 0;
                final likedBy = List<String>.from(doc['likedBy'] ?? []);
                final bookmarkedBy = List<String>.from(doc['bookmarkedBy'] ?? []);

                final isLiked = likedBy.contains(userId);
                final isBookmarked = bookmarkedBy.contains(userId);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: DaadImage(
                            liveImageUrl,
                            height: 220.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                    SliverToBoxAdapter(child: SizedBox(height: 18.h)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: AppText(
                            title: liveTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(18.r),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22.r),
                              ),
                              child: AppText(
                                title: liveBody,
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.97),
                                height: 1.8,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 28.h)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}