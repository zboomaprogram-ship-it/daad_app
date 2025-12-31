// import 'package:daad_app/core/route_utils/route_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:daad_app/features/services/remote_config_service.dart';
// import 'package:daad_app/features/home/home_screen.dart';
// import 'package:daad_app/features/services/services_screen.dart';
// import 'package:daad_app/features/works/works_screen.dart';
// import 'package:daad_app/features/contact/contact_screen.dart';

// class DaadBottomNav extends StatelessWidget {
//   const DaadBottomNav({super.key});

//   // Method to get the index based on the current location
//   int _indexForLocation(String location) {
//     if (location.startsWith('/services')) return 1;
//     if (location.startsWith('/works') || location.startsWith('/portfolio')) return 2;
//     if (location.startsWith('/contact')) return 3;
//     return 0; // '/'
//   }

//   @override
//   Widget build(BuildContext context) {
//     // استخدام GoRouter للحصول على الموقع الحالي
//     // final rc = RemoteConfigService.instance;
//     // final theme = Theme.of(context);
//     return BottomNavigationBar(
//       backgroundColor: Colors.yellow,
//       selectedItemColor: Colors.blueAccent,
//       unselectedItemColor: Colors.blueAccent,
//       currentIndex: _indexForLocation('/'), // نحدد الفهرس بناءً على الموقع
//       onTap: (i) {
//         switch (i) {
//           case 0:
//             RouteUtils.push(const HomeScreen()); // الذهاب إلى الصفحة الرئيسية
//             break;
//           case 1:
//             RouteUtils.push(const ServicesScreen()); // الذهاب إلى صفحة الخدمات
//             break;
//           case 2:
//             RouteUtils.push(const WorksScreen()); // الذهاب إلى صفحة الأعمال
//             break;
//           case 3:
//             RouteUtils.push(const ContactScreen()); // الذهاب إلى صفحة التواصل
//             break;
//         }
//       },
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home, color: Colors.blueAccent),
//           label: 'الرئيسية',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.design_services, color: Colors.blueAccent),
//           label: 'الخدمات',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.collections, color: Colors.blueAccent),
//           label: 'الأعمال',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.mail, color:Colors.blueAccent),
//           label: 'تواصل',
//         ),
//       ],
//     );
//   }
// }