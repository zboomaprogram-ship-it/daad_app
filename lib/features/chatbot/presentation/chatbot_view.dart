// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:daad_app/core/constants.dart';
// import 'package:daad_app/core/utils/app_colors/app_colors.dart';
// import 'package:daad_app/core/utils/network_utils/secure_config_service.dart';
// import 'package:daad_app/core/widgets/app_text.dart';
// import 'package:daad_app/features/contact/widgets.dart';
// import 'package:daad_app/features/dashboard/services/chatbot_persona_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// class ChatBotScreen extends StatefulWidget {
//   const ChatBotScreen({super.key});
//   @override
//   State<ChatBotScreen> createState() => _ChatBotScreenState();
// }
// class _ChatBotScreenState extends State<ChatBotScreen> {
//   final List<ChatMessage> _messages = [];
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   bool _isTyping = false;
//   bool _isLoading = true;
//   bool _isFirstTimeUser = true;
//   bool _hasIntroduced = false;

//   List<Map<String, dynamic>> _servicesData = [];
//   bool _servicesLoaded = false;

//   ChatBotPersona? _persona;

//   @override
//   void initState() {
//     super.initState();
//     _initChat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _initChat() async {
//     try {
//       _persona = await ChatBotPersonaService.getPersona();
//       print('✅ Loaded chatbot persona: ${_persona?.botName}');
//     } catch (e) {
//       print('❌ Error loading persona: $e');
//     }

//     await _loadServicesData();
//     await _cleanupOldMessages();
//     await _loadMessages();
//     await _checkAndSendWelcomeMessage();
//   }

//   Future<void> _loadServicesData() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('services')
//           .orderBy('order')
//           .get();

//       setState(() {
//         _servicesData = snapshot.docs.map((doc) {
//           final data = doc.data();
//           return {
//             'id': doc.id,
//             'title': data['title'] ?? '',
//             'desc': data['desc'] ?? '',
//             'category': data['category'] ?? '',
//             'priceTiers': data['priceTiers'] ?? [],
//             'images': data['images'] ?? [],
//           };
//         }).toList();
//         _servicesLoaded = true;
//       });

//       print('✅ Loaded ${_servicesData.length} services for chatbot');
//     } catch (e) {
//       print('❌ Error loading services: $e');
//       setState(() => _servicesLoaded = true);
//     }
//   }

//   Future<void> _cleanupOldMessages() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       final cutoff = DateTime.now().subtract(const Duration(days: 3));
//       final cutoffTs = Timestamp.fromDate(cutoff);

//       final oldSnap = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('chatMessages')
//           .where('timestamp', isLessThan: cutoffTs)
//           .get();

//       if (oldSnap.docs.isEmpty) {
//         print('✅ No old messages to cleanup');
//         return;
//       }

//       print('🗑️ Cleaning up ${oldSnap.docs.length} old messages...');

//       const batchSize = 450;
//       for (var i = 0; i < oldSnap.docs.length; i += batchSize) {
//         final batch = FirebaseFirestore.instance.batch();
//         final end = (i + batchSize < oldSnap.docs.length)
//             ? i + batchSize
//             : oldSnap.docs.length;

//         for (var j = i; j < end; j++) {
//           batch.delete(oldSnap.docs[j].reference);
//         }

//         await batch.commit();
//       }

//       print('✅ Cleaned up old messages successfully');
//     } catch (e) {
//       print('❌ Error cleaning up old messages: $e');
//     }
//   }

//   Future<void> _loadMessages() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('chatMessages')
//           .orderBy('timestamp', descending: false)
//           .get();

//       setState(() {
//         _messages.clear();

//         for (var doc in snapshot.docs) {
//           final data = doc.data();
//           _messages.add(
//             ChatMessage(
//               text: data['text'] ?? '',
//               isUser: data['isUser'] ?? false,
//               timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
//                   (data['clientTimestamp'] as Timestamp?)?.toDate() ??
//                   DateTime.now(),
//             ),
//           );
//         }

//         _isFirstTimeUser = _messages.isEmpty;
//         _hasIntroduced = _messages.any((m) => !m.isUser);

//         _isLoading = false;
//       });

//       // ✅ FIXED: Scroll to bottom after messages are loaded
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _scrollToBottom();
//       });

//       print(_isFirstTimeUser
//           ? '👋 First time user detected'
//           : '🔄 Returning user detected (${_messages.length} messages)');

