import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_loading_indicator.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UserPackagesScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final bool isAdmin;

  const UserPackagesScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isAdmin = false,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: AppText(
          title: isAdmin ? 'باقات $userName' : 'الخدمات المشترك بها / باقتك',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
        // centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('packages')
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoadingIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.white70,
                      ),
                      SizedBox(height: 16.h),
                      const AppText(
                        title: 'خطأ في تحميل الباقات',
                        color: Colors.white,
                      ),
                    ],
                  ),
                );
              }
              final packages = snapshot.data?.docs ?? [];
              if (packages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_membership_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      SizedBox(height: 16.h),
                      const AppText(
                        title: 'لا توجد باقات حالياً',
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(20.r),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  final data = package.data() as Map<String, dynamic>;

                  return _buildPackageCard(context, package.id, data);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    String packageId,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] ?? 'باقة';
    final description = data['description'] ?? '';
    final pdfUrl = data['pdfUrl'] ?? '';
    final uploadedAt = data['uploadedAt'] as Timestamp?;
    final startDate = data['startDate'] as Timestamp?;
    final endDate = data['endDate'] as Timestamp?;
    final isActive = data['isActive'] ?? true;

    final bool isExpired =
        endDate != null && endDate.toDate().isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.w),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: pdfUrl.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfContractPage(
                        pdfUrl: pdfUrl,
                        title: title,
                        showAgreementButton: false,
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Image.asset(
                        'assets/icons/agreement1.png',
                        height: 80.h,
                        width: 80.w,
                        scale: 0.5,
                      ),
                      // child: Icon(isAgreed? FontAwesomeIcons.handshake :FontAwesomeIcons.handshakeSlash,color: AppColors.backgroundColor,size: 30.sp,),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            title: title,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          if (isExpired)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1.w,
                                ),
                              ),
                              child: const AppText(
                                title: 'منتهية',
                                fontSize: 15,
                                color: Colors.red,
                              ),
                            )
                          else if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1.w,
                                ),
                              ),
                              child: const AppText(
                                title: 'نشطة',
                                fontSize: 15,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: AppColors.secondaryColor.withOpacity(0.95),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                const Icon(Icons.toggle_on),
                                SizedBox(width: 8.w),
                                const AppText(title: 'تغيير الحالة'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8.w),
                                const AppText(title: 'حذف'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'delete') {
                            _confirmDelete(context, packageId);
                          } else if (value == 'toggle') {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('packages')
                                .doc(packageId)
                                .update({'isActive': !isActive});
                          }
                        },
                      ),
                  ],
                ),

                // Description
                if (description.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  AppText(
                    title: description,
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ],

                SizedBox(height: 12.h),
                Divider(color: Colors.white.withOpacity(0.2), height: 1.h),
                SizedBox(height: 12.h),

                // Date information
                Row(
                  children: [
                    Expanded(
                      child: _buildDateInfo(
                        '📅 تاريخ البدء',
                        startDate,
                        AppColors.textColor,
                      ),
                    ),
                    if (endDate != null) ...[
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildDateInfo(
                          '⏰ تاريخ التجديد',
                          endDate,
                          AppColors.backgroundColor,
                        ),
                      ),
                    ],
                  ],
                ),

                if (uploadedAt != null) ...[
                  SizedBox(height: 8.h),
                  AppText(
                    title: 'أضيفت في: ${_formatDate(uploadedAt)}',
                    fontSize: 12,
                    color: AppColors.textColor,
                  ),
                ],

                // View PDF button
                if (pdfUrl.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    height: 42.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF090103), Color(0xFF5C132B)],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8.w),
                          const AppText(
                            title: 'عرض تفاصيل الباقة',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, Timestamp? timestamp, Color? color) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title: label,
            fontSize: 13,
            // color: Colors.white60,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
          SizedBox(height: 2.h),
          AppText(
            title: timestamp != null ? _formatDate(timestamp) : 'غير محدد',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
  }

  Future<void> _confirmDelete(BuildContext context, String packageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor.withOpacity(0.95),
        title: const AppText(title: 'تأكيد الحذف'),
        content: const AppText(title: 'هل تريد حذف هذه الباقة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText(title: 'إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const AppText(title: 'حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('packages')
            .doc(packageId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AppText(title: 'تم حذف الباقة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(title: 'خطأ في الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
