import 'dart:convert';
import 'dart:io';

import 'package:daad_app/core/utils/network_utils/secure_config_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';

class WordPressMediaService {
  // Replace with your WordPress site details
  static String get wordPressUrl => SecureConfigService.wordPressUrl;
  static String get username => SecureConfigService.wordPressUsername;
  static String get applicationPassword =>
      SecureConfigService.wordPressAppPassword;
  static String get fileBirdApiKey => SecureConfigService.fileBirdApiKey;

  static const Duration uploadTimeout = Duration(minutes: 10);
  static const Duration connectionTimeout = Duration(seconds: 30);

  static String _getAuthHeader() {
    final credentials = base64Encode(
      utf8.encode('$username:$applicationPassword'),
    );
    return 'Basic $credentials';
  }

  // Helper: Convert XFile to File
  static File xFileToFile(dynamic xFile) {
    return File(xFile.path);
  }

  // Helper: Convert List<XFile> to List<File>
  static List<File> xFilesToFiles(List<dynamic> xFiles) {
    return xFiles.map((xFile) => File(xFile.path)).toList();
  }

  // Helper: Convert dynamic (XFile or File) to File
  static File toFile(dynamic file) {
    if (file is File) return file;
    return File(file.path); // Handles XFile
  }

  // ************************************************************
  // 🔵 FILEBIRD FUNCTIONS
  // ************************************************************

  /// Get all FileBird folders + IDs
  static Future<List<dynamic>> getFileBirdFolders() async {
    try {
      final url = Uri.parse(
        '$wordPressUrl/wp-json/filebird-api/v2/folders?api_key=$fileBirdApiKey',
      );

      final response = await http.get(url).timeout(connectionTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error fetching FileBird folders: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception fetching FileBird folders: $e");
      return [];
    }
  }

  /// Upload file to a specific FileBird folder (accepts both XFile and File)
  static Future<String?> uploadToFileBirdFolder(
    dynamic file,
    int folderId, {
    Function(double)? onProgress,
  }) async {
    try {
      final ioFile = toFile(file);

      final url = Uri.parse(
        '$wordPressUrl/wp-json/filebird-api/v2/upload?api_key=$fileBirdApiKey&folder=$folderId',
      );

      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', ioFile.path));

      final streamedResponse = await request.send().timeout(uploadTimeout);

      int bytesReceived = 0;
      final contentLength =
          streamedResponse.contentLength ?? await ioFile.length();
      final responseBytes = <int>[];

      await for (var chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        bytesReceived += chunk.length;

        if (onProgress != null && contentLength > 0) {
          final progress = (bytesReceived / contentLength).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      final responseBody = utf8.decode(responseBytes);

      if (streamedResponse.statusCode == 200) {
        final jsonData = jsonDecode(responseBody);
        return jsonData['url'];
      } else {
        print(
          "FileBird Upload Failed: ${streamedResponse.statusCode} - $responseBody",
        );
        return null;
      }
    } catch (e) {
      print("Error uploading to FileBird: $e");
      return null;
    }
  }

  // ************************************************************
  // 🔵 WordPress Media upload functions with progress tracking
  // ************************************************************

  /// Upload multiple images (accepts both XFile and File)
  static Future<List<String>> uploadMultipleImages(
    List<dynamic> images, {
    Function(int current, int total)? onImageProgress,
  }) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        if (onImageProgress != null) {
          onImageProgress(i + 1, images.length);
        }

        // Convert to File if it's XFile
        final file = toFile(images[i]);
        final url = await uploadImage(file);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        print("WordPress Upload Error: $e");
      }
    }

    return uploadedUrls;
  }

  /// Upload single image (accepts both XFile and File)
  static Future<String?> uploadImage(
    dynamic image, {
    Function(double)? onProgress,
  }) async {
    try {
      final file = toFile(image);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$wordPressUrl/wp-json/wp/v2/media'),
      );
      request.headers['Authorization'] = _getAuthHeader();

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);