//     } catch (e) {
//       print('❌ Error loading messages: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _checkAndSendWelcomeMessage() async {
//     if (_isLoading) return;

//     if (_messages.isNotEmpty) {
//       final lastMessage = _messages.last;
//       final hoursSinceLastMessage =
//           DateTime.now().difference(lastMessage.timestamp).inHours;

//       if (hoursSinceLastMessage < 1) {
//         print('⏭️ Skipping welcome (last message was ${hoursSinceLastMessage}h ago)');
//         return;
//       }
//     }

//     setState(() => _isTyping = true);

//     try {
//       String welcomeMessage;

//       if (_isFirstTimeUser) {
//         welcomeMessage = await _getAIWelcomeMessage(isFirstTime: true);
//       } else {
//         welcomeMessage = await _getAIWelcomeMessage(isFirstTime: false);
//       }

//       final botMessage = ChatMessage(
//         text: welcomeMessage,
//         isUser: false,
//         timestamp: DateTime.now(),
//       );

//       setState(() {
//         _messages.add(botMessage);
//         _isTyping = false;
//         _hasIntroduced = true;
//       });

//       await _saveMessage(welcomeMessage, false);
//       _scrollToBottom();

//     } catch (e) {
//       print('❌ Error sending welcome message: $e');
//       setState(() => _isTyping = false);
//     }
//   }

//   Future<String> _getAIWelcomeMessage({required bool isFirstTime}) async {
//     final apiKey = SecureConfigService.geminiApiKey;
//     const model = 'gemini-2.5-flash-lite';

//     if (_persona != null) {
//       final customWelcome = _persona!.getFinalWelcome(isFirstTime);

//       if (!customWelcome.contains('أنت') && customWelcome.length < 500) {
//         return customWelcome;
//       }
//     }

//     final prompt = isFirstTime
//         ? _persona?.getFinalWelcome(true) ?? '''أنت "مساعد ضاد"، مستشار أعمال وتسويق إلكتروني.

// هذا أول لقاء مع المستخدم. عرّف بنفسك بشكل ودود ومحترف.

// اجعل الترحيب:
// - قصير (3-4 جمل فقط)
// - دافئ ومرحب
// - يوضح دورك كمستشار
// - يدعو المستخدم للسؤال

// لا تذكر الخدمات تفصيلياً الآن.'''
//         : _persona?.getFinalWelcome(false) ?? '''أنت "مساعد ضاد"، مستشار أعمال.

// المستخدم عاد للمحادثة. رحب به بطريقة ودودة وبسيطة.

// اجعل الرد:
// - قصير جداً (1-2 جملة)
// - طبيعي وغير متكلف
// - اسأل كيف يمكنك المساعدة''';

//     final requestBody = {
//       "contents": [
//         {
//           "parts": [{"text": prompt}]
//         }
//       ],
//       "generationConfig": {
//         "temperature": 0.9,
//         "maxOutputTokens": 200,
//       }
//     };

//     try {
//       final url = Uri.parse(
//         "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
//       );

//       final response = await http
//           .post(
//             url,
//             headers: {"Content-Type": "application/json"},
//             body: json.encode(requestBody),
//           )
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

//         if (text != null && text.isNotEmpty) {
//           return text.trim();
//         }
//       }
//     } catch (e) {
//       print('❌ Error getting AI welcome: $e');
//     }

//     return isFirstTime
//         ? 'مرحباً بك! أنا مساعد ضاد، مستشارك الذكي للتسويق الإلكتروني وإدارة الأعمال. كيف يمكنني مساعدتك اليوم؟'
//         : 'أهلاً بعودتك! كيف يمكنني مساعدتك اليوم؟';
//   }

