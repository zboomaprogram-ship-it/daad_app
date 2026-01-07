import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_button.dart';

import 'package:daad_app/features/auth/data/user_utils.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/home/home_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String userId;
  final bool isOptional;

  const CompleteProfileScreen({
    super.key,
    required this.userId,
    this.isOptional = true,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  String _facebookUrl = '';
  String _tiktokUrl = '';
  String _snapchatUrl = '';
  String _instagramUrl = '';

  bool _isLoading = false;
  bool _isDaadClient = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _cityController.text = data['city'] ?? '';
          _addressController.text = data['address'] ?? '';
          _bioController.text = data['storelink'] ?? '';
          _isDaadClient = data['isDaadClient'] ?? false;
          _facebookUrl = data['socialLinks']?['facebook'] ?? '';
          _tiktokUrl = data['socialLinks']?['tiktok'] ?? '';
          _snapchatUrl = data['socialLinks']?['snapchat'] ?? '';
          _instagramUrl = data['socialLinks']?['instagram'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {};

      if (_cityController.text.trim().isNotEmpty) {
        updateData['city'] = _cityController.text.trim();
      }
      if (_addressController.text.trim().isNotEmpty) {
        updateData['address'] = _addressController.text.trim();
      }
      if (_bioController.text.trim().isNotEmpty) {
        updateData['storelink'] = _bioController.text.trim();
      }

      updateData['isDaadClient'] = _isDaadClient;

      Map<String, String> socialLinks = {
        'facebook': _facebookUrl,
        'tiktok': _tiktokUrl,
        'snapchat': _snapchatUrl,
        'instagram': _instagramUrl,
      };

      socialLinks.removeWhere((key, value) => value.isEmpty);

      if (socialLinks.isNotEmpty) {
        updateData['socialLinks'] = socialLinks;
      }

      updateData['profileCompleted'] = true;
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updateData);

      if (mounted) {
        _showSnackBar('تم حفظ البيانات بنجاح ✓', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipForNow() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'profileCompleted': false});

    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await UserManager().init();
    await NotificationService.setExternalUserId(UserManager().uid);
    if (mounted) {
      RouteUtils.pushAndPopAll(const HomeNavigationBar());
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? const GlassBackButton() : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kAuthBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  // Logo
                  Image.asset(kLogoImage, width: 62.18.w, height: 62.18.h),
                  SizedBox(height: 20.h),

                  const AppText(
                    title: 'إكمال البيانات',
                    color: AppColors.textColor,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: 110.h),

                  // City Field
                  GlassTextField(
                    controller: _cityController,
                    label: 'اسم المدينة',
                    icon: Icons.location_city_outlined,
                  ),

                  SizedBox(height: 16.h),

                  // Address Field
                  GlassTextField(
                    controller: _addressController,
                    label: 'عنوان السكن',
                    icon: Icons.home_outlined,
                  ),

                  SizedBox(height: 16.h),

                  // Checkbox: هل انت عميل لضاد؟
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDaadClient = !_isDaadClient;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.45),
                            Colors.white.withOpacity(0.04),
                          ],
                        ),
                        // color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: _isDaadClient
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 2.w,
                              ),
                            ),
                            child: _isDaadClient
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          AppText(
                            title: 'هل انت عميل لضاد؟',

                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Bio Field
                  GlassTextField(
                    controller: _bioController,
                    label: 'لينك المتجر',
                    icon: Icons.link,
                    maxLines: 1,
                  ),

                  SizedBox(height: 24.h),

                  // Social Media Section
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'ادخل لينكات المنصات الخاصة بك',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // Social Media Input Fields
                  _buildSocialInputField(
                    icon: FontAwesomeIcons.facebook,
                    value: _facebookUrl,
                    onChanged: (value) => setState(() => _facebookUrl = value),
                  ),
                  SizedBox(height: 12.h),

                  _buildSocialInputField(
                    icon: FontAwesomeIcons.tiktok,
                    value: _tiktokUrl,
                    onChanged: (value) => setState(() => _tiktokUrl = value),
                  ),
                  SizedBox(height: 12.h),

                  _buildSocialInputField(
                    icon: FontAwesomeIcons.snapchat,
                    value: _snapchatUrl,
                    onChanged: (value) => setState(() => _snapchatUrl = value),
                  ),
                  SizedBox(height: 12.h),

                  _buildSocialInputField(
                    icon: FontAwesomeIcons.instagram,
                    value: _instagramUrl,
                    onChanged: (value) => setState(() => _instagramUrl = value),
                  ),

                  SizedBox(height: 32.h),

                  // Save Button
                  // ContactGlassButton(
                  //   onPressed: _isLoading ? null : _saveProfile,
                  //   child: _isLoading
                  //       ? SizedBox(
                  //           height: 20.h,
                  //           width: 20.w,
                  //           child: CircularProgressIndicator(
                  //             color: Colors.white,
                  //             strokewidth: 2.w,
                  //           ),
                  //         )
                  //       : const Row(
                  //           mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             Text(
                  //               'إنشاء حساب',
                  //               style: TextStyle(
                  //                 fontSize: 16,
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  // ),
                  AppButton(
                    btnText: 'إنشاء حساب',
                    onTap: _isLoading ? null : _saveProfile,
                    isLoading: _isLoading,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _skipForNow,
                        child: const AppText(
                          title: 'تخطي الآن',
                          // textDecoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialInputField({
    required IconData icon,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.45),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.w),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          ),
          // Input Field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
                onChanged: onChanged,
                controller: TextEditingController(text: value)
                  ..selection = TextSelection.collapsed(offset: value.length),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
