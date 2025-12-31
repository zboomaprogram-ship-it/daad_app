import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlassBackButton(),
        title: const AppText(
          title: 'سياسة الخصوصية',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
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
            padding: EdgeInsets.all(20.w),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('سياسة الخصوصية'),
                  SizedBox(height: 16.h),

                  _buildSubsectionTitle('جمع واستخدام البيانات الشخصية'),
                  SizedBox(height: 8.h),
                  _buildParagraph(
                    'من خلال استخدامك لتطبيق ضاد، فإنك توافق على جمع ومعالجة واستخدام بعض البيانات الشخصية الخاصة بك بهدف تحسين تجربتك وتقديم الخدمات التسويقية والتعليمية ذات الصلة.',
                  ),
                  SizedBox(height: 12.h),

                  _buildParagraph('تشمل البيانات التي قد نقوم بجمعها ما يلي:'),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('الاسم الكامل'),
                  _buildBulletPoint('عنوان البريد الإلكتروني'),
                  _buildBulletPoint('رقم الهاتف'),
                  _buildBulletPoint('عنوان النشاط التجاري أو المتجر'),
                  _buildBulletPoint('روابط وأسماء حسابات التواصل الاجتماعي'),
                  _buildBulletPoint(
                    'حالة كونك عميلًا حاليًا أو مستخدمًا محتملاً لخدمات ضاد',
                  ),
                  _buildBulletPoint(
                    'البيانات التحليلية الخاصة باستخدام التطبيق (مثل الصفحات التي تزورها)',
                  ),
                  SizedBox(height: 16.h),

                  _buildSubsectionTitle('أغراض استخدام البيانات'),
                  SizedBox(height: 8.h),
                  _buildParagraph('نستخدم البيانات بهدف:'),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('إنشاء حساب المستخدم وإدارته'),
                  _buildBulletPoint('تقديم محتوى تعليمي مثل المقالات والبودكاست'),
                  _buildBulletPoint('تمكينك من الاستفادة من نظام الولاء والعروض'),
                  _buildBulletPoint('تحسين خدماتنا وتجربتك داخل التطبيق'),
                  _buildBulletPoint('التواصل معك حول الخدمات الحالية أو المستجدة'),
                  _buildBulletPoint('تخصيص المحتوى والخدمات بما يناسب اهتماماتك'),
                  SizedBox(height: 12.h),

                  _buildParagraph(
                    'تتعهد شركة ضاد بالحفاظ على سرية معلوماتك وعدم مشاركتها مع أي طرف ثالث إلا عند الضرورة لتقديم الخدمات أو وفق ما يقتضيه القانون.',
                  ),
                  SizedBox(height: 16.h),

                  _buildSubsectionTitle('حقوق المستخدم والموافقة'),
                  SizedBox(height: 8.h),
                  _buildParagraph(
                    'نحن نمنحك السيطرة الكاملة على بياناتك الشخصية. ويحق لك:',
                  ),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('الوصول إلى بياناتك الشخصية'),
                  _buildBulletPoint('تعديل أو تحديث معلوماتك'),
                  _buildBulletPoint('طلب حذف بياناتك بالكامل'),
                  _buildBulletPoint('سحب الموافقة على معالجة بياناتك'),
                  _buildBulletPoint(
                    'تقديم شكوى أو استفسار حول طريقة استخدام بياناتك عبر وسائل الاتصال داخل التطبيق',
                  ),
                  SizedBox(height: 16.h),

                  _buildSubsectionTitle('الاحتفاظ بالبيانات وحمايتها'),
                  SizedBox(height: 8.h),
                  _buildParagraph(
                    'يتم الاحتفاظ ببياناتك طالما حسابك فعال أو حسب الضرورة لتقديم الخدمات.',
                  ),
                  SizedBox(height: 8.h),
                  _buildParagraph(
                    'تستخدم ضاد أنظمة حماية وتشفير متقدمة تمنع الوصول غير المصرح به وتضمن سرية بياناتك.',
                  ),
                  SizedBox(height: 8.h),
                  _buildParagraph(
                    'باستمرارك في استخدام التطبيق، فإنك تؤكد أنك قرأت وفهمت ووافقت على سياسة الخصوصية هذه.',
                  ),
                  SizedBox(height: 20.h),

                  Divider(color: Colors.white.withOpacity(0.25), height: 24.h),

                  _buildSectionTitle('سياسة حذف الحساب'),
                  SizedBox(height: 12.h),
                  _buildParagraph(
                    'نحن نقدم للمستخدمين القدرة على حذف حسابهم وبياناتهم الشخصية بالكامل في أي وقت، بما يتوافق مع سياسات Apple وGoogle.',
                  ),
                  SizedBox(height: 16.h),

                  _buildSubsectionTitle('كيفية حذف الحساب'),
                  SizedBox(height: 8.h),
                  _buildParagraph('يمكن للمستخدم حذف حسابه من خلال واحدة من الطرق التالية:'),
                  SizedBox(height: 10.h),

                  _buildSubsectionTitle('1) من داخل التطبيق'),
                  SizedBox(height: 8.h),
                  _buildQuote(
                    'يمكنك حذف حسابك مباشرة من داخل التطبيق عبر:\n\n'
                    'البروفايل → حذف الحساب',
                  ),
                  SizedBox(height: 14.h),

                  _buildSubsectionTitle('2) أو عن طريق طلب مباشر لفريق الدعم'),
                  SizedBox(height: 8.h),
                  _buildQuote(
                    // 'لينك الدعم/الواتساب\n\n'
                    'سيتم حذف حسابك وجميع البيانات المرتبطة به خلال مدة أقصاها 7 أيام عمل.',
                  ),
                  SizedBox(height: 16.h),

                  _buildSubsectionTitle('ماذا يحدث بعد حذف الحساب؟'),
                  SizedBox(height: 8.h),
                  _buildParagraph('عند تنفيذ طلب الحذف:'),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('يتم حذف جميع بيانات المستخدم من خوادمنا بشكل كامل ودائم'),
                  _buildBulletPoint('لا يمكن استعادة الحساب بعد الحذف'),
                  _buildParagraph('ويتم إزالة:'),
                  SizedBox(height: 8.h),
                  _buildBulletPoint('معلومات الاتصال'),
                  _buildBulletPoint('بيانات النشاط التجاري'),
                  _buildBulletPoint('الرسائل'),
                  _buildBulletPoint('السجلات'),
                  _buildBulletPoint('أي بيانات أخرى مرتبطة بالحساب'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return AppText(
      title: text,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.secondaryTextColor,
    );
  }

  Widget _buildSubsectionTitle(String text) {
    return AppText(
      title: text,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  Widget _buildParagraph(String text) {
    return AppText(
      title: text,
      fontSize: 14,
      color: Colors.white.withOpacity(0.9),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w, bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title: '• ',
            fontSize: 14,
            color: AppColors.secondaryTextColor,
          ),
          Expanded(
            child: AppText(
              title: text,
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 1.w,
        ),
      ),
      child: AppText(
        title: text,
        fontSize: 13,
        color: Colors.white.withOpacity(0.92),
      ),
    );
  }
}