//   Future<void> _saveMessage(String text, bool isUser) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('chatMessages')
//           .add({
//         'text': text,
//         'isUser': isUser,
//         'timestamp': FieldValue.serverTimestamp(),
//         'clientTimestamp': Timestamp.fromDate(DateTime.now()),
//       });
//     } catch (e) {
//       print('❌ Error saving message: $e');
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   Future<void> _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     final userMessage = ChatMessage(
//       text: text,
//       isUser: true,
//       timestamp: DateTime.now(),
//     );

//     setState(() {
//       _messages.add(userMessage);
//       _controller.clear();
//       _isTyping = true;
//     });

//     await _saveMessage(text, true);
//     _scrollToBottom();

//     try {
//       final response = await _sendToGeminiAPI(text);

//       final botMessage = ChatMessage(
//         text: response,
//         isUser: false,
//         timestamp: DateTime.now(),
//       );

//       setState(() {
//         _messages.add(botMessage);
//         _isTyping = false;
//         _hasIntroduced = true;
//       });
//       await _saveMessage(response, false);
//       _scrollToBottom();
//     } catch (e) {
//       final errorMessage = ChatMessage(
//         text: 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.',
//         isUser: false,
//         timestamp: DateTime.now(),
//       );

//       setState(() {
//         _messages.add(errorMessage);
//         _isTyping = false;
//       });

//       await _saveMessage(errorMessage.text, false);
//     }
//   }

//   String _buildServicesContext() {
//     if (_servicesData.isEmpty) {
//       return "لا توجد خدمات متاحة حالياً.";
//     }

//     final servicesText = StringBuffer();
//     servicesText.writeln("📋 الخدمات المتوفرة في التطبيق:\n");

//     for (var service in _servicesData) {
//       servicesText.writeln("▪️ ${service['title']}");
//       servicesText.writeln("   الوصف: ${service['desc']}");
//       servicesText.writeln("   التصنيف: ${service['category']}");

//       if (service['priceTiers'] != null && service['priceTiers'].isNotEmpty) {
//         servicesText.writeln("   الباقات المتاحة:");
//         for (var tier in service['priceTiers']) {
//           final name = tier['name'] ?? 'غير محدد';
//           final price = tier['price'] ?? 0;
//           final features = tier['features'] ?? [];

//           servicesText.writeln("      - $name: ${price > 0 ? '$price ريال' : 'مجاني'}");
//           if (features.isNotEmpty) {
//             servicesText.writeln("        المميزات: ${features.join(', ')}");
//           }
//         }
//       }
//       servicesText.writeln();
//     }

//     return servicesText.toString();
//   }

//   Future<String> _sendToGeminiAPI(String message) async {
//     final apiKey = SecureConfigService.geminiApiKey;
//     const model = 'gemini-2.5-flash-lite';

//     if (!_servicesLoaded) {
//       await _loadServicesData();
//     }

//     String systemPrompt = _persona?.getFinalSystemPrompt() ?? _getDefaultSystemPrompt();

//     systemPrompt += '\n\n${_buildServicesContext()}';
//     systemPrompt += '\n\nحالة التعريف: ${_hasIntroduced ? "تم التعريف سابقاً - لا تعيد التعريف" : "أول رد - عرّف بنفسك"}';

//     const memoryLimit = 15;
//     final recentMessages = _messages.length > memoryLimit
//         ? _messages.sublist(_messages.length - memoryLimit)
//         : _messages;

//     List<Map<String, dynamic>> conversationHistory = [];

//     for (var msg in recentMessages) {
//       conversationHistory.add({
//         "role": msg.isUser ? "user" : "model",
//         "parts": [{"text": msg.text}]
//       });
//     }

//     conversationHistory.add({
//       "role": "user",
//       "parts": [{"text": message}]
//     });

//     final requestBody = {
//       "system_instruction": {
//         "parts": [{"text": systemPrompt}]
//       },
//       "contents": conversationHistory,
//       "generationConfig": {
//         "temperature": _persona?.temperature ?? 0.8,
//         "maxOutputTokens": _persona?.maxTokens ?? 8000,
//         "topP": 0.95,
//         "topK": 40,
//       },
//       "safetySettings": [
//         {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
//         {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
//         {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
//         {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
//       ]
//     };

//     try {
//       final url = Uri.parse(
//         "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
//       );

//       final response = await http
//           .post(
//             url,
//             headers: {"Content-Type": "application/json"},
//             body: json.encode(requestBody),
//           )
//           .timeout(const Duration(seconds: 45));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

//         if (text != null && text.isNotEmpty) {
//           return text;
//         } else {
//           return "لم أتمكن من فهم الرد. هل يمكنك إعادة صياغة السؤال؟";
//         }
//       } else {
//         print('❌ API Error: ${response.statusCode} - ${response.body}');
//         return "عذراً، الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.";
//       }
//     } catch (e) {
//       print("❌ Error: $e");
//       if (e.toString().contains('timeout')) {
//         return "عذراً، استغرق الرد وقتاً طويلاً. يرجى المحاولة مرة أخرى.";
//       }
//       return "عذراً، حدث خطأ في الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.";
//     }
//   }

//   String _getDefaultSystemPrompt() {
//     return '''أنت "مساعد ضاد" - مستشار أعمال وتسويق إلكتروني مطوّر خصيصًا لشركة ضاد للتسويق الإلكتروني.
// 🎯 هويتك:
// - الاسم: مساعد ضاد
// - الشركة: شركة ضاد للتسويق الإلكتروني (شركة مصرية / سعودية بخبرة تتجاوز 10 سنوات)
// - التخصص: إدارة الأعمال، التسويق الإلكتروني، تحليل الأسواق، سلوك المستهلك

// 🧠 شخصيتك وأسلوبك:
// - لطيف، ذكي، محترف، منظم، واقعي
// - تفهم عقلية العميل وتتحدث بطريقته
// - تعطي حلول عملية وليست نظرية

// 📌 قواعد الرد:
// 1. لا تعيد التعريف بنفسك في كل رد
// 2. اقرأ مستوى العميل وعدّل لغتك
// 3. اربط كل رد بهدف العميل التجاري
// 4. قدم حلول عملية

// 🚫 ممنوع:
// - تحديد مدد زمنية أو تكاليف مالية
// - إعطاء وعود غير واقعية
// - التحدث عن شركات منافسة''';
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));

