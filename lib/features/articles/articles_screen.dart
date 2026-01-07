import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/network_utils/error_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/home_app_bar.dart';
import 'package:daad_app/features/home/widegts/recently_viewed_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen>
    with AutomaticKeepAliveClientMixin {
  DocumentSnapshot? _cachedUserData;
  bool _isInitialized = false;
  final List<DocumentSnapshot> _cachedArticles = [];
  dynamic _error;

  // Pagination
  static const int _pageSize = 5;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _error == null) {
        _loadMoreArticles();
      }
    }
  }

  Future<void> _initializeData() async {
    if (_isInitialized && _error == null) return;

    setState(() {
      _error = null;
      _isInitialized = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _error = 'يرجى تسجيل الدخول';
          _isInitialized = true;
        });
      }
      return;
    }

    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      _cachedUserData = userDoc;

      // Load first page of articles
      await _loadMoreArticles();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _error = e;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          if (snapshot.docs.length < _pageSize) {
            _hasMore = false;
          }

          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
            _cachedArticles.addAll(snapshot.docs);
          }

          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more articles: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (_cachedArticles.isEmpty) {
            _error = e;
          }
        });
      }
    }
  }

  // Method to refresh a specific item in the list
  void _refreshItem(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(docId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          final index = _cachedArticles.indexWhere((item) => item.id == docId);
          if (index != -1) {
            _cachedArticles[index] = doc;
          }
        });
      }
    } catch (e) {
      print('Error refreshing item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized) {
      return _buildShimmerLoading();
    }

    if (_error != null && _cachedArticles.isEmpty) {
      return ErrorView(error: _error!, onRetry: _initializeData);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          HomeAppBar(cachedUserData: _cachedUserData),
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          const SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerRight,
              child: AppText(
                title: 'المقالات',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 16.h)),

          _cachedArticles.isEmpty
              ? const SliverToBoxAdapter(
                  child: EmptyStateView(
                    message: 'لا توجد مقالات بعد',
                    icon: Icons.article_outlined,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _cachedArticles.length) {
                      return _isLoadingMore
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : SizedBox(height: 100.h);
                    }

                    final doc = _cachedArticles[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _ArticleCard(
                        docId: doc.id,
                        data: data,
                        onTap: () async {
                          // Navigate and refresh on return
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArticleDetailsScreen(
                                doc: data,
                                docId: doc.id,
                                onChanged: () => _refreshItem(doc.id),
                              ),
                            ),
                          );
                          // Refresh after return
                          _refreshItem(doc.id);
                        },
                      ),
                    );
                  }, childCount: _cachedArticles.length + 1),
                ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 60.h)),

          // App bar shimmer
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

          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerRight,
              child: ShimmerBox(width: 100.w, height: 20.h),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 16.h)),

          // List shimmer
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ShimmerListItem(),
              childCount: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.docId,
    required this.data,
    required this.onTap,
  });

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  late List<String> _likedBy;
  late List<String> _bookmarkedBy;
  late int _views;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _likedBy = List<String>.from(widget.data['likedBy'] ?? []);
    _bookmarkedBy = List<String>.from(widget.data['bookmarkedBy'] ?? []);
    _views = (widget.data['viewedBy'] is List)
        ? (widget.data['viewedBy'] as List).length
        : (widget.data['views'] ?? 0);
  }

  @override
  void didUpdateWidget(_ArticleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when data changes from parent
    if (widget.data != oldWidget.data) {
      _likedBy = List<String>.from(widget.data['likedBy'] ?? []);
      _bookmarkedBy = List<String>.from(widget.data['bookmarkedBy'] ?? []);
      _views = (widget.data['viewedBy'] is List)
          ? (widget.data['viewedBy'] as List).length
          : (widget.data['views'] ?? 0);
    }
  }

  Future<void> _toggleLike() async {
    if (_isUpdating) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      if (_likedBy.contains(userId)) {
        _likedBy.remove(userId);
      } else {
        _likedBy.add(userId);
      }
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.docId)
          .update({'likedBy': _likedBy})
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Error toggling like: $e');
      if (mounted) {
        setState(() {
          if (_likedBy.contains(userId)) {
            _likedBy.remove(userId);
          } else {
            _likedBy.add(userId);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isUpdating) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      if (_bookmarkedBy.contains(userId)) {
        _bookmarkedBy.remove(userId);
      } else {
        _bookmarkedBy.add(userId);
      }
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.docId)
          .update({'bookmarkedBy': _bookmarkedBy})
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Error toggling bookmark: $e');
      if (mounted) {
        setState(() {
          if (_bookmarkedBy.contains(userId)) {
            _bookmarkedBy.remove(userId);
          } else {
            _bookmarkedBy.add(userId);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? "";
    final body = widget.data['body'] ?? "";
    final images = widget.data['images'];

    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isLiked = uid.isNotEmpty && _likedBy.contains(uid);
    final bool isBookmarked = uid.isNotEmpty && _bookmarkedBy.contains(uid);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 140.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(24.r),
              ),
              child: SizedBox(
                width: 120.w,
                child: DaadImage(images, fit: BoxFit.cover),
              ),
            ),

            // CONTENT
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title: title,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w400,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    const AppText(
                      title: "المقالات",
                      fontSize: 10,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 6),
                    AppText(
                      title: body,
                      fontSize: 11,
                      maxLines: 2,
                      height: 1.4,
                      overflow: TextOverflow.ellipsis,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    const Spacer(),

                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.remove_red_eye_outlined,
                          count: _views,
                          active: false,
                          onTap: null,
                        ),
                        SizedBox(width: 14.w),
                        _MiniStat(
                          icon: isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          count: _likedBy.length,
                          active: isLiked,
                          onTap: _toggleLike,
                        ),
                        SizedBox(width: 14.w),
                        _MiniStat(
                          icon: isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          count: _bookmarkedBy.length,
                          active: isBookmarked,
                          onTap: _toggleBookmark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  const _MiniStat({
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppColors.secondaryTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4.w),
            AppText(title: count.toString(), fontSize: 11, color: color),
          ],
        ),
      ),
    );
  }
}

// ArticleDetailsScreen with callback
class ArticleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> doc;
  final String docId;
  final VoidCallback? onChanged;

  const ArticleDetailsScreen({
    super.key,
    required this.doc,
    required this.docId,
    this.onChanged,
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
    await Future.wait([_increaseViewsOnce(), _loadArticleAndTrack()]);
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

    // Notify parent to refresh
    widget.onChanged?.call();
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

    // Notify parent to refresh
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
            child: Image.asset(kBackgroundImage, fit: BoxFit.cover),
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
                final doc =
                    snapshot.data?.data() as Map<String, dynamic>? ??
                    _cachedArticle ??
                    widget.doc;

                final liveTitle = (doc['title'] ?? '').toString();
                final liveBody = (doc['body'] ?? '').toString();
                final liveImageUrl = doc['images'];

                final views = (doc['viewedBy'] as List?)?.length ?? 0;
                final likedBy = List<String>.from(doc['likedBy'] ?? []);
                final bookmarkedBy = List<String>.from(
                  doc['bookmarkedBy'] ?? [],
                );

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
                            fit: BoxFit.fill,
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
