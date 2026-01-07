import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/daad_image.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/widegts/recently_viewed_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _recentlyViewedService = RecentlyViewedService();
  Map<String, dynamic>? _cachedService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
  }

  Future<void> _loadServiceData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        if (mounted) {
          setState(() {
            _cachedService = data;
            _isLoading = false;
          });
        }

        // Track view in background
        _trackServiceView(data);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading service: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _trackServiceView(Map<String, dynamic> data) async {
    try {
      await _recentlyViewedService.addRecentlyViewed(
        itemId: widget.serviceId,
        collection: 'services',
        title: data['title'] ?? '',
        imageUrl: (data['images'] as List?)?.first ?? '',
        body: data['body'] ?? '',
        additionalData: {'industry': data['industry'] ?? ''},
      );
    } catch (e) {
      print('Error tracking view: $e');
    }
  }

  Future<void> _sendWhatsAppMessage(BuildContext context, String title) async {
    final message = 'مرحباً، أود الاستفسار عن خدمة: $title';
    const phone = "+966564639466";
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تعذر فتح واتساب")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("حدث خطأ")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading || _cachedService == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kBackgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final title = _cachedService!["title"] ?? "بدون اسم";
    final desc = _cachedService!["desc"] ?? "";
    final image = _cachedService!["images"];

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(kBackgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: size.height * 0.30,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textColor.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const GlassBackButton(),
                      SizedBox(width: 5.w),
                      // const Spacer(),
                      AppText(
                        title: title,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  SizedBox(height: 25.h),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 280.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          // color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(30.r),
                          // border: Border.all(
                          //   // color: Colors.white.withOpacity(0.20),
                          //   width: 1.5.w,
                          // ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: DaadImage(image, fit: BoxFit.fill),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 25.h),

                  AppText(
                    title: desc,
                    fontSize: 16,
                    height: 1.7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.95),
                  ),

                  SizedBox(height: 12.h),

                  GestureDetector(
                    onTap: () => _sendWhatsAppMessage(context, title),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const AppText(
                        title: "اشترك في الخدمة",
                        fontSize: 12,
                        // fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
