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
            Tab(
              icon: Icon(Icons.people, color: AppColors.textColor),
              text: 'المستخدمون',
            ),
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
        children: const [UsersTab(), SupportChatsTab(), NotificationsTab()],
      ),
    );
  }
}
