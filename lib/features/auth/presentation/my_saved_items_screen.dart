import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/network_utils/error_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:daad_app/features/articles/articles_deatiles_screen.dart';
import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
import 'package:daad_app/features/learn_daad/learn_daad.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MySavedItemsScreen extends StatefulWidget {
  const MySavedItemsScreen({super.key});

  @override
  State<MySavedItemsScreen> createState() => _MySavedItemsScreenState();
}

class _MySavedItemsScreenState extends State<MySavedItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: EmptyStateView(
            message: 'يرجى تسجيل الدخول أولاً',
            icon: Icons.login_rounded,
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: const AppText(
          title: 'ما تم حفظه',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'الأعمال'),
            Tab(text: 'التعلم'),
            Tab(text: 'المقالات'),
          ],
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
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPortfolioTab(userId),
              _buildLearnTab(userId),
              _buildArticlesTab(userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('portfolio')
          .where('bookmarkedBy', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        if (snapshot.hasError) {
          return ErrorView(
            error: snapshot.error!,
            onRetry: () => setState(() {}),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const EmptyStateView(
            message: 'لا توجد أعمال محفوظة',
            icon: Icons.bookmark_border_rounded,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(20.r),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return _SavedPortfolioCard(
              data: data,
              docId: docId,
              userId: userId,
            );
          },
        );
      },
    );
  }

  Widget _buildLearnTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('learnWithdaad')
          .where('saves', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        if (snapshot.hasError) {
          return ErrorView(
            error: snapshot.error!,
            onRetry: () => setState(() {}),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const EmptyStateView(
            message: 'لا توجد دروس محفوظة',
            icon: Icons.bookmark_border_rounded,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(20.r),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return _SavedLearnCard(data: data, docId: docId, userId: userId);
          },
        );
      },
    );
  }

  Widget _buildArticlesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        if (snapshot.hasError) {
          return ErrorView(
            error: snapshot.error!,
            onRetry: () => setState(() {}),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final savedDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
          return bookmarkedBy.contains(userId);
        }).toList();

        if (savedDocs.isEmpty) {
          return const EmptyStateView(
            message: 'لا توجد مقالات محفوظة',
            icon: Icons.bookmark_border_rounded,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(20.r),
          physics: const BouncingScrollPhysics(),
          itemCount: savedDocs.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final data = savedDocs[index].data() as Map<String, dynamic>;
            final docId = savedDocs[index].id;

            return _SavedArticleCard(data: data, docId: docId, userId: userId);
          },
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.all(20.r),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => const ShimmerListItem(),
    );
  }
}

// Saved Portfolio Card
class _SavedPortfolioCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _SavedPortfolioCard({
    required this.data,
    required this.docId,
    required this.userId,
  });

  Future<void> _removeBookmark(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('portfolio')
          .doc(docId)
          .update({
            'bookmarkedBy': FieldValue.arrayRemove([userId]),
            'bookmarks': FieldValue.increment(-1),
          })
          .timeout(const Duration(seconds: 5));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'تم الإزالة من المحفوظات'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            title:
                'خطأ: ${ErrorHandler.getErrorMessage(ErrorHandler.getErrorType(e))}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'عنوان العمل';
    final body = data['body'] ?? 'محتوى العمل';
    final imageUrl = data['images'];
    final pdfUrl = data['pdfUrl'] ?? '';

    return GestureDetector(
      onTap: () {
        if (pdfUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfContractPage(
                title: title,
                pdfUrl: pdfUrl,
                showAgreementButton: false,
              ),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            height: 140.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: DaadImage(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 140.h,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppText(
                                title: title,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeBookmark(context),
                              child: const Icon(
                                Icons.bookmark,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          title: data['industry'] ?? 'الأعمال',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                        SizedBox(height: 8.h),
                        Expanded(
                          child: AppText(
                            title: body,
                            fontSize: 12,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
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

// Saved Learn Card
class _SavedLearnCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _SavedLearnCard({
    required this.data,
    required this.docId,
    required this.userId,
  });

  Future<void> _removeBookmark(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('learnWithdaad')
          .doc(docId)
          .update({
            'saves': FieldValue.arrayRemove([userId]),
          })
          .timeout(const Duration(seconds: 5));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'تم الإزالة من المحفوظات'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            title:
                'خطأ: ${ErrorHandler.getErrorMessage(ErrorHandler.getErrorType(e))}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'عنوان';
    final body = data['body'] ?? 'محتوى';
    final imageUrl = data['images'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearnDetails(doc: data, docId: docId),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            height: 140.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: DaadImage(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 140.h,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppText(
                                title: title,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeBookmark(context),
                              child: const Icon(
                                Icons.bookmark,
                                color: AppColors.textColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        const AppText(
                          title: 'تعلم مع ضاد',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                        SizedBox(height: 8.h),
                        Expanded(
                          child: AppText(
                            title: body,
                            fontSize: 12,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
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

// Saved Article Card
class _SavedArticleCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;

  const _SavedArticleCard({
    required this.data,
    required this.docId,
    required this.userId,
  });

  Future<void> _removeBookmark(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('articles')
          .doc(docId)
          .update({
            'bookmarkedBy': FieldValue.arrayRemove([userId]),
          })
          .timeout(const Duration(seconds: 5));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'تم الإزالة من المحفوظات'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            title:
                'خطأ: ${ErrorHandler.getErrorMessage(ErrorHandler.getErrorType(e))}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'عنوان المقال';
    final body = data['body'] ?? 'محتوى المقال';
    final imageUrl = data['images'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailsScreen(doc: data, docId: docId),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            height: 140.h,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: DaadImage(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 140.h,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppText(
                                title: title,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeBookmark(context),
                              child: const Icon(
                                Icons.bookmark,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        const AppText(
                          title: 'المقالات',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                        SizedBox(height: 8.h),
                        Expanded(
                          child: AppText(
                            title: body,
                            fontSize: 12,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
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
