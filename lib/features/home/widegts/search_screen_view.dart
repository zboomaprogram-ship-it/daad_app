// ============================================
// 1. SEARCH SCREEN
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/articles/articles_deatiles_screen.dart';
import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/home_app_bar.dart';
import 'package:daad_app/features/learn_daad/learn_daad.dart';
import 'package:daad_app/features/services/services_detailes_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class UnifiedSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const UnifiedSearchScreen({super.key, this.initialQuery});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _searchAllCollections(query.trim().toLowerCase());

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<List<SearchResult>> _searchAllCollections(String query) async {
    final results = <SearchResult>[];

    // Search Articles
    final articlesSnapshot = await FirebaseFirestore.instance
        .collection('articles')
        .get();

    for (final doc in articlesSnapshot.docs) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final titleAr = (data['title_ar'] ?? '').toString().toLowerCase();
      final body = (data['body'] ?? '').toString().toLowerCase();
      final bodyAr = (data['body_ar'] ?? '').toString().toLowerCase();

      if (title.contains(query) ||
          titleAr.contains(query) ||
          body.contains(query) ||
          bodyAr.contains(query)) {
        results.add(
          SearchResult(
            id: doc.id,
            type: SearchResultType.article,
            title: data['title_ar'] ?? data['title'] ?? 'بدون عنوان',
            subtitle: _truncateText(data['body_ar'] ?? data['body'] ?? '', 100),
            imageUrl: data['imageUrl'],
            data: data,
          ),
        );
      }
    }

    // Search Learn with Daad
    final learnSnapshot = await FirebaseFirestore.instance
        .collection('learnWithdaad')
        .get();

    for (final doc in learnSnapshot.docs) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final body = (data['body'] ?? '').toString().toLowerCase();
      final person = (data['person'] ?? '').toString().toLowerCase();

      if (title.contains(query) ||
          body.contains(query) ||
          person.contains(query)) {
        results.add(
          SearchResult(
            id: doc.id,
            type: SearchResultType.learnWithDaad,
            title: data['title'] ?? 'بدون عنوان',
            subtitle: _truncateText(data['body'] ?? '', 100),
            imageUrl: (data['images'] as List?)?.isNotEmpty == true
                ? data['images'][0]
                : null,
            data: data,
          ),
        );
      }
    }

    // Search Portfolio
    final portfolioSnapshot = await FirebaseFirestore.instance
        .collection('portfolio')
        .get();

    for (final doc in portfolioSnapshot.docs) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final body = (data['body'] ?? '').toString().toLowerCase();
      final industry = (data['industry'] ?? '').toString().toLowerCase();

      if (title.contains(query) ||
          body.contains(query) ||
          industry.contains(query)) {
        results.add(
          SearchResult(
            id: doc.id,
            type: SearchResultType.portfolio,
            title: data['title'] ?? 'بدون عنوان',
            subtitle: data['industry'] ?? 'مشروع',
            imageUrl: (data['images'] as List?)?.isNotEmpty == true
                ? data['images'][0]
                : null,
            data: data,
          ),
        );
      }
    }

    // Search Services
    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in servicesSnapshot.docs) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final desc = (data['desc'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();

      if (title.contains(query) ||
          desc.contains(query) ||
          category.contains(query)) {
        results.add(
          SearchResult(
            id: doc.id,
            type: SearchResultType.service,
            title: data['title'] ?? 'بدون عنوان',
            subtitle: _truncateText(data['desc'] ?? '', 100),
            imageUrl: (data['images'] as List?)?.isNotEmpty == true
                ? data['images'][0]
                : null,
            data: data,
          ),
        );
      }
    }

    // Sort by relevance (exact match first, then partial)
    results.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();

      final aExact = aTitle == query;
      final bExact = bTitle == query;

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aStarts = aTitle.startsWith(query);
      final bStarts = bTitle.startsWith(query);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return 0;
    });

    return results;
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: const AppText(
          title: 'البحث',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: GlassSearchField(
                      controller: _searchController,
                      label: 'ابحث عن المحتوى...',
                      icon: Icons.search,
                      focusNode: _searchFocus,
                      onChanged: (value) {
                        // Optional: Add debouncing for real-time search
                      },
                      onSubmitted: (value) {
                        _performSearch(value);
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () => _performSearch(_searchController.text),
                    child: 
                    // GlassContainer(
                    //   width: 50.w,
                    //   height: 50.h,
                    //   child: const Icon(
                    //     Icons.search_rounded,
                    //     color: Colors.white,
                    //   ),
                    // ),
                    Container(
                          width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
              colors: [
                Color(0xff922D4E),
                Color(0xff480118),
              ],
            ),
                        borderRadius: BorderRadius.circular(15.r)
                      ),
                      child: const Center(
                        child: Icon( Icons.search_rounded,),
                      ),
                    )
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16.h),
                          const AppText(
                            title: 'جاري البحث...',
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    )
                  : !_hasSearched
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.h),
                          AppText(
                            title: 'ابحث عن المقالات، الدورات، الخدمات والمزيد',
                            color: Colors.white.withOpacity(0.6),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.h),
                          const AppText(
                            title: 'لم يتم العثور على نتائج',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: 8.h),
                          AppText(
                            title: 'جرب كلمات بحث مختلفة',
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _SearchResultCard(
                          result: result,
                          onTap: () => _handleResultTap(result),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResultTap(SearchResult result) {
    // Navigate to appropriate detail screen based on type
    switch (result.type) {
      case SearchResultType.article:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArticleDetailsScreen(docId: result.id, doc: result.data),
          ),
        );
        break;
      case SearchResultType.learnWithDaad:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearnDetails(docId: result.id, doc: result.data),
          ),
        );
        break;
      case SearchResultType.portfolio:
        final pdfUrl = (result.data['pdfUrl'] ?? '').toString();
        final title = (result.data['title'] ?? result.data['name'] ?? 'الملف')
            .toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfContractPage(
              pdfUrl: pdfUrl,
              showAgreementButton: false,
              title: title, // ✅ pass title
            ),
          ),
        );
        break;

      case SearchResultType.service:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(
              serviceId: result.id,
              //  data: result.data
            ),
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}

