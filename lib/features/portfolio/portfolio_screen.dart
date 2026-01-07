import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/recently_viewed_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final List<IndustryCategory> industries = [
    IndustryCategory(
      name: 'نتائج الحملات الإعلانية',
      image: 'assets/icons/campaign.png',
      color: Colors.transparent,
    ),
    IndustryCategory(
      name: 'نتائج تحسين محركات البحث',
      image: 'assets/icons/website.png',
      color: Colors.transparent,
    ),
    IndustryCategory(
      name: 'معرض تصاميمنا',
      image: 'assets/icons/ux-design.png',
      color: Colors.transparent,
    ),
    IndustryCategory(
      name: 'أعمال قسم إدارة وسائل التواصل الأجتماعى',
      image: 'assets/icons/media.png',
      color: Colors.transparent,
    ),
  ];

  String? selectedIndustry;
  List<DocumentSnapshot>? _cachedPortfolioItems;
  bool _isLoadingPortfolio = false;

  Future<void> _loadPortfolioForIndustry(String industry) async {
    setState(() {
      _isLoadingPortfolio = true;
      _cachedPortfolioItems = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('portfolio')
          .where('industry', isEqualTo: industry)
          .get();

      if (mounted) {
        setState(() {
          _cachedPortfolioItems = snapshot.docs;
          _isLoadingPortfolio = false;
        });
      }
    } catch (e) {
      print('Error loading portfolio: $e');
      if (mounted) {
        setState(() => _isLoadingPortfolio = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: selectedIndustry != null
            ? GlassBackButton(
                onPressed: () => setState(() {
                  selectedIndustry = null;
                  _cachedPortfolioItems = null;
                }),
              )
            : const GlassBackButton(),
        title: AppText(
          title: selectedIndustry ?? 'أعمالنا',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: SizedBox.expand(
            child: selectedIndustry == null
                ? _buildIndustryGrid()
                : _buildPortfolioList(selectedIndustry!),
          ),
        ),
      ),
    );
  }

  Widget _buildIndustryGrid() {
    return Column(
      children: [
        SizedBox(height: 16.h),
        Container(
          padding: const EdgeInsets.all(12),
          height: 65.h,
          width: 65.w,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(100.r),
          ),
          child: Image.asset('assets/icons/employment.png'),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: const AppText(
            title:
                'بخبرة عميقة في جميع المجالات نستعرض جزء من أعمالنا  في جميع الفروع والأقسام',
            fontSize: 14,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w300,
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: _GlassPanel(
            child: Padding(
              padding: EdgeInsets.all(30.r),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: industries.length,
                itemBuilder: (context, index) {
                  final industry = industries[index];
                  return IndustryCard(
                    category: industry,
                    onTap: () {
                      setState(() => selectedIndustry = industry.name);
                      _loadPortfolioForIndustry(industry.name);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioList(String industry) {
    if (_isLoadingPortfolio) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_cachedPortfolioItems == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_cachedPortfolioItems!.isEmpty) {
      return Center(
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: Colors.white,
                size: 64,
              ),
              SizedBox(height: 16.h),
              const AppText(
                title: 'لا توجد أعمال في هذا القطاع',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 8.h),
              const AppText(title: 'سيتم إضافة أعمال قريباً', fontSize: 14),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 16.h),
        Expanded(
          child: _GlassPanel(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(18.r, 18.r, 18.r, 24.h),
              physics: const BouncingScrollPhysics(),
              itemCount: _cachedPortfolioItems!.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final doc = _cachedPortfolioItems![index];
                final portfolioItem = doc.data() as Map<String, dynamic>;

                return LargePortfolioCard(
                  portfolioId: doc.id,
                  portfolioData: portfolioItem,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class IndustryCategory {
  final String name;
  final String image;
  final Color color;

  IndustryCategory({
    required this.name,
    required this.image,
    required this.color,
  });
}

class IndustryCard extends StatelessWidget {
  final IndustryCategory category;
  final VoidCallback onTap;

  const IndustryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff481123),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1.4.w,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset(category.image, height: 50.h, width: 50.w),
                ),
                SizedBox(height: 14.h),
                AppText(
                  title: category.name,
                  textAlign: TextAlign.center,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 10.h),
                Divider(
                  height: 1.h,
                  color: const Color(0xffdfd8bc2b).withOpacity(0.17),
                  thickness: 1.03,
                  indent: 50,
                  endIndent: 50,
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTextColor,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: const AppText(
                    title: 'مشاهدة',
                    fontSize: 12,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 15.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LargePortfolioCard extends StatefulWidget {
  final String portfolioId;
  final Map<String, dynamic> portfolioData;

  const LargePortfolioCard({
    super.key,
    required this.portfolioId,
    required this.portfolioData,
  });

  @override
  State<LargePortfolioCard> createState() => _LargePortfolioCardState();
}

class _LargePortfolioCardState extends State<LargePortfolioCard> {
  final _recentlyViewedService = RecentlyViewedService();

  late int _views;
  late List<String> _likedBy;
  late List<String> _bookmarkedBy;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _likedBy = List<String>.from(widget.portfolioData['likedBy'] ?? []);
    _bookmarkedBy = List<String>.from(
      widget.portfolioData['bookmarkedBy'] ?? [],
    );
    _views = (widget.portfolioData['views'] is num)
        ? (widget.portfolioData['views'] as num).toInt()
        : 0;
  }

  Future<void> _toggleLike() async {
    if (_isUpdating) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Optimistic update
    setState(() {
      if (_likedBy.contains(uid)) {
        _likedBy.remove(uid);
      } else {
        _likedBy.add(uid);
      }
      _isUpdating = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('portfolio')
          .doc(widget.portfolioId);

      await docRef.update({'likedBy': _likedBy});
    } catch (e) {
      print('Error toggling like: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          if (_likedBy.contains(uid)) {
            _likedBy.remove(uid);
          } else {
            _likedBy.add(uid);
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Optimistic update
    setState(() {
      if (_bookmarkedBy.contains(uid)) {
        _bookmarkedBy.remove(uid);
      } else {
        _bookmarkedBy.add(uid);
      }
      _isUpdating = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('portfolio')
          .doc(widget.portfolioId);

      await docRef.update({'bookmarkedBy': _bookmarkedBy});
    } catch (e) {
      print('Error toggling bookmark: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          if (_bookmarkedBy.contains(uid)) {
            _bookmarkedBy.remove(uid);
          } else {
            _bookmarkedBy.add(uid);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _openPdf(BuildContext context) async {
    final pdfUrl = (widget.portfolioData['pdfUrl'] ?? '').toString();

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'رابط الملف غير متوفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Track recently viewed
    try {
      String imageUrl = '';
      final images =
          widget.portfolioData['images'] ?? widget.portfolioData['imageUrl'];
      if (images is List && images.isNotEmpty) {
        imageUrl = images.first.toString();
      } else if (images != null) {
        imageUrl = images.toString();
      }

      await _recentlyViewedService.addRecentlyViewed(
        itemId: widget.portfolioId,
        collection: 'portfolio',
        title: widget.portfolioData['title'] ?? '',
        imageUrl: imageUrl,
        body: widget.portfolioData['body'] ?? '',
        additionalData: {
          'pdfUrl': pdfUrl,
          'industry':
              widget.portfolioData['subtitle'] ??
              widget.portfolioData['industry'] ??
              '',
        },
      );
    } catch (e) {
      debugPrint('Recently viewed error: $e');
    }

    // Increase views once per user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final docRef = FirebaseFirestore.instance
          .collection('portfolio')
          .doc(widget.portfolioId);

      var shouldIncreaseLocalViews = false;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(docRef);
        if (!snap.exists) return;

        final data = snap.data() ?? {};
        final int currentViews = (data['views'] is num)
            ? (data['views'] as num).toInt()
            : 0;
        final List<dynamic> viewedBy = List<dynamic>.from(
          data['viewedBy'] ?? [],
        );

        if (!viewedBy.contains(uid)) {
          shouldIncreaseLocalViews = true;
          transaction.update(docRef, {
            'views': currentViews + 1,
            'viewedBy': FieldValue.arrayUnion([uid]),
          });
        }
      });

      if (shouldIncreaseLocalViews && mounted) {
        setState(() => _views++);
      }
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfContractPage(
          pdfUrl: pdfUrl,
          title: widget.portfolioData['title'] ?? '',
          showAgreementButton: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = _likedBy.contains(currentUid);
    final isBookmarked = _bookmarkedBy.contains(currentUid);

    final imageData =
        widget.portfolioData['images'] ??
        widget.portfolioData['imageUrl'] ??
        kDefaultImage;

    return GestureDetector(
      onTap: () => _openPdf(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1.6.w,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  child: SizedBox(
                    height: 250.h,
                    width: double.infinity,
                    child: DaadImage(imageData, fit: BoxFit.fill),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title: (widget.portfolioData['title'] ?? 'عنوان العمل')
                            .toString(),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      if ((widget.portfolioData['subtitle'] ??
                              widget.portfolioData['industry'] ??
                              '')
                          .toString()
                          .isNotEmpty) ...[
                        AppText(
                          title:
                              (widget.portfolioData['subtitle'] ??
                                      widget.portfolioData['industry'] ??
                                      '')
                                  .toString(),
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                        SizedBox(height: 6.h),
                      ],
                      AppText(
                        title: (widget.portfolioData['body'] ?? 'محتوى العمل')
                            .toString(),
                        fontSize: 11,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          SizedBox(width: 10.w),
                          _buildStatItem(
                            icon: Icons.visibility_outlined,
                            count: _views,
                          ),
                          SizedBox(width: 40.w),
                          _buildStatItem(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            count: _likedBy.length,
                            onTap: _toggleLike,
                          ),
                          SizedBox(width: 40.w),
                          _buildStatItem(
                            icon: isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            count: _bookmarkedBy.length,
                            onTap: _toggleBookmark,
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
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

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: [
        AppText(title: '$count', fontSize: 12, fontWeight: FontWeight.w600),
        SizedBox(width: 4.w),
        Icon(icon, size: 20.sp, color: AppColors.secondaryTextColor),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: content,
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.only(
      topLeft: Radius.circular(40.r),
      topRight: Radius.circular(40.r),
    );

    return ClipRRect(
      borderRadius: br,
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: br,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.w,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
