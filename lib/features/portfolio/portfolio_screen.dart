import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'portfolio_detail_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GlassBackButton(),
        title: const Text(
          'أعمالنا',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('portfolio')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: GlassContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ في تحميل الأعمال',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              
              if (docs.isEmpty) {
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
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد أعمال حالياً',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سيتم إضافة أعمالنا قريباً',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          GlassContainer(
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.work_outline_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'معرض أعمالنا',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'استكشف مشاريعنا الناجحة',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Portfolio Items Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final portfolioItem = docs[index].data() as Map<String, dynamic>;
                          
                          String imageUrl;
                          if (portfolioItem['images'] is List && 
                              (portfolioItem['images'] as List).isNotEmpty) {
                            imageUrl = portfolioItem['images'].first ?? kDefaultImage;
                          } else {
                            imageUrl = portfolioItem['imageUrl'] ?? kDefaultImage;
                          }

                          return PortfolioCard(
                            title: portfolioItem['title'] ?? 'عنوان العمل',
                            industry: portfolioItem['industry'] ?? 'الصناعة',
                            imageUrl: imageUrl,
                            onTap: () {
                              RouteUtils.push(
                                PortfolioDetailScreen(
                                  title: portfolioItem['title'] ?? 'عنوان العمل',
                                  body: portfolioItem['body'] ?? 'محتوى العمل',
                                  imageUrl: imageUrl,
                                  industry: portfolioItem['industry'] ?? 'غير محدد',
                                  createdAt: portfolioItem['createdAt']?.toDate().toString() ?? 'غير محدد',
                                ),
                              );
                            },
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
