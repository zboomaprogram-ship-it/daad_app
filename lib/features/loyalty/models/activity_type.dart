enum ActivityType {
  comment(points: 5, nameEn: 'Comment on post', nameAr: 'تعليق على منشور'),
  like(points: 5, nameEn: 'Like a post', nameAr: 'الإعجاب بمنشور'),
  story(points: 10, nameEn: 'Share story with mention', nameAr: 'مشاركة منشور على الستوري مع منشن'),
  post(points: 30, nameEn: 'Post about us', nameAr: 'بوست يتكلم عنا أو عن تجربة معنا'),
  ugcVideo(points: 50, nameEn: 'UGC video about services', nameAr: 'فيديو UGC يتكلم عن خدماتنا'),
  referral(points: 100, nameEn: 'Refer new client', nameAr: 'إحالة عميل جديد'),
  review(points: 20, nameEn: 'Write review on LinkedIn/Google', nameAr: 'كتابة تقييم على LinkedIn أو جوجل');

  final int points;
  final String nameEn;
  final String nameAr;

  const ActivityType({
    required this.points,
    required this.nameEn,
    required this.nameAr,
  });
}

// lib/features/loyalty/models/reward.dart

class Reward {
  final String id;
  final String titleAr;
  final String descriptionAr;
  final int requiredPoints;
  final bool isAvailable;

  const Reward({
    required this.id,
    required this.titleAr,

    required this.descriptionAr,
    required this.requiredPoints,
    this.isAvailable = true,
  });

  static List<Reward> getAllRewards() {
    return [
      const Reward(
        id: 'discount_10',

        titleAr: 'خصم 10%',

        descriptionAr: 'خصم 10% على أي خدمة مستقبلية',
        requiredPoints: 50,
      ),
      const Reward(
        id: 'discount_20',

        titleAr: 'خصم 20%',

        descriptionAr: 'خصم 20% على الباقة الشهرية',
        requiredPoints: 100,
      ),
      const Reward(
        id: 'free_service',

        titleAr: 'خدمة مجانية',

        descriptionAr: 'خدمة مجانية على حسب اختيار العميل فيديو أو تصميم',
        requiredPoints: 150,
      ),
      const Reward(
        id: 'featured_post',

        titleAr: 'إدراج مميز',

        descriptionAr: 'إدراج مميز على منصتنا بوست تعريفي للعميل',
        requiredPoints: 200,
      ),
      const Reward(
        id: 'package_upgrade',

        titleAr: 'ترقية الباقة',

        descriptionAr: 'ترقية الباقة الحالية لباقة أعلى',
        requiredPoints: 300,
      ),
      const Reward(
        id: 'free_month',

        titleAr: 'شهر مجاني',

        descriptionAr: 'شهر مجاني من إحدى الباقات أو خدمة مخصصة من اختيارك',
        requiredPoints: 500,
      ),
    ];
  }

  double getAvailabilityPercentage(int userPoints) {
    if (userPoints >= requiredPoints) return 100.0;
    return (userPoints / requiredPoints) * 100;
  }
}
