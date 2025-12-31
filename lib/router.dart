// import 'package:flutter/material.dart';
// import 'package:daad_app/core/widgets/custom_back_button.dart';

// import 'features/home/home_screen.dart';
// import 'features/about/about_screen.dart';
// import 'features/services/services_screen.dart';
// import 'features/works/works_screen.dart';
// import 'features/contact/contact_screen.dart';
// import 'features/dashboard/dashboard_screen.dart';
// import 'features/articles/articles_screen.dart';
// import 'features/portfolio/portfolio_screen.dart';

// final appRouter = GoRouter(
//   initialLocation: '/',
//   routes: [
//     GoRoute(path: '/', name: 'home', builder: (c, s) => const HomeScreen()),

//     // تبويبات/شاشات عامة
//     GoRoute(path: '/about',    name: 'about',    builder: (c, s) => const AboutScreen()),
//     GoRoute(path: '/services', name: 'services', builder: (c, s) => const ServicesScreen()),
//     GoRoute(path: '/works',    name: 'works',    builder: (c, s) => const WorksScreen()),
//     GoRoute(path: '/contact',  name: 'contact',  builder: (c, s) => const ContactScreen()),
//     GoRoute(path: '/dashboard',name: 'dashboard',builder: (c, s) => const DashboardScreen()),
//     GoRoute(path: '/portfolio',name: 'portfolio',builder: (c, s) => const PortfolioScreen()),
//     GoRoute(path: '/articles', name: 'articles', builder: (c, s) => const ArticlesScreen()),
//   ],
//   errorBuilder: (c, s) => Scaffold(
//     body: Center(child: AppText(title:'حدث خطأ: ${s.error}')),
//   ),
// );
