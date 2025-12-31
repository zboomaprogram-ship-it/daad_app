import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/dashboard/forms/profile_changes_review_tab.dart';
import 'package:daad_app/features/dashboard/tabs/activities_tab.dart';
import 'package:daad_app/features/dashboard/tabs/articles_tab.dart';
import 'package:daad_app/features/dashboard/tabs/bookings_tab.dart';

import 'package:daad_app/features/dashboard/tabs/inbox_tab.dart';
import 'package:daad_app/features/dashboard/tabs/learn_tab.dart';
import 'package:daad_app/features/dashboard/tabs/notifications_tab.dart';
import 'package:daad_app/features/dashboard/tabs/points_review_tab.dart';
import 'package:daad_app/features/dashboard/tabs/portfolio_tab.dart';
import 'package:daad_app/features/dashboard/tabs/redeem_requests_tab.dart';
import 'package:daad_app/features/dashboard/tabs/rewards_tab.dart';
import 'package:daad_app/features/dashboard/tabs/services_tab.dart';
import 'package:daad_app/features/dashboard/tabs/settings_tab.dart';
import 'package:daad_app/features/dashboard/tabs/users_tab.dart';
import 'package:flutter/material.dart';
 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 13, vsync: this);
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
        title: const AppText(title: 'لوحة تحكّم DAAD'),
        backgroundColor: AppColors.primaryColor,
        bottom: TabBar(
          tabAlignment: TabAlignment.center,
          labelColor: AppColors.textColor,
          dividerColor: AppColors.secondaryColor,
          indicatorColor: AppColors.textColor,
          labelStyle: const TextStyle(
            fontFamily: 'TheYearOfCamel'
          ),
          unselectedLabelColor: AppColors.textColor,
          
          controller: _tabController,
          
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.settings,color: AppColors.textColor,), text: 'إعدادات',),
            Tab(icon: Icon(Icons.design_services,color: AppColors.textColor), text: 'الخدمات'),
            Tab(icon: Icon(Icons.article,color: AppColors.textColor), text: 'المقالات'),
            Tab(icon: Icon(Icons.book,color: AppColors.textColor), text: 'تعلم مع ضاد'),
            Tab(icon: Icon(Icons.people,color: AppColors.textColor), text: 'المستخدمون'),
            Tab(icon: Icon(Icons.edit,color: AppColors.textColor), text: 'مراجعة تغييرات الملف الشخصي'),
            Tab(icon: Icon(Icons.access_time,color: AppColors.textColor), text: 'الانشطه'),
            Tab(icon: Icon(Icons.present_to_all,color: AppColors.textColor), text: 'الجوايز'),
            Tab(icon: Icon(Icons.point_of_sale,color: AppColors.textColor), text: 'point'),
            Tab(icon: Icon(Icons.redeem,color: AppColors.textColor), text: 'redeem'),
            Tab(icon: Icon(Icons.work,color: AppColors.textColor), text: 'الأعمال'),
            Tab(icon: Icon(Icons.message,color: AppColors.textColor), text: 'Chats'),
            Tab(icon: Icon(Icons.notification_add,color: AppColors.textColor), text: 'الاشعارات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SettingsTab(),
          ServicesTab(),
          ArticlesTab(),
          LearnTab(),
          UsersTab(), 
          ProfileChangesReviewTab(),
          ActivitiesTab(),
          RewardsTab(),
          PointsReviewTab(), 
          RedeemRequestsTab(), 
          PortfolioTab(),
          SupportChatsTab(),
          NotificationsTab(),
        ],
      ),
    );
  }
}