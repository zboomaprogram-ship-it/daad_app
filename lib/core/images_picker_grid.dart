import 'dart:convert';
import 'dart:io' show File;
import 'package:image_picker/image_picker.dart';

Future<List<String>> uploadMultipleImages(List<XFile> images) async {
    List<String> base64Images = [];
    
    for (var image in images) {
      try {
        File imageFile = File(image.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add(base64Image);
      } catch (e) {
        print('حدث خطأ أثناء رفع الصورة: $e');
      }
    }
    
    return base64Images;
  }