//     final messageDate = DateTime(date.year, date.month, date.day);

//     if (messageDate == today) return 'اليوم';
//     if (messageDate == yesterday) return 'أمس';

//     return DateFormat('d MMMM yyyy', 'ar').format(date);
//   }

//   String _formatTime(DateTime time) {
//     return DateFormat('h:mm a', 'ar').format(time);
//   }

//   bool _shouldShowDateHeader(int index) {
//     if (index == 0) return true;

//     final current = _messages[index].timestamp;
//     final previous = _messages[index - 1].timestamp;

//     return current.day != previous.day ||
//         current.month != previous.month ||
//         current.year != previous.year;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Container(
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage(kBackgroundImage),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.w),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const GlassBackButton(),
//                     // SizedBox(height: 10,),
//                               AppText(
//                                 title: _persona?.botName ??  '',
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                     SizedBox(width: 40.w),

//                   ],
//                 ),
//               ),

//               // Messages Area
//               Expanded(
//                 child: _isLoading
//                     ? _buildShimmerLoading()
//                     : _messages.isEmpty && !_isTyping
//                         ? _buildEmptyChat()
//                         : _buildMessagesList(),
//               ),

//               // Typing Indicator
//               if (_isTyping) _buildTypingIndicator(),

//               // Input Field
//               _buildInputField(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildShimmerLoading() {
//     return ListView.builder(
//       padding: EdgeInsets.all(16.r),
//       itemCount: 4,
//       itemBuilder: (context, index) {
//         final isUser = index % 2 == 0;
//         return Padding(
//           padding: EdgeInsets.only(bottom: 16.h),
//           child: Row(
//             mainAxisAlignment:
//                 isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               if (!isUser) ...[
//                 Shimmer.fromColors(
//                   baseColor: Colors.white.withOpacity(0.1),
//                   highlightColor: Colors.white.withOpacity(0.3),
//                   child: CircleAvatar(
//                     radius: 16.r,
//                     backgroundColor: Colors.white,
//                   ),
//                 ),
//                 SizedBox(width: 8.w),
//               ],
//               Shimmer.fromColors(
//                 baseColor: Colors.white.withOpacity(0.1),
//                 highlightColor: Colors.white.withOpacity(0.3),
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.6,
//                   height: 60.h,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20.r),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyChat() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             // ✅ FIXED: Changed to SVG
//             child: SvgPicture.asset(
//               'assets/icons/chatbot.svg', // Replace with your SVG path
//               width: 64.w,
//               height: 64.h,
//               // colorFilter: const ColorFilter.mode(
//               //   // Colors.white,
//               //   // BlendMode.srcIn,
//               // ),
//             ),
//           ),
//           SizedBox(height: 24.h),
//           AppText(
//             title: 'مرحباً بك في ${_persona?.botName ?? "مساعد ضاد"}',
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//           SizedBox(height: 8.h),
//           AppText(
//             title: 'جاري التحضير...',
//             fontSize: 14,
//             color: Colors.white.withOpacity(0.7),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessagesList() {
//     return ListView.builder(
//       controller: _scrollController,
//       reverse: false,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       itemCount: _messages.length,
//       itemBuilder: (context, index) {
//         final message = _messages[index];
//         final showDateHeader = _shouldShowDateHeader(index);

