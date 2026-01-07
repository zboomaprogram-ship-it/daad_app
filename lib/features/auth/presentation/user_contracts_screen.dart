import 'package:daad_app/core/constants.dart';
import 'package:daad_app/features/auth/presentation/pdf_viewer_page.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/dashboard/services/contract_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/app_loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class UserContractsScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final bool isAdmin;

  const UserContractsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              kBackgroundImage,
            ), // Add your background image path here
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const AppText(
                title: 'العقود والاتفاقيات',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              leading: const GlassBackButton(),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0.w),
                child: StreamBuilder<QuerySnapshot>(
                  stream: ContractService.getUserContracts(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: AppLoadingIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: AppText(title: 'خطأ: ${snapshot.error}'),
                      );
                    }

                    final contracts = snapshot.data?.docs ?? [];

                    if (contracts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            SizedBox(height: 16.h),
                            const AppText(
                              title: 'لا توجد عقود',
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: contracts.length,
                      itemBuilder: (context, index) {
                        final contract = contracts[index];
                        final data = contract.data() as Map<String, dynamic>;
                        final isAgreed = data['isAgreed'] ?? false;

                        return Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.45),
                                Colors.white.withOpacity(0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isAgreed
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFFA726),
                              width: 2.w,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20.r),
                            child: Column(
                              children: [
                                // Header with icon and title
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        title: data['title'] ?? 'عميل يونتك',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      width: 60.w,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        // color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/icons/agreement.png',
                                        height: 80.h,
                                        width: 80.w,
                                        scale: 0.5,
                                      ),
                                      // child: Icon(isAgreed? FontAwesomeIcons.handshake :FontAwesomeIcons.handshakeSlash,color: AppColors.backgroundColor,size: 30.sp,),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8.h),

                                // Status badge
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAgreed
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFFFA726),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isAgreed
                                                ? Icons.check_circle
                                                : Icons.schedule,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4.w),
                                          AppText(
                                            title: isAgreed
                                                ? 'موقع'
                                                : 'بإنتظار التوقيع',
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16.h),

                                // Divider
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.2),
                                ),

                                SizedBox(height: 16.h),

                                // Date information
                                _buildDateRow(
                                  '📅 تاريخ الرفع',
                                  _formatTimestamp(data['uploadedAt']),
                                ),

                                if (isAgreed && data['agreedAt'] != null)
                                  _buildDateRow(
                                    '📝 تاريخ التوقيع',
                                    _formatTimestamp(data['agreedAt']),
                                  ),

                                SizedBox(height: 16.h),

                                // View PDF button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48.h,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF090103), // Start color
                                          Color(0xFF5C132B), // End color
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.transparent, // <-- important
                                        shadowColor: Colors
                                            .transparent, // <-- remove shadow
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        if (data['pdfUrl'] != null &&
                                            data['pdfUrl']
                                                .toString()
                                                .isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PdfContractPage(
                                                pdfUrl: data['pdfUrl'],
                                                showAgreementButton:
                                                    !isAdmin && !isAgreed,
                                                onAgree: !isAdmin && !isAgreed
                                                    ? () => _handleAgreement(
                                                        context,
                                                        contract.id,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: AppText(
                                                title: "رابط العقد غير متوفر",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: const AppText(
                                        title: 'عرض ال PDF',
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),

                                // Delete button for admin
                                if (isAdmin) ...[
                                  SizedBox(height: 8.h),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48.h,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _confirmDelete(
                                        context,
                                        contract.id,
                                        data['title'] ?? 'عقد',
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.delete_outline),
                                          SizedBox(width: 8.w),
                                          const AppText(
                                            title: 'حذف العقد',
                                            fontSize: 16,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          AppText(
            title: label,
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          SizedBox(width: 8.w),
          AppText(
            title: value,
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAgreement(BuildContext context, String contractId) async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D2645),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const AppText(title: 'الموافقة على العقد', color: Colors.white),
        content: const AppText(
          title: 'هل قرأت العقد وتوافق على جميع الشروط والأحكام؟',
          color: Colors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText(title: 'لا', color: Colors.white70),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const AppText(title: 'نعم، أوافق', color: Colors.white),
          ),
        ],
      ),
    );

    if (agreed == true && context.mounted) {
      try {
        await ContractService.agreeToContract(
          userId: userId,
          contractId: contractId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(title: 'تم التوقيع على العقد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(title: 'خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String contractId,
    String contractTitle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D2645),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const AppText(title: 'تأكيد الحذف', color: Colors.white),
        content: AppText(
          title: 'هل تريد حذف عقد "$contractTitle"؟',
          color: Colors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText(title: 'إلغاء', color: Colors.white70),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const AppText(title: 'حذف', color: Colors.white),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ContractService.deleteContract(
          userId: userId,
          contractId: contractId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(title: 'تم حذف العقد'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(title: 'خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
    }
    return '-';
  }
}
