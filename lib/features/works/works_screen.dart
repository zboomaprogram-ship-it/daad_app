import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/daad_image.dart';

class WorksScreen extends StatelessWidget {
  const WorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أعمالنا')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('portfolio')
              .orderBy('order') // Make sure 'order' field exists in Firestore
              .snapshots(),
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            
            final docs = s.data!.docs;
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12, 
                childAspectRatio: 1,
              ),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;

                // Handle image selection logic
                final img = (d['images'] is List && d['images'].isNotEmpty)
                    ? d['images'][0] // If 'images' is a list, get the first image
                    : d['imageUrl']; // Else use the 'imageUrl' field
                
                // Handle missing images by using a default image
                final imageUrl = img ?? kDefaultImage;

                return Card(
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned.fill(child: DaadImage(imageUrl)), // Use DaadImage for handling Base64 or URL
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            d['title'] ?? 'عمل',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