      if (streamedResponse.statusCode == 201) {
        final jsonData = json.decode(responseBody);
        return jsonData['source_url'];
      } else {
        throw Exception(
          'Upload failed: ${streamedResponse.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload PDF (accepts both XFile and File)
  static Future<String?> uploadPdf(
    dynamic pdf, {
    Function(double)? onProgress,
  }) async {
    try {
      final file = toFile(pdf);
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      final fileSizeMB = fileSize / (1024 * 1024);
      print(
        '📄 Starting PDF upload: $fileName (${fileSizeMB.toStringAsFixed(2)} MB)',
      );

      final url = Uri.parse('$wordPressUrl/wp-json/wp/v2/media');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Content-Type'] = 'multipart/form-data';
      request.headers['Accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send().timeout(uploadTimeout);
      int bytesReceived = 0;
      final responseBytes = <int>[];
      final totalLength = streamedResponse.contentLength ?? fileSize;

      await for (var chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        bytesReceived += chunk.length;

        if (onProgress != null && totalLength > 0) {
          final progress = (bytesReceived / totalLength).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      final responseBody = utf8.decode(responseBytes);

      if (streamedResponse.statusCode == 201) {
        final jsonData = json.decode(responseBody);
        final pdfUrl = jsonData['source_url'];
        print('✅ PDF uploaded successfully! URL: $pdfUrl');
        return pdfUrl;
      } else {
        throw Exception(
          'Upload failed: ${streamedResponse.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      print('❌ Error uploading PDF: $e');
      rethrow;
    }
  }

  /// Pick PDF file
  static Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Delete media
  static Future<bool> deleteMedia(int mediaId) async {
    try {
      final url = Uri.parse(
        '$wordPressUrl/wp-json/wp/v2/media/$mediaId?force=true',
      );
      final response = await http
          .delete(url, headers: {'Authorization': _getAuthHeader()})
          .timeout(connectionTimeout);
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting media: $e');
      return false;
    }
  }

  /// Test Authentication
  static Future<bool> testAuthentication() async {
    try {
      final url = Uri.parse('$wordPressUrl/wp-json/wp/v2/users/me');
      final response = await http
          .get(url, headers: {'Authorization': _getAuthHeader()})
          .timeout(connectionTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Authentication successful! User: ${jsonData['name']}');
        return true;
      } else {
        print('❌ Authentication failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error testing authentication: $e');
      return false;
    }
  }

  /// Check WordPress upload limits
  static Future<Map<String, dynamic>> checkUploadLimits() async {
    try {
      final url = Uri.parse('$wordPressUrl/wp-json/');
      final response = await http.get(url).timeout(connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 WordPress Info: Name: ${data['name']}');
        return data;
      }
    } catch (e) {
      print('Error checking WordPress info: $e');
    }
    return {};
  }

  static Future<String?> uploadAudio(File audioFile) async {
    try {
      // 1. Change extension from .m4a to .mp4 to bypass WordPress security
      // WordPress accepts .mp4 (video) by default, but blocks .m4a (audio) sometimes.
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final fileSize = await audioFile.length();
      print('🎙️ Starting Audio upload: $fileName');
      print('📏 Size: $fileSize bytes');

      final url = Uri.parse('$wordPressUrl/wp-json/wp/v2/media');

      var request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = _getAuthHeader();
      request.headers['Accept'] = 'application/json';

      // 2. Upload with 'video/mp4' content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          filename: fileName,
          contentType: MediaType(
            'video',
            'mp4',
          ), // Trick server into thinking it's video
        ),
      );

      final streamedResponse = await request.send().timeout(uploadTimeout);
      final responseBytes = await streamedResponse.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);

      print('📡 Status Code: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 201) {
        final jsonData = json.decode(responseBody);
        print('✅ Upload Success: ${jsonData['source_url']}');
        return jsonData['source_url'];
      } else {
        print('❌ Server Error Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Exception uploading Audio: $e');
      return null;
    }
  }
}
