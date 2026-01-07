import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';

import 'package:daad_app/features/dashboard/tabs/inbox_tab.dart';
import 'package:daad_app/features/dashboard/tabs/notifications_tab.dart';
import 'package:daad_app/features/dashboard/tabs/users_tab.dart';
import 'package:flutter/material.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const AppText(title: 'لوحة تحكّم Sales'),
        backgroundColor: AppColors.primaryColor,
        bottom: TabBar(
          tabAlignment: TabAlignment.center,
          labelColor: AppColors.textColor,
          dividerColor: AppColors.secondaryColor,
          indicatorColor: AppColors.textColor,
          labelStyle: const TextStyle(fontFamily: 'TheYearOfCamel'),
          unselectedLabelColor: AppColors.textColor,

          controller: _tabController,

          isScrollable: true,
          tabs: const [
            // Tab(icon: Icon(Icons.settings,color: AppColors.textColor,), text: 'إعدادات',),
            // Tab(icon: Icon(Icons.design_services,color: AppColors.textColor), text: 'الخدمات'),
            // Tab(icon: Icon(Icons.article,color: AppColors.textColor), text: 'المقالات'),
            // Tab(icon: Icon(Icons.book,color: AppColors.textColor), text: 'تعلم مع ضاد'),
            Tab(
              icon: Icon(Icons.people, color: AppColors.textColor),
              text: 'المستخدمون',
            ),
            // Tab(icon: Icon(Icons.edit,color: AppColors.textColor), text: 'مراجعة تغييرات الملف الشخصي'),
            // Tab(icon: Icon(Icons.access_time,color: AppColors.textColor), text: 'الانشطه'),
            // Tab(icon: Icon(Icons.present_to_all,color: AppColors.textColor), text: 'الجوايز'),
            // Tab(icon: Icon(Icons.point_of_sale,color: AppColors.textColor), text: 'point'),
            // Tab(icon: Icon(Icons.redeem,color: AppColors.textColor), text: 'redeem'),
            // Tab(icon: Icon(Icons.work,color: AppColors.textColor), text: 'الأعمال'),
            Tab(
              icon: Icon(Icons.message, color: AppColors.textColor),
              text: 'Chats',
            ),
            Tab(
              icon: Icon(Icons.notification_add, color: AppColors.textColor),
              text: 'الاشعارات',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // SettingsTab(),
          // ServicesTab(),
          // ArticlesTab(),
          // LearnTab(),
          UsersTab(),
          // ProfileChangesReviewTab(),
          // ActivitiesTab(),
          // RewardsTab(),
          // PointsReviewTab(),
          // RedeemRequestsTab(),
          // PortfolioTab(),
          SupportChatsTab(),
          NotificationsTab(),
        ],
      ),
    );
  }
}
