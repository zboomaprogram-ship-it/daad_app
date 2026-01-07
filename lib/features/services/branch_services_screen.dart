import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/services/services_detailes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesBranchesScreen extends StatefulWidget {
  const ServicesBranchesScreen({super.key});

  @override
  State<ServicesBranchesScreen> createState() => _ServicesBranchesScreenState();
}

class _ServicesBranchesScreenState extends State<ServicesBranchesScreen> {
  static const List<Map<String, String>> branches = [
    {
      'id': 'إنشاء المتاجر',
      'image': 'assets/icons/web.png',
      'title': 'إنشاء المتاجر',
    },
    {
      'id': 'المجال الطبي',
      'image': 'assets/icons/midecal.png',
      'title': 'المجال الطبي',
    },
    {
      'id': 'التجارة الإلكترونية',
      'image': 'assets/icons/commerce.png',
      'title': 'التجارة الإلكترونية',
    },
    {'id': 'مطاعم', 'image': 'assets/icons/food.png', 'title': 'مطاعم'},
  ];

  // Cache services by branch
  final Map<String, List<DocumentSnapshot>> _cachedServices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllBranchServices();
  }

  Future<void> _loadAllBranchServices() async {
    try {
      // Load all branch services in parallel
      final results = await Future.wait(
        branches.map(
          (branch) => FirebaseFirestore.instance
              .collection('services')
              .where('category', isEqualTo: branch['id'])
              .get(),
        ),
      );

      for (int i = 0; i < branches.length; i++) {
        _cachedServices[branches[i]['id']!] = results[i].docs;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading branch services: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
              SizedBox(height: 8.h),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const GlassBackButton(),
                    SizedBox(width: 8.w),
                    const AppText(
                      title: 'خدمات فروع ضاد',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      final services = _cachedServices[branch['id']] ?? [];

                      // Skip if no services
                      if (services.isEmpty) return const SizedBox.shrink();

                      return _BranchSection(
                        branchId: branch['id']!,
                        image: branch['image']!,
                        branchTitle: branch['title']!,
                        services: services,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchSection extends StatefulWidget {
  final String branchId;
  final String branchTitle;
  final String image;
  final List<DocumentSnapshot> services;

  const _BranchSection({
    required this.branchId,
    required this.branchTitle,
    required this.image,
    required this.services,
  });

  @override
  State<_BranchSection> createState() => _BranchSectionState();
}

class _BranchSectionState extends State<_BranchSection> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.60);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(widget.image, height: 35.h),
              SizedBox(width: 5.w),
              AppText(
                title: widget.branchTitle,
                maxLines: 2,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ],
          ),

          SizedBox(height: 10.h),

          ClipRRect(
            borderRadius: BorderRadius.circular(26.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 350.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // PageView for services
                    SizedBox(
                      height: 320.h,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: widget.services.length,
                        itemBuilder: (context, index) {
                          final doc = widget.services[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? '';
                          final desc = data['shortDesc'] ?? data['desc'] ?? '';
                          final imageUrl = data['images'];

                          return _ServiceCard(
                            serviceId: doc.id,
                            title: title,
                            description: desc,
                            imageUrl: imageUrl,
                          );
                        },
                      ),
                    ),

                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.services.length, (i) {
                        final bool isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 7 : 5,
                          height: isActive ? 7 : 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String serviceId;
  final String title;
  final String description;
  final dynamic imageUrl;

  const _ServiceCard({
    required this.serviceId,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  Future<void> _sendWhatsAppMessage(BuildContext context, String title) async {
    final message = 'مرحباً، أود الاستفسار عن خدمة: $title';
    const phone = "+966564639466";
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تعذر فتح واتساب")));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("حدث خطأ")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(serviceId: serviceId),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.2.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    child: SizedBox(
                      height: 120.h,
                      width: double.infinity,
                      child: DaadImage(imageUrl, fit: BoxFit.fill),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AppText(
                      title: title,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      maxLines: 2,
                      textAlign: TextAlign.right,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: AppText(
                      title: 'خدمات فروع ضاد',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDFD8BC),
                      maxLines: 2,
                      textAlign: TextAlign.right,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AppText(
                      title: description,
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      height: 1.6,
                    ),
                  ),

                  // const Spacer(),
                  SizedBox(height: 20.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _sendWhatsAppMessage(context, title),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A1A2C),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const AppText(
                              title: 'اشترك في الخدمة',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