//         return Column(
//           children: [
//             if (showDateHeader)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: AppText(
//                     title: _formatDate(message.timestamp),
//                     fontSize: 12,
//                     color: Colors.white.withOpacity(0.9),
//                   ),
//                 ),
//               ),
//             _MessageBubble(
//               message: message,
//               time: _formatTime(message.timestamp),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildTypingIndicator() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 16.r,
//             backgroundColor: Colors.white.withOpacity(0.2),
//             // ✅ FIXED: Changed to SVG
//             child: SvgPicture.asset(
//               'assets/icons/chatbot.svg', // Replace with your SVG path
//               width: 50.sp,
//               height: 50.sp,
//               // colorFilter: const ColorFilter.mode(
//               //   Colors.white,
//               //   BlendMode.srcIn,
//               // ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(20.r),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const _TypingDot(delay: 0),
//                 SizedBox(width: 4.h),
//                 const _TypingDot(delay: 200),
//                 SizedBox(width: 4.h),
//                 const _TypingDot(delay: 400),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputField() {
//     return Container(
//       padding: EdgeInsets.all(16.r),
//       decoration: BoxDecoration(
//         color: Colors.transparent,
//         border: Border(
//           top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.w),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.08),
//                 borderRadius: BorderRadius.circular(25.r),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.15),
//                   width: 1,
//                 ),
//               ),
//               child: TextField(
//                 controller: _controller,
//                 textAlign: TextAlign.right,
//                 style: TextStyle(color: Colors.white, fontSize: 14.sp),
//                 decoration: InputDecoration(
//                   hintText: 'اسأل ${_persona?.botName ?? "مساعد ضاد"} عن أي شيء...',
//                   hintStyle: TextStyle(
//                     color: Colors.white.withOpacity(0.4),
//                     fontSize: 14.sp,
//                   ),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 20.w,
//                     vertical: 8.h,
//                   ),
//                 ),
//                 onSubmitted: (_) => _sendMessage(),
//               ),
//             ),
//           ),
//           SizedBox(width: 12.w),
//           GestureDetector(
//             onTap: _sendMessage,
//             child: Container(
//               width: 45.w,
//               height: 45.h,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//               child: Icon(
//                 Icons.send,
//                 color: AppColors.secondaryTextColor,
//                 size: 25.sp,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Message Bubble Widget
// class _MessageBubble extends StatelessWidget {
//   final ChatMessage message;
//   final String time;

//   const _MessageBubble({required this.message, required this.time});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 16.h),
//       child: Row(
//         mainAxisAlignment:
//             message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!message.isUser) ...[
//             CircleAvatar(
//               radius: 16.r,
//               backgroundColor: Colors.white.withOpacity(0.2),
//               // ✅ FIXED: Changed to SVG
//               child: SvgPicture.asset(
//                 'assets/icons/chatbot.svg', // Replace with your SVG path
//                 width: 50.sp,
//                 height: 50.sp,
//                 // colorFilter: const ColorFilter.mode(
//                 //   Colors.white,
//                 //   BlendMode.srcIn,
//                 // ),
//               ),
//             ),
//             SizedBox(width: 8.w),
//           ],
//           Flexible(
//             child: Column(
//               crossAxisAlignment: message.isUser
//                   ? CrossAxisAlignment.end
//                   : CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 16.w,
//                     vertical: 12.h,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: message.isUser
//                           ? [
//                               AppColors.secondaryTextColor,
//                               AppColors.primaryColor,
//                             ]
//                           : [
//                               Colors.white.withOpacity(0.45),
//                               Colors.white.withOpacity(0.04),
//                             ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(20.r),
//                       topRight: Radius.circular(20.r),
//                       bottomLeft: message.isUser
//                           ? Radius.circular(4.r)
//                           : Radius.circular(20.r),
//                       bottomRight: message.isUser
//                           ? Radius.circular(20.r)
//                           : Radius.circular(4.r),
//                     ),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.15),
//                       width: 1.w,
//                     ),
//                   ),
//                   child: AppText(
//                     title: message.text,
//                     fontSize: 16,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 4.h),
//                 AppText(
//                   title: time,
//                   fontSize: 12,
//                   color: Colors.white.withOpacity(0.5),
//                 ),

//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Typing Dot Animation
// class _TypingDot extends StatefulWidget {
//   final int delay;
//   const _TypingDot({required this.delay});

//   @override
//   State<_TypingDot> createState() => _TypingDotState();
// }

