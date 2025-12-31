import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';

import 'package:daad_app/features/services/service_card.dart';
import 'package:daad_app/features/services/services_detailes_screen.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:daad_app/features/consultation/consultation_screen.dart'; // Import consultation screen

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  Future<void> _addToPlan(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No authenticated user. Cannot add service to plan.');
      return;
    }
    final userId = user.uid;

    final planRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('plans');

    await planRef.add({
      'serviceId': serviceId,
      'addedAt': FieldValue.serverTimestamp(),
      'userid': userId,
    });
    debugPrint('Service added to plan');
  }

  void _bookConsultation(BuildContext context, String serviceTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationScreen(serviceTitle: serviceTitle),
      ),
    );
  }

  void _viewServiceDetails(BuildContext context, Map<String, dynamic> serviceData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(
          title: serviceData['title'],
          description: serviceData['desc'],
          imageUrl: serviceData['images'],
          priceTiers: serviceData['priceTiers'] ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [
          //     const Color(0xFF7A4458),
          //     const Color(0xFF5D3344),
          //     const Color(0xFF4A2735),
          //   ],
          // ),
          color: AppColors.primaryColor
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الخدمات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Services List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .orderBy('order')
                      .snapshots(),
                  builder: (c, s) {
                    if (!s.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    final docs = s.data!.docs;
                    return ListView.separated(
                      padding: const EdgeInsets.only(right: 16,left: 16,top: 16,bottom: 100),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final serviceId = docs[i].id;
                        return ServiceCard(
                          data: d,
                          serviceId: serviceId,
                          onAddToPlan: () => _addToPlan(serviceId),
                          onBookConsultation: () => _bookConsultation(context, d['title']),
                          onViewDetails: () => _viewServiceDetails(context, d),
                        );
                      },
                    );
                  },
                ),
              ),
          
            ],
          ),
        ),
      ),
    );
  }
}

