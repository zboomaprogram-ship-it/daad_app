import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/features/auth/presentation/sign_in_screen.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:daad_app/core/route_utils/route_utils.dart';
import 'package:daad_app/features/dashboard/dashboard_screen.dart';
import 'package:intl/intl.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Row(
          children: [
            GlassBackButton(),
          ],
        ),
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: GlassIconButton(
              icon: Icons.logout_rounded,
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                RouteUtils.pushAndPopAll(const LoginScreen());
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          // color: AppColors.primaryColor,
         image: DecorationImage(
      image: AssetImage("assets/images/background3.jpg"),
      fit: BoxFit.cover,

    ),
    
        ),
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'خطأ: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'لا توجد بيانات',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String userRole = userData['role'] ?? 'client';

              return CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Picture
                          GlassContainer(
                            width: 100,
                            height: 100,
                            child: ClipOval(
                              child: user?.photoURL != null
                                  ? Image.network(
                                      user!.photoURL!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            userData['name'] ?? 'مستخدم',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              userRole == 'admin' ? 'مدير' : 'عميل',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Info Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          ProfileInfoCard(
                            icon: Icons.email_outlined,
                            title: 'البريد الإلكتروني',
                            value: user?.email ?? 'غير متوفر',
                          ),
                          const SizedBox(height: 12),
                          ProfileInfoCard(
                            icon: Icons.phone_outlined,
                            title: 'رقم الهاتف',
                            value: userData['phone'] ?? 'غير متوفر',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Admin Dashboard Button
                  if (userRole == 'admin')
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ContactGlassButton(
                          onPressed: () => RouteUtils.push(const DashboardScreen()),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dashboard_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'لوحة التحكم',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Plans Section
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'خططك',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('plans')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: GlassContainer(
                              child: Center(
                                child: Text(
                                  'لا توجد خطط',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              var plan = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                              String serviceId = plan['serviceId'];
                              Timestamp addedAt = plan['addedAt'];
                              String formattedTime = DateFormat('yyyy-MM-dd – HH:mm').format(addedAt.toDate());

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('services').doc(serviceId).get(),
                                  builder: (context, serviceSnapshot) {
                                    if (!serviceSnapshot.hasData) {
                                      return const SizedBox();
                                    }
                                    var serviceData = serviceSnapshot.data!.data() as Map<String, dynamic>?;
                                    String serviceName = serviceData?['title'] ?? 'خدمة غير معروفة';

                                    return PlanCard(
                                      serviceName: serviceName,
                                      date: formattedTime,
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: snapshot.data!.docs.length,
                          ),
                        ),
                      );
                    },
                  ),

                  // Messages Section
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.message_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'رسائلك',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('inbox')
                        .where('userId', isEqualTo: user?.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: GlassContainer(
                              child: Center(
                                child: Text(
                                  'لا توجد رسائل',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              var message = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                              String status = message['status'] ?? 'pending';
                              String adminResponse = message['adminResponse'] ?? '';
                              Timestamp createdAt = message['createdAt'];
                              String formattedTime = DateFormat('yyyy-MM-dd – HH:mm').format(createdAt.toDate());

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: MessageCard(
                                  message: message['message'],
                                  date: formattedTime,
                                  status: status,
                                  adminResponse: adminResponse,
                                ),
                              );
                            },
                            childCount: snapshot.data!.docs.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}