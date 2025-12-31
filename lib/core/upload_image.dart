import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UploadState { idle, uploading, success, failed }

class ServiceImage {
  final String id;            // local id for edit/delete/replace in UI
  String data;                // base64 string (or URL later if you switch to Storage)
  UploadState state;
  double progress;            // 0..1 (handy if you switch to Storage)

  ServiceImage({
    required this.id,
    required this.data,
    this.state = UploadState.idle,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'data': data,             // base64 (current)
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory ServiceImage.fromMap(Map<String, dynamic> m) => ServiceImage(
    id: (m['id'] ?? const Uuid().v4()) as String,
    data: (m['data'] ?? '') as String,
    state: UploadState.success,
    progress: 1.0,
  );
}

bool _isBase64(String s) {
  // very light check: starts with data or decodes OK
  if (s.startsWith('data:image')) return true;
  try { base64Decode(s); return true; } catch (_) { return false; }
}

Future<String?> _uploadImage(XFile image) async {
  try {
    // فتح الصورة
    File imageFile = File(image.path);

    // قراءة الصورة كـ بايتات
    List<int> imageBytes = await imageFile.readAsBytes();

    // تحويل الصورة إلى Base64
    String base64Image = base64Encode(imageBytes);

    // الآن قم بتخزين السلسلة النصية Base64 في Firestore
    await FirebaseFirestore.instance.collection('images').add({
      'imageData': base64Image,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return base64Image; // إرجاع Base64 بدلاً من URL
  } catch (e) {
    print('حدث خطأ أثناء رفع الصورة: $e');
    return null;
  }
}

class ImagesPickerGrid extends StatelessWidget {
  final List<ServiceImage> images;
  final VoidCallback onAddPressed;
  final void Function(int index) onDelete;
  final void Function(int index) onReplace;

  const ImagesPickerGrid({
    super.key,
    required this.images,
    required this.onAddPressed,
    required this.onDelete,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];

    // image tiles
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      tiles.add(
        Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isBase64(img.data)
                    ? Image.memory(
                        base64Decode(img.data),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        img.data,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            // overlay for states
            if (img.state == UploadState.uploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text('جارٍ الرفع...',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),

            if (img.state == UploadState.failed)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withOpacity(0.35),
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 36),
                  ),
                ),
              ),

            // actions (replace / delete)
            Positioned(
              top: 6,
              right: 6,
              child: Row(
                children: [
                  _IconChip(
                    tooltip: 'استبدال',
                    icon: Icons.swap_horiz,
                    onTap: () => onReplace(i),
                  ),
                  const SizedBox(width: 6),
                  _IconChip(
                    tooltip: 'حذف',
                    icon: Icons.delete,
                    onTap: () => onDelete(i),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // add tile
    tiles.add(
      InkWell(
        onTap: onAddPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Icon(Icons.add_a_photo, size: 30),
          ),
        ),
      ),
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: tiles,
    );
  }
}

class _IconChip extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  const _IconChip({required this.tooltip, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}