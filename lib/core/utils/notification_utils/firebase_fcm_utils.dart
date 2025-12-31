// import 'package:dio/dio.dart';
// import 'package:flutter/services.dart';
// import 'package:googleapis_auth/auth_io.dart' as auth;

// Future<String> getAccessToken() async {
//   final serviceAccountJson = await rootBundle.loadString(
//     '',
//   );

//   final accountCredentials = auth.ServiceAccountCredentials.fromJson(
//     serviceAccountJson,
//   );

//   final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

//   final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
//   final accessToken = client.credentials.accessToken.data;

//   client.close();
//   return accessToken;
// }

// Future<void> sendPushNotification({
//   required String fcmToken,
//   required String title,
//   required String body,
// }) async {
//   final accessToken = await getAccessToken();
//   const String projectId = "yalla-50"; // ⚠️ لازم تعدله

//   final message = {
//     "message": {
//       "token": fcmToken,
//       "notification": {"title": title, "body": body},
//       "android": {
//         "priority": "high",
//         "notification": {"sound": "default"},
//       },
//     },
//   };

//   final dio = Dio();

//   await dio.post(
//     'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
//     options: Options(
//       headers: {
//         'Authorization': 'Bearer $accessToken',
//         'Content-Type': 'application/json',
//       },
//     ),
//     data: message,
//   );
// }
