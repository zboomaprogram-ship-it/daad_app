import 'dart:convert';
import 'dart:ui';
import 'package:daad_app/core/widgets/glass_button.dart';
import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String serviceId;
  final VoidCallback onAddToPlan;
  final VoidCallback onBookConsultation;
  final VoidCallback onViewDetails;

  const ServiceCard({
    required this.data,
    required this.serviceId,
    required this.onAddToPlan,
    required this.onBookConsultation,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent.withOpacity(0.2),
              Colors.transparent.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
          
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Builder(
                        builder: (context) {
                          final imageUrl = data['imageUrl'];
                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            try {
                              final cleanBase64 = imageUrl
                                  .toString()
                                  .replaceAll('"', '')
                                  .replaceAll('\n', '')
                                  .replaceAll('\r', '')
                                  .trim();
                              return Image.memory(
                                base64Decode(cleanBase64),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.transparent.withOpacity(0.4),
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white.withOpacity(0.4),
                                      size: 40,
                                    ),
                                  );
                                },
                              );
                            } catch (e) {
                              return Container(
                                color: Colors.transparent.withOpacity(0.4),
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 40,
                                ),
                              );
                            }
                          }
                          return Container(
                            color: Colors.transparent.withOpacity(0.4),
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'خدمة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['desc'] ?? 'وصف مختصر للخدمة',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: 'أضف للخطة',
                      icon: Icons.add_circle_outline,
                      onPressed: onAddToPlan,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: 'احجز استشارة',
                      icon: Icons.calendar_today,
                      onPressed: onBookConsultation,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
              
            ],
          ),
        ),
        
      ),
    );
  }
}