// class _TypingDotState extends State<_TypingDot>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..repeat(reverse: true);

//     Future.delayed(Duration(milliseconds: widget.delay), () {
//       if (mounted) _controller.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _controller,
//       child: Container(
//         width: 6.w,
//         height: 6.h,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }

// // Chat Message Model
// class ChatMessage {
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;

//   ChatMessage({
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//   });
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/constants.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/utils/network_utils/secure_config_service.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:daad_app/features/contact/widgets.dart';
import 'package:daad_app/features/dashboard/services/chatbot_persona_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});
  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _isLoading = true;
  bool _isFirstTimeUser = true;
  bool _hasIntroduced = false;

  List<Map<String, dynamic>> _servicesData = [];
  bool _servicesLoaded = false;

  ChatBotPersona? _persona;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      _persona = await ChatBotPersonaService.getPersona();
      print('✅ Loaded chatbot persona: ${_persona?.botName}');
    } catch (e) {
      print('❌ Error loading persona: $e');
    }
    await _loadServicesData();
    await _cleanupOldMessages();
    await _loadMessages();
    await _checkAndSendWelcomeMessage();
  }

  Future<void> _loadServicesData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('services')
          .orderBy('order')
          .get();

      setState(() {
        _servicesData = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'desc': data['desc'] ?? '',
            'category': data['category'] ?? '',
            'priceTiers': data['priceTiers'] ?? [],
            'images': data['images'] ?? [],
          };
        }).toList();
        _servicesLoaded = true;
      });

      print('✅ Loaded ${_servicesData.length} services for chatbot');
    } catch (e) {
      print('❌ Error loading services: $e');
      setState(() => _servicesLoaded = true);
    }
  }

  Future<void> _cleanupOldMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 3));
      final cutoffTs = Timestamp.fromDate(cutoff);

      final oldSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .where('timestamp', isLessThan: cutoffTs)
          .get();

      if (oldSnap.docs.isEmpty) {
        print('✅ No old messages to cleanup');
        return;
      }
      print('🗑️ Cleaning up ${oldSnap.docs.length} old messages...');

      const batchSize = 450;
      for (var i = 0; i < oldSnap.docs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (i + batchSize < oldSnap.docs.length)
            ? i + batchSize
            : oldSnap.docs.length;

        for (var j = i; j < end; j++) {
          batch.delete(oldSnap.docs[j].reference);
        }

        await batch.commit();
      }

      print('✅ Cleaned up old messages successfully');
    } catch (e) {
      print('❌ Error cleaning up old messages: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _messages.clear();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          _messages.add(
            ChatMessage(
              text: data['text'] ?? '',
              isUser: data['isUser'] ?? false,
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ??
                  (data['clientTimestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            ),
          );
        }

        _isFirstTimeUser = _messages.isEmpty;
        _hasIntroduced = _messages.any((m) => !m.isUser);

        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      print(
        _isFirstTimeUser
            ? '👋 First time user detected'
            : '🔄 Returning user detected (${_messages.length} messages)',
      );
    } catch (e) {
      print('❌ Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndSendWelcomeMessage() async {
    if (_isLoading) return;

    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      final hoursSinceLastMessage = DateTime.now()
          .difference(lastMessage.timestamp)
          .inHours;

      if (hoursSinceLastMessage < 1) {
        print(
          '⏭️ Skipping welcome (last message was ${hoursSinceLastMessage}h ago)',
        );
        return;
      }
    }

    setState(() => _isTyping = true);

    try {
      String welcomeMessage;

      if (_isFirstTimeUser) {
        welcomeMessage = await _getAIWelcomeMessage(isFirstTime: true);
      } else {
        welcomeMessage = await _getAIWelcomeMessage(isFirstTime: false);
      }

      final botMessage = ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
        _hasIntroduced = true;
      });

      await _saveMessage(welcomeMessage, false);
      _scrollToBottom();
    } catch (e) {
      print('❌ Error sending welcome message: $e');
      setState(() => _isTyping = false);
    }
  }

  Future<String> _getAIWelcomeMessage({required bool isFirstTime}) async {
    final apiKey = SecureConfigService.llamaApiKey;
    final model = SecureConfigService.chatModel;

    // Check if persona has custom welcome message
    if (_persona != null) {
      final customWelcome = _persona!.getFinalWelcome(isFirstTime);

      // If custom welcome is direct text (not a prompt), use it
      if (!customWelcome.contains('أنت') && customWelcome.length < 500) {
        return customWelcome;
      }
    }

    // Build prompt from persona or use default
    final prompt = isFirstTime
        ? _persona?.getFinalWelcome(true) ??
              '''عرّف بنفسك كمساعد ضاد في جملتين فقط.'''
        : _persona?.getFinalWelcome(false) ??
              '''رحب بالمستخدم العائد في جملة واحدة.''';

    final requestBody = {
      "model": model,
      "messages": [
        {"role": "user", "content": prompt},
      ],
      "temperature": 0.9,
      "max_tokens": 100, // Reduced from 150
    };

    try {
      final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data["choices"]?[0]?["message"]?["content"];

        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      } else if (response.statusCode == 429) {
        print('⏳ Rate limit on welcome message, using fallback');
        // Use fallback immediately for welcome messages
      } else {
        print('❌ Welcome API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting AI welcome: $e');
    }

    // Fallback welcome messages
    return isFirstTime
        ? 'مرحباً! أنا ${_persona?.botName ?? "مساعد ضاد"}، مستشارك للتسويق. كيف يمكنني مساعدتك؟'
        : 'أهلاً بعودتك! كيف يمكنني مساعدتك؟';
  }

  Future<void> _saveMessage(String text, bool isUser) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .add({
            'text': text,
            'isUser': isUser,
            'timestamp': FieldValue.serverTimestamp(),
            'clientTimestamp': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      print('❌ Error saving message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isTyping = true;
    });

    await _saveMessage(text, true);
    _scrollToBottom();

    try {
      final response = await _sendToGroqAPI(text);

      final botMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
        _hasIntroduced = true;
      });
      await _saveMessage(response, false);
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isTyping = false;
      });

      await _saveMessage(errorMessage.text, false);
    }
  }
  // String _buildCompactServicesContext() {
  //   if (_servicesData.isEmpty) {
  //     return "لا توجد خدمات حالياً.";
  //   }

  //   final servicesText = StringBuffer();
  //   servicesText.writeln("الخدمات المتاحة:");

  //   for (var service in _servicesData) {
  //     servicesText.write("▪️ ${service['title']}");

  //     // Add price if available
  //     if (service['priceTiers'] != null && service['priceTiers'].isNotEmpty) {
  //       final firstTier = service['priceTiers'][0];
  //       final price = firstTier['price'] ?? 0;
  //       if (price > 0) {
  //         servicesText.write(" (${price} ريال)");
  //       }
  //     }
  //     servicesText.writeln();
  //   }

  //   return servicesText.toString();
  // }

  String _buildCompactSystemPrompt() {
    // Use persona system prompt if available
    String basePrompt =
        _persona?.getFinalSystemPrompt() ??
        '''أنت "${_persona?.botName ?? 'مساعد ضاد'}" - مستشار تسويق.
- ردود قصيرة جداً (2-3 جمل فقط)
- مباشر ومختصر
- لا تكرر التعريف''';

    // Only add services if user might ask about them
    // Don't add by default to save tokens

    // Add introduction status
    String introStatus = _hasIntroduced
        ? "\nملاحظة: لا تعيد التعريف."
        : "\nملاحظة: عرّف بنفسك بجملة واحدة.";

    return '$basePrompt$introStatus';
  }

  Future<String> _sendToGroqAPI(String message, {int retryCount = 0}) async {
    final apiKey = SecureConfigService.llamaApiKey;
    final model = SecureConfigService.chatModel;
    const maxRetries = 2;

    if (!_servicesLoaded) {
      await _loadServicesData();
    }

    // Build compact system prompt
    String systemPrompt = _buildCompactSystemPrompt();

    // Reduce history even more to save tokens (4 messages = 2 exchanges)
    const memoryLimit = 4;
    final recentMessages = _messages.length > memoryLimit
        ? _messages.sublist(_messages.length - memoryLimit)
        : _messages;

    // Build conversation history
    List<Map<String, String>> conversationHistory = [
      {"role": "system", "content": systemPrompt},
    ];

    for (var msg in recentMessages) {
      conversationHistory.add({
        "role": msg.isUser ? "user" : "assistant",
        "content": msg.text,
      });
    }

    conversationHistory.add({"role": "user", "content": message});

    final requestBody = {
      "model": model,
      "messages": conversationHistory,
      "temperature": _persona?.temperature ?? 0.7,
      "max_tokens": _persona?.maxTokens ?? 500, // Reduced from 800
      "top_p": 0.9,
    };

    try {
      final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data["choices"]?[0]?["message"]?["content"];

        if (content != null && content.isNotEmpty) {
          return content.trim();
        } else {
          return "لم أتمكن من فهم الرد. هل يمكنك إعادة صياغة السؤال؟";
        }
      } else if (response.statusCode == 429) {
        // Rate limit error
        final data = json.decode(response.body);
        final errorMessage = data["error"]?["message"] ?? "";

        // Extract wait time from error message (e.g., "Please try again in 3.51s")
        final waitTimeMatch = RegExp(
          r'try again in ([\d.]+)s',
        ).firstMatch(errorMessage);
        double waitSeconds = 4.0; // Default wait time

        if (waitTimeMatch != null) {
          waitSeconds = double.tryParse(waitTimeMatch.group(1) ?? '4') ?? 4.0;
          waitSeconds += 0.5; // Add buffer
        }

        print(
          '⏳ Rate limit hit. Waiting ${waitSeconds.toStringAsFixed(1)}s before retry...',
        );

        // Retry if we haven't exceeded max retries
        if (retryCount < maxRetries) {
          await Future.delayed(
            Duration(milliseconds: (waitSeconds * 1000).toInt()),
          );
          print(
            '🔄 Retrying request (attempt ${retryCount + 2}/${maxRetries + 1})...',
          );
          return await _sendToGroqAPI(message, retryCount: retryCount + 1);
        } else {
          return "عذراً، الخدمة مزدحمة حالياً. يرجى الانتظار قليلاً والمحاولة مرة أخرى.";
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return "عذراً، الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.";
      }
    } catch (e) {
      print("❌ Error: $e");
      if (e.toString().contains('timeout')) {
        return "عذراً، استغرق الرد وقتاً طويلاً. يرجى المحاولة مرة أخرى.";
      }
      return "عذراً، حدث خطأ في الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.";
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'اليوم';
    if (messageDate == yesterday) return 'أمس';

    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a', 'ar').format(time);
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    final current = _messages[index].timestamp;
    final previous = _messages[index - 1].timestamp;

    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kBackgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const GlassBackButton(),
                    AppText(
                      title: _persona?.botName ?? 'مساعد ضاد',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    SizedBox(width: 40.w),
                  ],
                ),
              ),

              // Messages Area
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _messages.isEmpty && !_isTyping
                    ? _buildEmptyChat()
                    : _buildMessagesList(),
              ),

              // Typing Indicator
              if (_isTyping) _buildTypingIndicator(),

              // Input Field
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: 4,
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.3),
                  child: CircleAvatar(
                    radius: 16.r,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.3),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/icons/chatbot.svg',
              width: 64.w,
              height: 64.h,
            ),
          ),
          SizedBox(height: 24.h),
          AppText(
            title: 'مرحباً بك في ${_persona?.botName ?? "مساعد ضاد"}',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          SizedBox(height: 8.h),
          AppText(
            title: 'جاري التحضير...',
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDateHeader = _shouldShowDateHeader(index);

        return Column(
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    title: _formatDate(message.timestamp),
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            _MessageBubble(
              message: message,
              time: _formatTime(message.timestamp),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: SvgPicture.asset(
              'assets/icons/chatbot.svg',
              width: 50.sp,
              height: 50.sp,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TypingDot(delay: 0),
                SizedBox(width: 4.h),
                const _TypingDot(delay: 200),
                SizedBox(width: 4.h),
                const _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.w),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText:
                      'اسأل ${_persona?.botName ?? "مساعد ضاد"} عن أي شيء...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 45.w,
              height: 45.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.send,
                color: AppColors.secondaryTextColor,
                size: 25.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String time;

  const _MessageBubble({required this.message, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: SvgPicture.asset(
                'assets/icons/chatbot.svg',
                width: 50.sp,
                height: 50.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: message.isUser
                          ? [
                              AppColors.secondaryTextColor,
                              AppColors.primaryColor,
                            ]
                          : [
                              Colors.white.withOpacity(0.45),
                              Colors.white.withOpacity(0.04),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                      bottomLeft: message.isUser
                          ? Radius.circular(4.r)
                          : Radius.circular(20.r),
                      bottomRight: message.isUser
                          ? Radius.circular(20.r)
                          : Radius.circular(4.r),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.w,
                    ),
                  ),
                  child: AppText(
                    title: message.text,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                AppText(
                  title: time,
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Typing Dot Animation
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6.w,
        height: 6.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
