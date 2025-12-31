// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:googleapis_auth/auth_io.dart';

// class NotificationService {
//   static Future<void> sendPushViaHttpV1({
//     required String targetFcmToken,
//     required String title,
//     required String body,
//   }) async {
//     // 👇 ملف الخدمة اللي نزلته من Firebase Console
//     final serviceAccountJson = File(
//       'C:/Users/omar2/OneDrive/Desktop/proj/secret/yall_50/yalla-50-firebase-adminsdk-fbsvc-74e1ab968e.json',
//     );
//     final credentials = ServiceAccountCredentials.fromJson(
//       serviceAccountJson.readAsStringSync(),
//     );

//     final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

//     // ⛓️ احصل على Access Token
//     final authClient = await clientViaServiceAccount(credentials, scopes);
//     final accessToken = authClient.credentials.accessToken.data;

//     final dio = Dio();

//     const projectId = 'yalla-50'; // 👈 استبدله بـ ID مشروعك

//     final url =
//         'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

//     final payload = {
//       "message": {
//         "token": targetFcmToken,
//         "notification": {"title": title, "body": body},
//         "android": {
//           "priority": "high",
//           "notification": {"sound": "default"},
//         },
//         "apns": {
//           "payload": {
//             "aps": {"sound": "default"},
//           },
//         },
//       },
//     };

//     try {
//       final response = await dio.post(
//         url,
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $accessToken',
//           },
//         ),
//         data: jsonEncode(payload),
//       );

//       print('✅ Notification sent: ${response.statusCode}');
//     } catch (e) {
//       print('❌ Failed to send notification: $e');
//     } finally {
//       authClient.close();
//     }
//   }
// }
