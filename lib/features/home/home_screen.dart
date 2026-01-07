import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/network_utils/error_handler.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/articles/articles_deatiles_screen.dart';
import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
import 'package:daad_app/features/auth/presentation/user_contracts_screen.dart';
import 'package:daad_app/features/contact/contact_screen.dart';
import 'package:daad_app/features/home/widegts/home_app_bar.dart';
import 'package:daad_app/features/home/widegts/recently_viewed_service.dart';
import 'package:daad_app/features/learn_daad/learn_daad.dart';
import 'package:daad_app/features/loyalty/loyalty_intro_screen.dart';
import 'package:daad_app/features/portfolio/portfolio_screen.dart';
import 'package:daad_app/features/services/branch_services_screen.dart';
import 'package:daad_app/features/services/remote_config_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/daad_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _recentlyViewedService = RecentlyViewedService();
  DocumentSnapshot? _cachedUserData;
  bool _isInitialized = false;

  dynamic _initError;

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
      _initError = null;
      _cachedUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      _initError = e;
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _refreshData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _cachedUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            title: ErrorHandler.getErrorMessage(ErrorHandler.getErrorType(e)),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _collectionSubtitleAr(String collection) {
    switch (collection) {
      case 'articles':
        return '(المقالات)';
      case 'portfolio':
        return '(أعمالنا)';
      case 'learnWithdaad':
        return '(تعلم مع ضاد)';
      case 'services':
        return '(الخدمات)';
      default:
        return '';
    }
  }

  Future<void> _handleRecentlyViewedItemTap(Map<String, dynamic> item) async {
    final collection = (item['collection'] ?? '').toString();
    final itemId = (item['itemId'] ?? '').toString();

    if (collection.isEmpty || itemId.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .doc(itemId)
          .get();

      if (!snap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(title: 'العنصر غير موجود'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = snap.data() ?? {};
      if (!mounted) return;

      switch (collection) {
        case 'articles':
          RouteUtils.push(ArticleDetailsScreen(doc: data, docId: itemId));
          break;

        case 'portfolio':
          final pdfUrl = (data['pdfUrl'] ?? '').toString();
          final title = (data['title'] ?? '').toString();

          if (pdfUrl.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: AppText(title: 'لا يوجد ملف PDF لهذا العمل'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfContractPage(
                pdfUrl: pdfUrl,
                showAgreementButton: false,
                title: title,
              ),
            ),
          );
          break;

        case 'learnWithdaad':
          RouteUtils.push(const LearnDaadScreen());
          break;

        case 'services':
          RouteUtils.push(const ServicesBranchesScreen());
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            title: ErrorHandler.getErrorMessage(ErrorHandler.getErrorType(e)),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final rc = RemoteConfigService.instance;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: !_isInitialized
            ? _buildShimmerLoading()
            : (_initError != null
                  ? ErrorView(
                      error: _initError,
                      onRetry: () {
                        setState(() {
                          _isInitialized = false;
                          _initError = null;
                        });
                        _initializeData();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: AppColors.primaryColor,
                      backgroundColor: AppColors.textColor,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            HomeAppBar(cachedUserData: _cachedUserData),

                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: _RecentlyViewedPanel(
                                  stream: _recentlyViewedService
                                      .getRecentlyViewed(limit: 7),
                                  onItemTap: _handleRecentlyViewedItemTap,
                                  subtitleBuilder: _collectionSubtitleAr,
                                ),
                              ),
                            ),

                            SliverToBoxAdapter(child: SizedBox(height: 18.h)),

                            if (rc.showHomeBanner)
                              SliverToBoxAdapter(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: DaadImage(
                                    rc.homeBannerImage.isEmpty
                                        ? null
                                        : rc.homeBannerImage,
                                    height: 170.h,
                                    width: double.infinity,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),

                            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                            SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 1.5,
                                  ),
                              delegate: SliverChildListDelegate([
                                _MainNavCard(
                                  titleAr: 'أعمالنا',
                                  image: 'assets/icons/employment.png',
                                  onTap: () =>
                                      RouteUtils.push(const PortfolioScreen()),
                                ),
                                _MainNavCard(
                                  titleAr: 'تعلم مع ضاد',
                                  image: 'assets/icons/reading-book.png',
                                  onTap: () =>
                                      RouteUtils.push(const LearnDaadScreen()),
                                ),
                                _MainNavCard(
                                  titleAr: 'تواصل معنا',
                                  image: 'assets/icons/customer-service.png',
                                  onTap: () =>
                                      RouteUtils.push(const ContactScreen()),
                                ),
                                _MainNavCard(
                                  titleAr: 'نظام الولاء',
                                  image: 'assets/icons/shines.png',
                                  onTap: () => RouteUtils.push(
                                    const LoyaltyIntroScreen(),
                                  ),
                                ),
                                _MainNavCard(
                                  titleAr: 'خدمات فروع ضاد',
                                  image: 'assets/icons/settings.png',
                                  onTap: () => RouteUtils.push(
                                    const ServicesBranchesScreen(),
                                  ),
                                ),
                                _MainNavCard(
                                  titleAr: 'العقود والاتفاقيات',
                                  image: 'assets/icons/contract.png',
                                  onTap: () {
                                    final userId = user?.uid ?? '';
                                    final userName =
                                        (_cachedUserData?.get('name') ?? '')
                                            .toString();
                                    RouteUtils.push(
                                      UserContractsScreen(
                                        userId: userId,
                                        userName: userName,
                                      ),
                                    );
                                  },
                                ),
                              ]),
                            ),

                            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                          ],
                        ),
                      ),
                    )),
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

          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
                _ShimmerBox(width: 120.w, height: 20.h),
                _ShimmerBox(width: 40.w, height: 40.h, isCircle: true),
              ],
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          SliverToBoxAdapter(
            child: _ShimmerBox(width: double.infinity, height: 220.h),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 18.h)),

          SliverToBoxAdapter(
            child: _ShimmerBox(width: double.infinity, height: 170.h),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const _ShimmerBox(
                width: double.infinity,
                height: double.infinity,
              ),
              childCount: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool isCircle;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MainNavCard extends StatelessWidget {
  final String titleAr;
  final String image;
  final VoidCallback onTap;

  const _MainNavCard({
    required this.titleAr,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.42),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.w,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(15.h),
                width: 60.w,
                height: 60.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A1A2C),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(image, color: Colors.white),
              ),
              SizedBox(height: 14.h),
              AppText(
                title: titleAr,
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentlyViewedPanel extends StatefulWidget {
  final Stream<QuerySnapshot> stream;
  final void Function(Map<String, dynamic> data) onItemTap;
  final String Function(String collection) subtitleBuilder;

  const _RecentlyViewedPanel({
    required this.stream,
    required this.onItemTap,
    required this.subtitleBuilder,
  });

  @override
  State<_RecentlyViewedPanel> createState() => _RecentlyViewedPanelState();
}

class _RecentlyViewedPanelState extends State<_RecentlyViewedPanel> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients && _totalPages > 0) {
      final cardWidth = 150.w + 10.w; // card width + separator
      final scrollOffset = _scrollController.offset;
      final newPage = (scrollOffset / cardWidth).round();

      if (newPage != _currentPage && newPage >= 0 && newPage < _totalPages) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = 240.h; // Increased to accommodate indicator

    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        height: panelHeight,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.w),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                AppText(
                  title: 'ما شاهدته سابقًا',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildRecentlyViewedShimmer();
                  }

                  if (snapshot.hasError) {
                    final msg = ErrorHandler.getErrorMessage(
                      ErrorHandler.getErrorType(snapshot.error),
                    );
                    return Center(
                      child: AppText(
                        title: msg,
                        fontSize: 13,
                        color: Colors.white70,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: AppText(
                        title: 'لم تشاهد أي محتوى بعد',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  final itemCount = docs.length > 7 ? 7 : docs.length;
                  // Update total pages when data changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_totalPages != itemCount && mounted) {
                      setState(() {
                        _totalPages = itemCount;
                        if (_currentPage >= itemCount) {
                          _currentPage = itemCount - 1;
                        }
                      });
                    }
                  });
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: itemCount,
                          separatorBuilder: (_, __) => SizedBox(width: 10.w),
                          itemBuilder: (_, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final title =
                                (data['titleAr'] as String?)
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? (data['titleAr'] as String)
                                : (data['title'] ?? '').toString();
                            final collection = (data['collection'] ?? '')
                                .toString();
                            final imageUrl = (data['imageUrl'] ?? '')
                                .toString();
                            return _RecentlyViewedCard(
                              title: title,
                              subtitle: widget.subtitleBuilder(collection),
                              imageUrl: imageUrl,
                              onTap: () => widget.onItemTap(data),
                            );
                          },
                        ),
                      ),
                      if (itemCount > 1) ...[
                        SizedBox(height: 12.h),
                        _DotIndicator(
                          itemCount: itemCount,
                          currentIndex: _currentPage,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyViewedShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(width: 10.w),
      itemBuilder: (_, __) =>
          _ShimmerBox(width: 150.w, height: double.infinity),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const _DotIndicator({required this.itemCount, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: currentIndex == index ? 20.w : 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
      ),
    );
  }
}

class _RecentlyViewedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const _RecentlyViewedCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = 150.w;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.r),
        child: Container(
          width: cardW,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 1.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.r),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.42),
                Colors.white.withOpacity(0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1.w,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7.r),
                  child: imageUrl.isNotEmpty
                      ? DaadImage(imageUrl, fit: BoxFit.fill)
                      : Container(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              SizedBox(height: 16.h),
              AppText(
                title: title,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              if (subtitle.isNotEmpty)
                AppText(
                  title: subtitle,
                  fontSize: 8,
                  color: Colors.white.withOpacity(0.70),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
