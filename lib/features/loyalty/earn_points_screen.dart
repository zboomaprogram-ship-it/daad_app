import 'dart:ui';
import 'dart:io';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/images_picker_grid.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/core/widgets/shimmer_loadfing.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/loyalty/rewards_selection_table.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class PointsRecordingScreen extends StatefulWidget {
  const PointsRecordingScreen({Key? key}) : super(key: key);

  @override
  State<PointsRecordingScreen> createState() => _PointsRecordingScreenState();
}

class ActivityEntry {
  String? selectedActivity;
  String activityLabel;
  String activityType;
  int points;
  TextEditingController linkController;
  File? selectedImage;
  String? uploadedImageUrl;
  bool isUploading;

  ActivityEntry({
    this.selectedActivity,
    this.activityLabel = '',
    this.activityType = '',
    this.points = 0,
    File? image,
    this.uploadedImageUrl,
    this.isUploading = false,
  }) : linkController = TextEditingController(),
       selectedImage = image;

  void dispose() {
    linkController.dispose();
  }
}

class _PointsRecordingScreenState extends State<PointsRecordingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  List<ActivityEntry> _activities = [ActivityEntry()];
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Map<String, Map<String, dynamic>> _activityTypes = {};
  List<Map<String, dynamic>> _rewards = [];
  int _userPoints = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _selectedRewards = [];
  int _temporaryDeductedPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _userHasUnlockedReward {
    if (_rewards.isEmpty) return false;

    for (final reward in _rewards) {
      final rawRequired =
          reward['requiredPoints'] ?? reward['points'] ?? 999999;
      int requiredPoints;

      if (rawRequired is num) {
        requiredPoints = rawRequired.toInt();
      } else if (rawRequired is String) {
        requiredPoints = int.tryParse(rawRequired) ?? 999999;
      } else {
        requiredPoints = 999999;
      }

      if (_userPoints >= requiredPoints) {
        return true;
      }
    }
    return false;
  }

  // ✅ FIXED: Direct image picker - no permission checks needed
  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _activities[index].selectedImage = File(image.path);
          _activities[index].isUploading = true;
        });

        final imageUrl = await WordPressMediaService.uploadImage(
          File(image.path),
        );

        if (!mounted) return;

        if (imageUrl != null) {
          setState(() {
            _activities[index].uploadedImageUrl = imageUrl;
            _activities[index].isUploading = false;
          });
        } else {
          setState(() => _activities[index].isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AppText(title: 'فشل رفع الصورة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;

      setState(() => _activities[index].isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadData() async {
    try {
      final activitiesSnapshot = await _db.collection('activities').get();

      if (activitiesSnapshot.docs.isNotEmpty) {
        final map = <String, Map<String, dynamic>>{};

        for (final doc in activitiesSnapshot.docs) {
          final data = doc.data();
          final type = data['type'] as String?;
          if (type == null || type.isEmpty) continue;

          final label = data['title'] ?? type;

          dynamic pointsRaw = data['points'];
          int points = 0;

          if (pointsRaw is num) {
            points = pointsRaw.toInt();
          } else if (pointsRaw is String) {
            points = int.tryParse(pointsRaw) ?? 0;
          }

          map[type] = {'label': label, 'points': points};
        }

        _activityTypes = map;
      }

      final rewardsSnapshot = await _db.collection('rewards').get();
      _rewards = rewardsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        _userPoints = (userDoc.data()?['points'] as num?)?.toInt() ?? 0;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(title: 'خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addActivity() {
    setState(() {
      _activities.add(ActivityEntry());
    });
  }

  void _removeActivity(int index) {
    if (_activities.length > 1) {
      setState(() {
        _activities[index].dispose();
        _activities.removeAt(index);
      });
    }
  }

  Future<void> _submitActivities() async {
    for (var activity in _activities) {
      if (activity.selectedActivity == null ||
          activity.linkController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(title: 'الرجاء إكمال جميع الحقول المطلوبة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? user.displayName ?? 'مستخدم';
      final userEmail = userData['email'] ?? user.email ?? '';
      final userPhone = userData['phone'] ?? '';

      final batch = _db.batch();

      for (var activity in _activities) {
        final activityRef = _db.collection('points_activity').doc();

        batch.set(activityRef, {
          'userId': user.uid,
          'userName': userName,
          'userEmail': userEmail,
          'userPhone': userPhone,
          'type': activity.activityLabel,
          'activityType': activity.selectedActivity,
          'link': activity.linkController.text.trim(),
          'imageUrl': activity.uploadedImageUrl,
          'points': activity.points,
          'scheduledDate': Timestamp.fromDate(
            DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ),
          ),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        _showSuccessDialog();
        setState(() {
          _activities = [ActivityEntry()];
          selectedDate = DateTime.now();
          selectedTime = TimeOfDay.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(title: 'حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _requestMeeting() async {
    if (_selectedRewards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'الرجاء اختيار مكافأة واحدة على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'الرجاء تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF670A27),
              onPrimary: Colors.white,
              surface: Color(0xFF1C020B),
              onSurface: Colors.white,
            ),
            datePickerTheme: const DatePickerThemeData(
              headerBackgroundColor: AppColors.primaryColor,
              headerForegroundColor: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1C020B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF670A27),
              onPrimary: Colors.white,
              surface: Color(0xFF1C020B),
              onSurface: Colors.white,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFF1C020B),
              hourMinuteTextColor: Colors.white,
              dialHandColor: Color(0xFF670A27),
              dialBackgroundColor: Color(0xFF2A0612),
              dayPeriodTextColor: Colors.white,
              dayPeriodColor: Color(0xFF3F091B),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1C020B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final pointsToDeduct = _temporaryDeductedPoints;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? user.displayName ?? 'مستخدم';
      final userEmail = userData['email'] ?? user.email ?? '';
      final userPhone = userData['phone'] ?? '';

      await _db.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(-pointsToDeduct),
      });

      await _db.collection('redeem_requests').add({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'type': 'meeting_request',
        'selectedRewards': _selectedRewards
            .map(
              (r) => {
                'title': r['title'] ?? r['name'],
                'requiredPoints': r['requiredPoints'] ?? r['points'],
                'rewardId': r['id'],
              },
            )
            .toList(),
        'totalPointsDeducted': pointsToDeduct,
        'status': 'pending',
        'requestType': 'meeting',
        'scheduledDatetime': Timestamp.fromDate(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        ),
        'notes': 'طلب اجتماع لمناقشة تفاصيل المكافآت المحددة',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await _loadData();

      setState(() {
        _selectedRewards = [];
        _temporaryDeductedPoints = 0;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.all(32.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5.w,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 16.h),
                      const Text(
                        'تم إرسال طلب الاجتماع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'تم خصم $pointsToDeduct نقطة مؤقتاً\nسيتم إرجاعها في حالة الرفض',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error creating meeting request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendToWhatsApp() async {
    if (_selectedRewards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'الرجاء اختيار مكافأة واحدة على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'الرجاء تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedRewardsSnapshot = List<Map<String, dynamic>>.from(
      _selectedRewards,
    );
    final totalPointsToDeduct = _temporaryDeductedPoints;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final userName = (userData['name'] ?? user.displayName ?? 'مستخدم')
          .toString();
      final userEmail = (userData['email'] ?? user.email ?? '').toString();
      final userPhone = (userData['phone'] ?? '').toString();

      final rewardsText = selectedRewardsSnapshot
          .map((r) {
            final title = (r['title'] ?? r['name'] ?? 'مكافأة').toString();
            final points = (r['requiredPoints'] ?? r['points'] ?? 0);
            return '• $title ($points نقطة)';
          })
          .join('\n');

      final message = '''
مرحباً 👋

أرغب في استبدال المكافآت التالية:

$rewardsText

إجمالي النقاط: $totalPointsToDeduct نقطة

الاسم: $userName
البريد: $userEmail
الهاتف: $userPhone

شكراً لكم 🙏
''';

      final encodedMessage = Uri.encodeComponent(message);
      const phone = '966564639466';

      final requestRef = await _db.collection('redeem_requests').add({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'type': 'whatsapp_request',
        'selectedRewards': selectedRewardsSnapshot
            .map(
              (r) => {
                'title': (r['title'] ?? r['name']).toString(),
                'requiredPoints': r['requiredPoints'] ?? r['points'] ?? 0,
                'rewardId': r['id'] ?? r['rewardId'] ?? null,
              },
            )
            .toList(),
        'totalPointsDeducted': totalPointsToDeduct,
        'status': 'pending',
        'requestType': 'whatsapp',
        'notes': 'طلب عبر واتساب لاستبدال المكافآت',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final nativeUri = Uri.parse(
        'whatsapp://send?phone=$phone&text=$encodedMessage',
      );

      bool opened = await launchUrl(
        nativeUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        final webUri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
        opened = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      if (!opened) {
        await requestRef.update({
          'status': 'failed',
          'error': 'Could not launch WhatsApp',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        throw 'تعذر فتح واتساب. تأكد أن واتساب مثبت على الجهاز.';
      }

      if (totalPointsToDeduct > 0) {
        await _db.collection('users').doc(user.uid).update({
          'points': FieldValue.increment(-totalPointsToDeduct),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await requestRef.update({
        'status': 'opened_whatsapp',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadData();
      if (!mounted) return;

      setState(() {
        _selectedRewards = [];
        _temporaryDeductedPoints = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(title: 'تم إنشاء الطلب وفتح واتساب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending to WhatsApp: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(title: 'حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.all(40.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5.w,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 80.h,
                      child: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white, size: 50),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    const Text(
                      'تم الإرسال بنجاح',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'سيتواصل فريق الدعم معك قريباً بعد مراجعة الأنشطة',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final additionalPoints = _activities.fold<int>(
      0,
      (sum, a) => sum + a.points,
    );
    final totalAfterReview = _userPoints + additionalPoints;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            const Text(
              'تسجيل النقاط',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10.w),
            Padding(
              padding: EdgeInsets.all(8.r),
              child: GlassIconButton(
                icon: Icons.arrow_forward_ios,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(kBackgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: _isLoading
              ? const PointsRecordingShimmer()
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 100.h),

                      ..._activities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        return _buildActivityEntry(index, activity);
                      }).toList(),

                      SizedBox(height: 20.h),

                      FloatingActionButton(
                        onPressed: _addActivity,
                        backgroundColor: AppColors.primaryColor,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),

                      SizedBox(height: 20.h),

                      _buildDateTimePointsSection(totalAfterReview),

                      SizedBox(height: 20.h),

                      _buildRewardsSection(),

                      SizedBox(height: 30.h),

                      _buildContactSection(),

                      SizedBox(height: 20.h),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitActivities,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.w,
                                  ),
                                )
                              : const Text(
                                  'إرسال الأنشطة للمراجعة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }


  Widget _buildActivityEntry(int index, ActivityEntry activity) {
    return Column(
      children: [
        _GlassPanel(
          child: Column(
            children: [
              // headers
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white24, width: 1.w),
                          left: BorderSide(color: Colors.white24, width: 1.w),
                        ),
                      ),
                      child: const Text(
                        'اللينك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white24, width: 1.w),
                        ),
                      ),
                      child: const Text(
                        'التفاعل على المنصات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // left
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: activity.isUploading
                                ? null
                                : () => _pickImage(index),
                            child: Container(
                              width: 150.w,
                              height: 140.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 2.w,
                                ),
                              ),
                              child: activity.isUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : activity.selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Image.file(
                                        activity.selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.image_outlined,
                                          color: Colors.white38,
                                          size: 32,
                                        ),
                                        SizedBox(height: 4.h),
                                        const Text(
                                          'أرفق صورة',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          const Text(
                            'اختياري',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          TextField(
                            controller: activity.linkController,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.right,
                            decoration:  InputDecoration(
                              hintText: 'أدخل الرابط هنا',
                              hintStyle: TextStyle(
                                color: Colors.white30,
                                fontSize: 12.sp,
                                
                              ),
                              suffixIcon: Icon(Icons.link),
                              suffixIconColor: AppColors.textColor
                              // border: InputBorder.none,
                              // contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1.w, height: 300.h, color: Colors.white24),
                  // right
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value:
                                    _activityTypes.containsKey(
                                      activity.selectedActivity,
                                    )
                                    ? activity.selectedActivity
                                    : null,
                                hint: Text(
                                  'اختر التفاعل',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10.sp,
                                  ),
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white60,
                                ),
                                dropdownColor: AppColors.primaryColor,

                                // ✅ 1) allow taller items (important)
                                itemHeight: null,

                                // ✅ 2) allow dropdown to be taller overall
                                // menuMaxHeight: 550.h,

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),

                                items: _activityTypes.entries.map((entry) {
                                  final key = entry.key;
                                  final data = entry.value;
                                  final label = (data['label'] ?? key)
                                      .toString();

                                  return DropdownMenuItem<String>(
                                    value: key,

                                    // ✅ 3) make each row taller + multiline
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.h,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          label,
                                          textAlign: TextAlign.right,
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),

                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      activity.selectedActivity = newValue;
                                      activity.activityType = newValue;
                                      activity.activityLabel =
                                          _activityTypes[newValue]?['label'] ??
                                          newValue;
                                      activity.points =
                                          _activityTypes[newValue]?['points'] ??
                                          0;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          if (activity.points > 0) ...[
                            SizedBox(height: 12.h),
                            Text(
                              '${activity.points} نقطة',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_activities.length > 1) ...[
          SizedBox(height: 8.h),
          IconButton(
            onPressed: () => _removeActivity(index),
            icon: const Icon(Icons.remove_circle, color: Colors.red),
          ),
        ],
        SizedBox(height: 12.h),
      ],
    );
  }

 Widget _buildDateTimePointsSection(int totalAfterReview) {
  return _GlassPanel(
    child: Column(
      children: [
        // Header Row with connected borders
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:   EdgeInsets.symmetric(vertical: 15.h),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white24, width: 1.w),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),   
                     const AppText(
                    title:
                        'آخر وقت للمراجعة',
                      
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                       
                      ),
                    ],
                  ),
                ),
              ),
              // Vertical divider that connects to horizontal line
              Container(
                width: 1.w,
                color: Colors.white24,
              ),
              Expanded(
                child: Container(
                  padding:   EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white24, width: 1.w),
                    ),
                  ),
                  child: const AppText(
                    title: 'إجمالي النقاط بعد المراجعة',
                    textAlign: TextAlign.center,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content Row
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(data: ThemeData.dark(), child: child!);
                      },
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(data: ThemeData.dark(), child: child!);
                        },
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = date;
                          selectedTime = time;
                        });
                      }
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: AppText(
                      title:
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}  ${selectedTime.format(context)}',
                      textAlign: TextAlign.center,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1.w,
                color: Colors.white24,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: AppText(
                      title:
                    '$totalAfterReview نقطة',
                    textAlign: TextAlign.center,
                    
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                   
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildRewardsSection() {
    if (_rewards.isEmpty) return const SizedBox.shrink();

    return RewardsSelectionTable(
      userPoints: _userPoints,
      rewards: _rewards,
      onSelectionChanged: (selectedRewards) {
        setState(() {
          _selectedRewards = selectedRewards;

          // حساب النقاط المخصومة مؤقتاً
          _temporaryDeductedPoints = 0;
          for (var reward in selectedRewards) {
            final rawReq = reward['requiredPoints'] ?? reward['points'] ?? 0;
            int required;
            if (rawReq is num) {
              required = rawReq.toInt();
            } else if (rawReq is String) {
              required = int.tryParse(rawReq) ?? 0;
            } else {
              required = 0;
            }
            _temporaryDeductedPoints += required;
          }
        });
      },
    );
  }

  /// واتساب + زر مستقل لطلب اجتماع

  Widget _buildContactSection() {
    final hasSelection = _selectedRewards.isNotEmpty;

    return Column(
      children: [
          Text(
          'تواصل مباشرة على الواتساب',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: hasSelection ? _sendToWhatsApp : null,
          icon: const Icon(Icons.message, color: Colors.white),
          label:   Text(
            'واتســـاب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection
                ? const Color(0xFF25D366)
                : Colors.grey,
            padding:   EdgeInsets.symmetric(horizontal: 60.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        const Text('أو', style: TextStyle(color: Colors.white60, fontSize: 14)),
        SizedBox(height: 20.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: hasSelection ? _requestMeeting : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelection
                  ? AppColors.primaryColor
                  : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: const Text(
              'اطلب اجتماع لمناقشة تفاصيل الخدمة المختارة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (!hasSelection) ...[
          SizedBox(height: 8.h),
          const Text(
            'يجب اختيار مكافأة واحدة على الأقل',
            style: TextStyle(color: Colors.orange, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    for (var activity in _activities) {
      activity.dispose();
    }
    super.dispose();
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassPanel({Key? key, required this.child, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.4.w,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
