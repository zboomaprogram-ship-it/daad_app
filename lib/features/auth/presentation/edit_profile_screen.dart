import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/custom_button.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  String _facebookUrl = '';
  String _tiktokUrl = '';
  String _snapchatUrl = '';
  String _instagramUrl = '';
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isDaadClient = false;

  // Store original values to check if anything changed
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Store original data
        _originalData = {
          'name': data['name'] ?? '',
          'phone': data['phone'] ?? '',
          'city': data['city'] ?? '',
          'address': data['address'] ?? '',
          'storelink': data['storelink'] ?? '',
          'isDaadClient': data['isDaadClient'] ?? false,
          'socialLinks': {
            'facebook': data['socialLinks']?['facebook'] ?? '',
            'tiktok': data['socialLinks']?['tiktok'] ?? '',
            'snapchat': data['socialLinks']?['snapchat'] ?? '',
            'instagram': data['socialLinks']?['instagram'] ?? '',
          },
        };

        setState(() {
          _nameController.text = _originalData['name'];
          _phoneController.text = _originalData['phone'];
          _cityController.text = _originalData['city'];
          _addressController.text = _originalData['address'];
          _bioController.text = _originalData['storelink'];
          _isDaadClient = _originalData['isDaadClient'];
          _facebookUrl = _originalData['socialLinks']['facebook'];
          _tiktokUrl = _originalData['socialLinks']['tiktok'];
          _snapchatUrl = _originalData['socialLinks']['snapchat'];
          _instagramUrl = _originalData['socialLinks']['instagram'];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        _showSnackBar('حدث خطأ في تحميل البيانات: $e', Colors.red);
      }
    }
  }

  Map<String, dynamic> _getChangedFields() {
    Map<String, dynamic> changes = {};

    if (_nameController.text.trim() != _originalData['name']) {
      changes['name'] = _nameController.text.trim();
    }
    if (_phoneController.text.trim() != _originalData['phone']) {
      changes['phone'] = _phoneController.text.trim();
    }
    if (_cityController.text.trim() != _originalData['city']) {
      changes['city'] = _cityController.text.trim();
    }
    if (_addressController.text.trim() != _originalData['address']) {
      changes['address'] = _addressController.text.trim();
    }
    if (_bioController.text.trim() != _originalData['storelink']) {
      changes['storelink'] = _bioController.text.trim();
    }
    if (_isDaadClient != _originalData['isDaadClient']) {
      changes['isDaadClient'] = _isDaadClient;
    }

    // Check social links
    Map<String, String> newSocialLinks = {
      'facebook': _facebookUrl,
      'tiktok': _tiktokUrl,
      'snapchat': _snapchatUrl,
      'instagram': _instagramUrl,
    };

    if (newSocialLinks['facebook'] !=
            _originalData['socialLinks']['facebook'] ||
        newSocialLinks['tiktok'] != _originalData['socialLinks']['tiktok'] ||
        newSocialLinks['snapchat'] !=
            _originalData['socialLinks']['snapchat'] ||
        newSocialLinks['instagram'] !=
            _originalData['socialLinks']['instagram']) {
      changes['socialLinks'] = newSocialLinks;
    }

    return changes;
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال الاسم', Colors.red);
      return;
    }

    // Get changed fields
    final changes = _getChangedFields();

    if (changes.isEmpty) {
      _showSnackBar('لم يتم إجراء أي تغييرات', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create profile change request
      await FirebaseFirestore.instance
          .collection('profile_change_requests')
          .add({
            'userId': user.uid,
            'userName': _originalData['name'],
            'userPhone': _originalData['phone'],
            'changes': changes,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showSnackBar('تم إرسال طلب التعديل للمراجعة ✓', Colors.green);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        leading: GlassBackButton(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        Image.asset(
                          kLogoImage,
                          width: 62.18.w,
                          height: 62.18.h,
                        ),
                        SizedBox(height: 15.h),
                        AppText(
                          title: 'تعديل الملف الشخصي',
                          color: AppColors.textColor,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 10.h),
                        AppText(
                          title: 'سيتم مراجعة التعديلات من قبل الإدارة',
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        SizedBox(height: 40.h),

                        GlassTextField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
                          icon: Icons.person_outline_rounded,
                        ),
                        SizedBox(height: 16.h),

                        GlassTextField(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 16.h),

                        GlassTextField(
                          controller: _cityController,
                          label: 'اسم المدينة',
                          icon: Icons.location_city_outlined,
                        ),
                        SizedBox(height: 16.h),

                        GlassTextField(
                          controller: _addressController,
                          label: 'عنوان السكن',
                          icon: Icons.home_outlined,
                        ),
                        SizedBox(height: 16.h),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDaadClient = !_isDaadClient;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
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

                        GlassTextField(
                          controller: _bioController,
                          label: 'المتجر',
                          icon: Icons.link,
                          maxLines: 1,
                        ),
                        SizedBox(height: 24.h),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: AppText(
                              title: 'ادخل لينكات المنصات الخاصة بك',

                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),

                        _buildSocialInputField(
                          icon: FontAwesomeIcons.facebook,
                          value: _facebookUrl,
                          onChanged: (value) =>
                              setState(() => _facebookUrl = value),
                        ),
                        SizedBox(height: 12.h),

                        _buildSocialInputField(
                          icon: FontAwesomeIcons.tiktok,
                          value: _tiktokUrl,
                          onChanged: (value) =>
                              setState(() => _tiktokUrl = value),
                        ),
                        SizedBox(height: 12.h),

                        _buildSocialInputField(
                          icon: FontAwesomeIcons.snapchat,
                          value: _snapchatUrl,
                          onChanged: (value) =>
                              setState(() => _snapchatUrl = value),
                        ),
                        SizedBox(height: 12.h),

                        _buildSocialInputField(
                          icon: FontAwesomeIcons.instagram,
                          value: _instagramUrl,
                          onChanged: (value) =>
                              setState(() => _instagramUrl = value),
                        ),

                        SizedBox(height: 32.h),

                        AppButton(
                          btnText: 'إرسال للمراجعة',
                          onTap: _isLoading ? null : _saveProfile,
                          isLoading: _isLoading,
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
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
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
