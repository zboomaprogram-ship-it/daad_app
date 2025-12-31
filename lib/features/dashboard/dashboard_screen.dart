import 'package:daad_app/features/dashboard/tabs/articles_tab.dart';
import 'package:daad_app/features/dashboard/tabs/bookings_tab.dart';
import 'package:daad_app/features/dashboard/tabs/deals_wheel_tab.dart';
import 'package:daad_app/features/dashboard/tabs/inbox_tab.dart';
import 'package:daad_app/features/dashboard/tabs/notifications_tab.dart';
import 'package:daad_app/features/dashboard/tabs/portfolio_tab.dart';
import 'package:daad_app/features/dashboard/tabs/projects_tab.dart';
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
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكّم DAAD'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'إعدادات'),
            Tab(icon: Icon(Icons.design_services), text: 'الخدمات'),
            Tab(icon: Icon(Icons.article), text: 'المقالات'),
            Tab(icon: Icon(Icons.redeem), text: 'عجلة العروض'),
            Tab(icon: Icon(Icons.people), text: 'المستخدمون'),
            Tab(icon: Icon(Icons.work), text: 'الأعمال'),
            Tab(icon: Icon(Icons.business_center), text: 'المشاريع'),
            Tab(icon: Icon(Icons.event_available), text: 'الحجوزات'),
            Tab(icon: Icon(Icons.notification_add), text: 'الاشعارات'),
            Tab(icon: Icon(Icons.inbox), text: 'الرسائل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SettingsTab(),
          ServicesTab(),
          ArticlesTab(),
          DealsWheelTab(),
          UsersTab(), 
          PortfolioTab(),
          ProjectsTab(),
          BookingsTab(),
          NotificationsTab(),
          InboxTab(),
        ],
      ),
    );
  }
}