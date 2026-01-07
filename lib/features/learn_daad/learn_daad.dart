import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/route_utils/url_launcher.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/recently_viewed_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/daad_image.dart';

class LearnDaadScreen extends StatefulWidget {
  const LearnDaadScreen({super.key});

  @override
  State<LearnDaadScreen> createState() => _LearnDaadScreenState();
}

class _LearnDaadScreenState extends State<LearnDaadScreen> {
  List<Map<String, dynamic>> _cachedArticles = [];
  bool _isLoading = true;

  // Pagination
  static const int _pageSize = 5;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadArticles();
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
      if (!_isLoadingMore && _hasMore) {
        _loadMoreArticles();
      }
    }
  }

  Future<void> _loadArticles() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('learnWithdaad')
          .orderBy('publishedAt', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _cachedArticles = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
          _isLoading = false;

          if (snapshot.docs.length < _pageSize) {
            _hasMore = false;
          }

          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;
          }
        });
      }
    } catch (e) {
      print('Error loading articles: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('learnWithdaad')
          .orderBy('publishedAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          if (snapshot.docs.length < _pageSize) {
            _hasMore = false;
          }

          if (snapshot.docs.isNotEmpty) {
            _lastDocument = snapshot.docs.last;

            final newArticles = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();

            _cachedArticles.addAll(newArticles);
          }

          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more articles: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    const GlassBackButton(),
                    SizedBox(width: 10.w),
                    const AppText(
                      title: 'تعلم مع ضاد',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
                child: Column(
                  children: [
                    Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const AppText(
                      title:
                          'ترشيح لأفضل تدوينات صوتية تهدف إلى تطوير  الأعمال والمشاريع والمسار العملي لرجال الأعمال، مع ملخص يشمل محاور اللقاء.',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const LearnDaadShimmerList()
                    : _cachedArticles.isEmpty
                    ? const Center(
                        child: AppText(
                          title: 'لا توجد محتوى بعد',
                          fontSize: 20,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.textColor.withOpacity(0.02),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            right: 30.w,
                            left: 30.w,
                            top: 20,
                            bottom: 100,
                          ),
                          itemCount: _cachedArticles.length + 1,
                          separatorBuilder: (_, __) => SizedBox(height: 16.h),

                          // Replace the itemBuilder section in your ListView.separated with this:

                          // Replace the itemBuilder section with this complete implementation:
                          itemBuilder: (_, i) {
                            if (i == _cachedArticles.length) {
                              return _isLoadingMore
                                  ? Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20.h,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final data = _cachedArticles[i];
                            final docId = data['id'] as String;
                            final currentUserId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';

                            return _LearnCard(
                              key: ObjectKey(
                                data,
                              ), // This will change when data object changes
                              docId: docId,
                              data: data,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LearnDetails(docId: docId, doc: data),
                                  ),
                                );

                                if (result == true && mounted) {
                                  // Fetch the latest doc from Firestore
                                  try {
                                    final freshDoc = await FirebaseFirestore
                                        .instance
                                        .collection('learnWithdaad')
                                        .doc(docId)
                                        .get();

                                    if (freshDoc.exists && mounted) {
                                      final freshData =
                                          freshDoc.data()
                                              as Map<String, dynamic>;

                                      // Find and update the item
                                      final index = _cachedArticles.indexWhere(
                                        (e) => e['id'] == docId,
                                      );
                                      if (index != -1) {
                                        // Create a completely new list with the updated item
                                        final updatedList =
                                            List<Map<String, dynamic>>.from(
                                              _cachedArticles,
                                            );
                                        updatedList[index] = {
                                          'id': docId,
                                          ...freshData,
                                        };

                                        setState(() {
                                          _cachedArticles = updatedList;
                                        });

                                        // Force a frame to ensure rebuild
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            });
                                      }
                                    }
                                  } catch (e) {
                                    print('Error refreshing article: $e');
                                  }
                                }
                              },
                              onLikeToggle: () async {
                                if (currentUserId.isEmpty) return;

                                final index = _cachedArticles.indexWhere(
                                  (e) => e['id'] == docId,
                                );
                                if (index == -1) return;

                                // Create new list and new map
                                final updatedList =
                                    List<Map<String, dynamic>>.from(
                                      _cachedArticles,
                                    );
                                final currentItem = Map<String, dynamic>.from(
                                  updatedList[index],
                                );
                                List<dynamic> likes = List.from(
                                  currentItem['likes'] ?? [],
                                );

                                if (likes.contains(currentUserId)) {
                                  likes.remove(currentUserId);
                                } else {
                                  likes.add(currentUserId);
                                }

                                currentItem['likes'] = likes;
                                updatedList[index] = currentItem;

                                setState(() {
                                  _cachedArticles = updatedList;
                                });

                                // Update Firestore
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('learnWithdaad')
                                      .doc(docId)
                                      .update({'likes': likes});
                                } catch (e) {
                                  print('Error updating like: $e');
                                  // Revert on error
                                  if (mounted) {
                                    final revertList =
                                        List<Map<String, dynamic>>.from(
                                          _cachedArticles,
                                        );
                                    final revertItem =
                                        Map<String, dynamic>.from(
                                          revertList[index],
                                        );
                                    List<dynamic> revertLikes = List.from(
                                      revertItem['likes'] ?? [],
                                    );

                                    if (revertLikes.contains(currentUserId)) {
                                      revertLikes.remove(currentUserId);
                                    } else {
                                      revertLikes.add(currentUserId);
                                    }

                                    revertItem['likes'] = revertLikes;
                                    revertList[index] = revertItem;

                                    setState(() {
                                      _cachedArticles = revertList;
                                    });
                                  }
                                }
                              },
                              onSaveToggle: () async {
                                if (currentUserId.isEmpty) return;

                                final index = _cachedArticles.indexWhere(
                                  (e) => e['id'] == docId,
                                );
                                if (index == -1) return;

                                // Create new list and new map
                                final updatedList =
                                    List<Map<String, dynamic>>.from(
                                      _cachedArticles,
                                    );
                                final currentItem = Map<String, dynamic>.from(
                                  updatedList[index],
                                );
                                List<dynamic> saves = List.from(
                                  currentItem['saves'] ?? [],
                                );

                                if (saves.contains(currentUserId)) {
                                  saves.remove(currentUserId);
                                } else {
                                  saves.add(currentUserId);
                                }

                                currentItem['saves'] = saves;
                                updatedList[index] = currentItem;

                                setState(() {
                                  _cachedArticles = updatedList;
                                });

                                // Update Firestore
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('learnWithdaad')
                                      .doc(docId)
                                      .update({'saves': saves});
                                } catch (e) {
                                  print('Error updating save: $e');
                                  // Revert on error
                                  if (mounted) {
                                    final revertList =
                                        List<Map<String, dynamic>>.from(
                                          _cachedArticles,
                                        );
                                    final revertItem =
                                        Map<String, dynamic>.from(
                                          revertList[index],
                                        );
                                    List<dynamic> revertSaves = List.from(
                                      revertItem['saves'] ?? [],
                                    );

                                    if (revertSaves.contains(currentUserId)) {
                                      revertSaves.remove(currentUserId);
                                    } else {
                                      revertSaves.add(currentUserId);
                                    }

                                    revertItem['saves'] = revertSaves;
                                    revertList[index] = revertItem;

                                    setState(() {
                                      _cachedArticles = revertList;
                                    });
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Replace your entire _LearnCard class with this version:

class _LearnCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onTap;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;

  const _LearnCard({
    super.key,
    required this.data,
    required this.docId,
    required this.onTap,
    required this.onLikeToggle,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final double thumb = 120.w;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final views = (data['views'] as List?)?.length ?? 0;
    final likesList = List<String>.from(data['likes'] ?? []);
    final savesList = List<String>.from(data['saves'] ?? []);

    final likes = likesList.length;
    final saves = savesList.length;

    final isLiked = likesList.contains(userId);
    final isSaved = savesList.contains(userId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 1.w),
        ),
        child: Padding(
          padding: EdgeInsets.all(18.r),
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title: (data['title'] ?? 'مقال').toString(),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),

                    AppText(
                      title: (data['subtitle'] ?? 'تعلم مع ضاد').toString(),
                      fontSize: 10,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10.h),

                    AppText(
                      title: (data['body'] ?? '').toString(),
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 11,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 14.h),

                    // Stats Row
                    Row(
                      children: [
                        // SAVE
                        GestureDetector(
                          onTap: onSaveToggle,
                          child: _StatItem(
                            icon: isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            count: saves,
                            isActive: isSaved,
                          ),
                        ),
                        SizedBox(width: 20.w),

                        // LIKE
                        GestureDetector(
                          onTap: onLikeToggle,
                          child: _StatItem(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            count: likes,
                            isActive: isLiked,
                          ),
                        ),
                        SizedBox(width: 20.w),

                        // VIEWS
                        _StatItem(
                          icon: Icons.remove_red_eye_outlined,
                          count: views,
                          isActive: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16.w),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(40.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.w,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40.r),
                    child: DaadImage(
                      data['images'],
                      fit: BoxFit.cover,
                      width: thumb,
                      height: thumb,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;

  const _StatItem({
    required this.icon,
    required this.count,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          title: count.toString(),
          fontSize: 12,
          color: isActive
              ? AppColors.secondaryTextColor
              : Colors.white.withOpacity(0.8),
        ),
        SizedBox(width: 4.w),
        Icon(icon, color: AppColors.secondaryTextColor, size: 16),
      ],
    );
  }
}

class LearnDetails extends StatefulWidget {
  final Map<String, dynamic> doc;
  final String docId;

  const LearnDetails({super.key, required this.doc, required this.docId});

  @override
  State<LearnDetails> createState() => _LearnDetailsState();
}

class _LearnDetailsState extends State<LearnDetails> {
  final _recentlyViewedService = RecentlyViewedService();
  bool _hasTrackedView = false;
  bool _hasChanges = false; // Track if any changes were made

  // Local state for optimistic updates
  late List<String> _likes;
  late List<String> _saves;
  late List<String> _views;
  final bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _likes = List<String>.from(widget.doc['likes'] ?? []);
    _saves = List<String>.from(widget.doc['saves'] ?? []);
    _views = List<String>.from(widget.doc['views'] ?? []);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([_incrementViews(), _trackView()]);
  }

  void _openWatchLink(Map<String, dynamic> doc) {
    final link = (doc['link'] ?? '').toString().trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرابط غير متوفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    UrlLauncherUtils.openExternalUrl(context, link);
  }

  Future<void> _trackView() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('learnWithdaad')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        await _recentlyViewedService.addRecentlyViewed(
          itemId: widget.docId,
          collection: 'learnWithdaad',
          title: data['title'] ?? '',
          imageUrl: (data['images'] as List?)?.first ?? '',
          body: data['body'] ?? '',
          additionalData: {
            'link': data['link'] ?? '',
            'person': data['person'] ?? '',
          },
        );
      }
    } catch (e) {
      print('Error tracking view: $e');
    }
  }

  Future<void> _incrementViews() async {
    if (_hasTrackedView) return;
    _hasTrackedView = true;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_views.contains(userId)) return;

    setState(() {
      _views.add(userId);
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('learnWithdaad')
          .doc(widget.docId);

      await docRef.update({
        'views': FieldValue.arrayUnion([userId]),
      });

      _hasChanges = true; // Mark that changes were made
    } catch (e) {
      print('Error incrementing views: $e');
      if (mounted) {
        setState(() {
          _views.remove(userId);
        });
      }
    }
  }

  // Future<void> _toggleLike() async {
  //   if (_isUpdating) return;

  //   final userId = FirebaseAuth.instance.currentUser?.uid;
  //   if (userId == null) return;

  //   final wasLiked = _likes.contains(userId);

  //   setState(() {
  //     if (wasLiked) {
  //       _likes.remove(userId);
  //     } else {
  //       _likes.add(userId);
  //     }
  //     _isUpdating = true;
  //   });

  //   try {
  //     final docRef = FirebaseFirestore.instance
  //         .collection('learnWithdaad')
  //         .doc(widget.docId);

  //     await docRef.update({'likes': _likes});

  //     _hasChanges = true; // Mark that changes were made
  //   } catch (e) {
  //     print('Error toggling like: $e');
  //     if (mounted) {
  //       setState(() {
  //         if (wasLiked) {
  //           _likes.add(userId);
  //         } else {
  //           _likes.remove(userId);
  //         }
  //       });
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isUpdating = false);
  //     }
  //   }
  // }

  // Future<void> _toggleSave() async {
  //   if (_isUpdating) return;

  //   final userId = FirebaseAuth.instance.currentUser?.uid;
  //   if (userId == null) return;

  //   final wasSaved = _saves.contains(userId);

  //   setState(() {
  //     if (wasSaved) {
  //       _saves.remove(userId);
  //     } else {
  //       _saves.add(userId);
  //     }
  //     _isUpdating = true;
  //   });

  //   try {
  //     final docRef = FirebaseFirestore.instance
  //         .collection('learnWithdaad')
  //         .doc(widget.docId);

  //     await docRef.update({'saves': _saves});

  //     _hasChanges = true; // Mark that changes were made
  //   } catch (e) {
  //     print('Error toggling save: $e');
  //     if (mounted) {
  //       setState(() {
  //         if (wasSaved) {
  //           _saves.add(userId);
  //         } else {
  //           _saves.remove(userId);
  //         }
  //       });
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isUpdating = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // final isLiked = _likes.contains(userId);
    // final isSaved = _saves.contains(userId);

    final mediaH = 250.h;

    return WillPopScope(
      onWillPop: () async {
        // Return the result before popping
        Navigator.of(context).pop(_hasChanges);
        return false; // Prevent default pop since we're handling it
      },
      child: Scaffold(
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
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(_hasChanges);
                        },
                        child: const GlassBackButton(),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: AppText(
                            title: widget.doc['title'] ?? 'مقال',
                            fontSize: 12.8,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 35.w),
                    ],
                  ),
                ),

                Expanded(
                  child: widget.doc.isEmpty
                      ? const LearnDetailsShimmer()
                      : ListView(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(26.r),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: mediaH,
                                    width: double.infinity,
                                    child: DaadImage(
                                      widget.doc['images'],
                                      height: mediaH,
                                      width: double.infinity,
                                      fit: BoxFit.fill,
                                    ),
                                  ),

                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.08),
                                    ),
                                  ),

                                  Positioned.fill(
                                    child: Center(
                                      child: InkWell(
                                        onTap: () => _openWatchLink(widget.doc),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: Container(
                                          width: 58.w,
                                          height: 58.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.22,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.55,
                                              ),
                                              width: 1.w,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            size: 34.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     _ActionButton(
                            //       icon: isSaved
                            //           ? Icons.bookmark
                            //           : Icons.bookmark_border,
                            //       count: _saves.length,
                            //       onTap: _toggleSave,
                            //       isActive: isSaved,
                            //     ),
                            //     SizedBox(width: 24.w),
                            //     _ActionButton(
                            //       icon: isLiked
                            //           ? Icons.favorite
                            //           : Icons.favorite_border,
                            //       count: _likes.length,
                            //       onTap: _toggleLike,
                            //       isActive: isLiked,
                            //     ),
                            //     SizedBox(width: 24.w),
                            //     _ActionButton(
                            //       icon: Icons.remove_red_eye_outlined,
                            //       count: _views.length,
                            //       onTap: null,
                            //       isActive: false,
                            //     ),
                            //   ],
                            // ),
                            SizedBox(height: 22.h),

                            AppText(
                              title: (widget.doc['body'] ?? '').toString(),
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.90),
                              textAlign: TextAlign.right,
                            ),

                            SizedBox(height: 30.h),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback? onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.count,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppText(
            title: count.toString(),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.secondaryTextColor : Colors.white,
          ),
          SizedBox(height: 4.h),
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: isActive
                    ? AppColors.secondaryTextColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Icon(icon, color: AppColors.secondaryTextColor, size: 20),
          ),
        ],
      ),
    );
  }
}
