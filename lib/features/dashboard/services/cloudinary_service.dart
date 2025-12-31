// import 'dart:io';
// import 'package:daad_app/core/constants.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:file_picker/file_picker.dart';

// class CloudinaryService {
//   // Replace with your Cloudinary credentials
//   static const String cloudName = KcloudName;
//   static const String uploadPreset = KuploadPreset;

//   /// Upload PDF to Cloudinary
//   static Future<String?> uploadPdf(File file) async {
//     try {
//       final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');
//       final request = http.MultipartRequest('POST', url);
//       request.fields['upload_preset'] = uploadPreset;
//       request.fields['resource_type'] = 'raw';
      
//       request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
//       final response = await request.send();
      
//       if (response.statusCode == 200) {
//         final responseData = await response.stream.toBytes();
//         final responseString = String.fromCharCodes(responseData);
//         final jsonMap = json.decode(responseString);
//         return jsonMap['secure_url'];
//       }
      
//       return null;
//     } catch (e) {
//       print('Error uploading to Cloudinary: $e');
//       return null;
//     }
//   }

//   /// Pick PDF file
//   static Future<File?> pickPdfFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );

//       if (result != null && result.files.single.path != null) {
//         return File(result.files.single.path!);
//       }
//       return null;
//     } catch (e) {
//       print('Error picking file: $e');
//       return null;
//     }
//   }
// }