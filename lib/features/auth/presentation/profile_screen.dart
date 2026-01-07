import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/notification_utils/notification_utils.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/presentation/edit_profile_screen.dart';
import 'package:daad_app/features/auth/presentation/my_favorites_screen.dart';
import 'package:daad_app/features/auth/presentation/my_saved_items_screen.dart';
import 'package:daad_app/features/auth/presentation/sign_in_screen.dart';
import 'package:daad_app/features/auth/presentation/user_contracts_screen.dart';
import 'package:daad_app/features/auth/presentation/user_packages_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/dashboard/dashboard_screen.dart';
import 'package:daad_app/features/dashboard/sales_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  final bool _isUpdatingField = false;

  TextEditingController? _nameController;
  TextEditingController? _phoneController;
  TextEditingController? _emailController;
  TextEditingController? _storeNameController;
  TextEditingController? _storeEmailController;
  TextEditingController? _addressController;

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GlassDialog(
        title: 'تسجيل الخروج',
        body: const AppText(
          title: 'هل تريد تسجيل الخروج من الحساب؟',
          fontSize: 13,
          color: Colors.white70,
          textAlign: TextAlign.center,
        ),
        primaryText: 'نعم، خروج',
        primaryColor: Colors.red,
        secondaryText: 'إلغاء',
        onPrimary: () => Navigator.pop(context, true),
        onSecondary: () => Navigator.pop(context, false),
      ),
    );

    if (ok != true) return;

    await FirebaseAuth.instance.signOut();
    await NotificationService.removeExternalUserId();

    if (!mounted) return;
    RouteUtils.pushAndPopAll(const LoginScreen());
  }

  // ✅ FIXED: No permission checks - direct photo picker usage
  Future<void> _uploadProfileImage() async {
    try {
      // ✅ Direct photo picker - no permission needed
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final imageUrl = await WordPressMediaService.uploadImage(
        File(image.path),
      );

      if (imageUrl == null) throw Exception('فشل رفع الصورة');

      final user = FirebaseAuth.instance.currentUser;
      await user?.updatePhotoURL(imageUrl);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
            'photoURL': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'تم تحديث الصورة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'خطأ في رفع الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _phoneController?.dispose();
    _emailController?.dispose();
    _storeNameController?.dispose();
    _storeEmailController?.dispose();
    _addressController?.dispose();
    super.dispose();
  }

  // ==========================
  // Delete account (FULL FLOW)
  // ==========================
  Future<void> _showDeleteAccountDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (confirmed != true) return;
    await _deleteAccountFlow();
  }

  Future<void> _deleteAccountFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final uid = user.uid;

      // 1) delete firestore user doc
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 2) delete auth user (might require recent login)
      await user.delete();

      // 3) cleanup
      await NotificationService.removeExternalUserId();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      RouteUtils.pushAndPopAll(const LoginScreen());
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      if (e.code == 'requires-recent-login') {
        await _showReauthDialogAndDelete();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'فشل حذف الحساب: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'فشل حذف الحساب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showReauthDialogAndDelete() async {
    final emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
    final passController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _GlassDialog(
          title: 'تأكيد الهوية',
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText(
                title: 'لأسباب أمنية، يلزم إعادة تسجيل الدخول قبل حذف الحساب.',
                fontSize: 13,
                color: Colors.white70,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14.h),
              _glassTextField(
                controller: emailController,
                hint: 'البريد الإلكتروني',
                readOnly: true,
              ),
              SizedBox(height: 10.h),
              _glassTextField(
                controller: passController,
                hint: 'كلمة المرور',
                obscure: true,
              ),
            ],
          ),
          primaryText: 'تأكيد والحذف',
          primaryColor: Colors.red,
          secondaryText: 'إلغاء',
          onPrimary: () => Navigator.pop(context, true),
          onSecondary: () => Navigator.pop(context, false),
        );
      },
    );

    if (ok != true) return;

    // loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final cred = EmailAuthProvider.credential(
        email: emailController.text.trim(),
        password: passController.text,
      );

      await user.reauthenticateWithCredential(cred);

      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      // delete after reauth
      await _deleteAccountFlow();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'فشل التأكيد: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'فشل التأكيد: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      emailController.dispose();
      passController.dispose();
    }
  }

  static Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    bool readOnly = false,
  }) {
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.w),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const GlassBackButton(),
          title: const AppText(
            title: 'الصفحة الشخصية',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GlassIconButton(
                icon: Icons.edit_rounded,
                onPressed: () => RouteUtils.push(EditProfileScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: GlassIconButton(
                icon: Icons.logout_rounded,
                onPressed: _confirmLogout,
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kAuthBackgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: AppText(title: 'خطأ: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: AppText(
                      title: 'لا توجد بيانات',
                      color: Colors.white,
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final userRole = userData['role'] ?? 'client';
                final socialLinks = (userData['socialLinks'] as Map?)
                    ?.cast<String, dynamic>();
                final photoURL = userData['photoURL'] ?? user?.photoURL ?? '';
                final points = userData['points'] ?? 0;

                _nameController ??= TextEditingController(
                  text: userData['name'] ?? '',
                );
                _phoneController ??= TextEditingController(
                  text: userData['phone'] ?? '',
                );
                _emailController ??= TextEditingController(
                  text: user?.email ?? '',
                );
                _storeNameController ??= TextEditingController(
                  text: userData['storeName'] ?? '',
                );
                _storeEmailController ??= TextEditingController(
                  text: userData['storeEmail'] ?? '',
                );
                _addressController ??= TextEditingController(
                  text: userData['address'] ?? '',
                );

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),

                            // صورة البروفايل
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipOval(
                                  child: photoURL.isNotEmpty
                                      ? Image.network(
                                          photoURL,
                                          fit: BoxFit.cover,
                                          width: 140.w,
                                          height: 140.h,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.person,
                                                size: 100,
                                                color: Colors.white,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 100,
                                          color: Colors.white,
                                        ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: _isUploadingImage
                                        ? null
                                        : _uploadProfileImage,
                                    child: Container(
                                      width: 38.w,
                                      height: 38.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.w,
                                        ),
                                      ),
                                      child: _isUploadingImage
                                          ? Padding(
                                              padding: EdgeInsets.all(8.0.r),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.w,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 18.h),

                            AppText(
                              title: userData['name'] ?? 'مستخدم',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),

                            SizedBox(height: 18.h),

                            // شريط نقاط الولاء
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF922D4E),
                                    Color(0xFF480118),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.45),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppText(
                                    title: 'نقاط الولاء',
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 7,
                                  ),
                                  SizedBox(width: 3.w),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6.w),
                                  AppText(
                                    title: '$points',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 26.h),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: _buildSectionHeader('البيانات الأساسية'),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildEditableField(
                              label: 'الاسم بالكامل',
                              controller: _nameController!,
                              keyboardType: TextInputType.name,
                            ),
                            _buildEditableField(
                              label: 'رقم الهاتف',
                              controller: _phoneController!,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildEditableField(
                              label: 'البريد الإلكتروني',
                              controller: _emailController!,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildEditableField(
                              label: 'اسم المتجر',
                              controller: _storeNameController!,
                            ),
                            _buildEditableField(
                              label: 'المتجر',
                              controller: _storeEmailController!,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _buildEditableField(
                              label: 'العنوان',
                              controller: _addressController!,
                            ),
                            SizedBox(height: 15.h),
                            Divider(
                              height: 1.h,
                              color: Colors.white,
                              thickness: 1,
                            ),
                            SizedBox(height: 15.h),
                            if (_isUpdatingField) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 18.h,
                                  width: 18.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // social links
                    if (socialLinks != null && socialLinks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionHeader('وسائل التواصل الاجتماعي'),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 0,
                          ),
                          child: Column(
                            children: [
                              if (socialLinks['facebook'] != null)
                                _buildSocialButton(
                                  FontAwesomeIcons.facebookF,
                                  socialLinks['facebook'],
                                ),
                              if (socialLinks['tiktok'] != null)
                                _buildSocialButton(
                                  FontAwesomeIcons.tiktok,
                                  socialLinks['tiktok'],
                                ),
                              if (socialLinks['snapchat'] != null)
                                _buildSocialButton(
                                  FontAwesomeIcons.snapchatGhost,
                                  socialLinks['snapchat'],
                                ),
                              if (socialLinks['instagram'] != null)
                                _buildSocialButton(
                                  FontAwesomeIcons.instagram,
                                  socialLinks['instagram'],
                                ),
                              SizedBox(height: 20.h),
                              Divider(
                                height: 1.h,
                                color: Colors.white,
                                thickness: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // interactions
                    SliverToBoxAdapter(child: _buildSectionHeader('التفاعلات')),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        child: Column(
                          children: [
                            _buildInteractionRow(
                              title: 'ما تم حفظه',
                              icon: Icons.bookmark_rounded,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MySavedItemsScreen(),
                                ),
                              ),
                            ),
                            _buildInteractionRow(
                              title: 'الإعجابات',
                              icon: Icons.favorite_rounded,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyFavoritesScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Divider(
                              height: 1.h,
                              color: Colors.white,
                              thickness: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // bottom buttons
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                        child: Column(
                          children: [
                            _buildBottomButton(
                              text: 'العقود والاتفاقيات',
                              onTap: () {
                                RouteUtils.push(
                                  UserContractsScreen(
                                    userId: userData['uid'].toString(),
                                    userName: userData['name'],
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 10.h),
                            _buildBottomButton(
                              text: 'الخدمات المشترك بها / باقتك',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserPackagesScreen(
                                      userId: user!.uid,
                                      userName: userData['name'] ?? 'مستخدم',
                                      isAdmin: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (userRole == 'admin') ...[
                              SizedBox(height: 10.h),
                              _buildBottomButton(
                                text: 'لوحة التحكم',
                                onTap: () =>
                                    RouteUtils.push(const DashboardScreen()),
                              ),
                            ],
                            if (userRole == 'sales') ...[
                              SizedBox(height: 10.h),
                              _buildBottomButton(
                                text: 'لوحة التحكم',
                                onTap: () => RouteUtils.push(
                                  const SalesDashboardScreen(),
                                ),
                              ),
                            ],
                            SizedBox(height: 16.h),

                            // ✅ DELETE ACCOUNT BUTTON
                            GestureDetector(
                              onTap: _showDeleteAccountDialog,
                              child: Container(
                                height: 48.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.55),
                                      Colors.red.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.28),
                                    width: 1.w,
                                  ),
                                ),
                                child: const Center(
                                  child: AppText(
                                    title: 'حذف الحساب نهائيًا',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Widgets ----------
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
      child: Column(
        children: [
          AppText(
            title: title,
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 46.h,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.w),
      ),
      child: TextFormField(
        controller: controller,
        enabled: false,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12.sp,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 48.h,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.w),
        ),
        child: Row(
          children: [
            SizedBox(width: 16.w),
            SizedBox(
              width: 32.w,
              height: 32.h,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppText(
                title: url,
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: 14.w),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionRow({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46.h,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.w),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 12.w),
                  AppText(
                    title: title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.45),
              Colors.white.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.w),
        ),
        child: Center(
          child: AppText(
            title: text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ======================
// Glass dialogs (THEME)
// ======================
class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return _GlassDialog(
      title: 'حذف الحساب',
      body: const AppText(
        title:
            'هل أنت متأكد؟ سيتم حذف حسابك وبياناتك نهائيًا ولا يمكن استرجاعها.',
        fontSize: 13,
        color: Colors.white70,
        textAlign: TextAlign.center,
      ),
      primaryText: 'نعم، احذف',
      primaryColor: Colors.red,
      secondaryText: 'إلغاء',
      onPrimary: () => Navigator.pop(context, true),
      onSecondary: () => Navigator.pop(context, false),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final String primaryText;
  final Color primaryColor;
  final String secondaryText;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _GlassDialog({
    required this.title,
    required this.body,
    required this.primaryText,
    required this.primaryColor,
    required this.secondaryText,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFF4A1A2C).withOpacity(0.65),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.w,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title: title,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                body,
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onSecondary,
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Center(
                            child: AppText(
                              title: secondaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: onPrimary,
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.75),
                                primaryColor.withOpacity(0.30),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Center(
                            child: AppText(
                              title: primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
    );
  }
}
