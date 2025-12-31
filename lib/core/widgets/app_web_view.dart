// // lib/core/widgets/app_webview_screen.dart
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class AppWebViewScreen extends StatelessWidget {
//   final String url;
//   final String title;

//   const AppWebViewScreen({super.key, required this.url, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     final controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..loadRequest(Uri.parse(url));

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       body: WebViewWidget(controller: controller),
//     );
//   }
// }