// ============================================
// 2. SEARCH RESULT CARD
// ============================================

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image - Full Height
                    if (result.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16.r),
                          bottomRight: Radius.circular(16.r),
                        ),
                        child: Image.network(
                          result.imageUrl!,
                          width: 130.w,
                          fit: BoxFit.fill, // ✅ Changed to cover
                          errorBuilder: (_, __, ___) => Container(
                            width: 130.w,
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16.r),
                            bottomRight: Radius.circular(16.r),
                          ),
                        ),
                        child: Icon(
                          _getIconForType(result.type),
                          color: Colors.white38,
                          size: 40,
                        ),
                      ),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorForType(result.type),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: AppText(
                                title: _getLabelForType(result.type),
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            // Title
                            AppText(
                              title: result.title,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              maxLines: 2,
                            ),
                            SizedBox(height: 4.h),
                            // Subtitle
                            AppText(
                              title: result.subtitle,
                              fontSize: 12,
                              color: Colors.white70,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Arrow
                    Padding(
                      padding: EdgeInsets.all(12.r),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white60,
                      ),
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

  IconData _getIconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.article:
        return Icons.article_outlined;
      case SearchResultType.learnWithDaad:
        return Icons.play_circle_outline;
      case SearchResultType.portfolio:
        return Icons.work_outline;
      case SearchResultType.service:
        return Icons.shopping_bag_outlined;
    }
  }

  Color _getColorForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.article:
        return Colors.blue.withOpacity(0.6);
      case SearchResultType.learnWithDaad:
        return Colors.purple.withOpacity(0.6);
      case SearchResultType.portfolio:
        return Colors.green.withOpacity(0.6);
      case SearchResultType.service:
        return Colors.orange.withOpacity(0.6);
    }
  }

  String _getLabelForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.article:
        return 'مقال';
      case SearchResultType.learnWithDaad:
        return 'تعلم مع ضاد';
      case SearchResultType.portfolio:
        return 'معرض الأعمال';
      case SearchResultType.service:
        return 'خدمة';
    }
  }
}
// ============================================
// 3. MODELS
// ============================================

enum SearchResultType { article, learnWithDaad, portfolio, service }

class SearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Map<String, dynamic> data;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.data,
  });
}

// ============================================
// 4. UPDATE HOME APP BAR
// ============================================

// In your HomeAppBar, update the search field to navigate to search screen:

/*
GlassTextField(
  controller: _searchController,
  label: "ابحث عن كلمة المحتوى...",
  icon: Icons.search,
  readOnly: true,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedSearchScreen(),
      ),
    );
  },
),
*/
