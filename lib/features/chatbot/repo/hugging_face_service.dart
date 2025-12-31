// import 'dart:async';

// import 'package:google_generative_ai/google_generative_ai.dart';

// class ChatbotService {
//   static ChatbotService? _instance;
//   GenerativeModel? _model;
//   ChatSession? _chat;
//   bool _isInitialized = false;

//   static ChatbotService get instance {
//     _instance ??= ChatbotService._();
//     return _instance!;
//   }

//   ChatbotService._();

//   // نماذج مدعومة
//   static const String _defaultModel = 'gemini'; // أو 'gemini-1.5-pro'

//   Future<bool> initialize(String apiKey) async {
//     // لا تتحقق بالمقارنة مع مفتاح ثابت، فقط تأكد إنه غير فارغ
//     if (apiKey.isEmpty || !apiKey.startsWith('AIza')) {
//       print('❌ Error: Invalid or empty API key format');
//       _isInitialized = false;
//       return false;
//     }

//     try {
//     _model = GenerativeModel(
//   model: 'gemini-base', // جرّب pro-latest إن أردت
//   apiKey: apiKey,
//   generationConfig:   GenerationConfig(
//     temperature: 0.6,
//     maxOutputTokens: 1024,
//   ),
//   systemInstruction: Content.system(
//     'أنت مساعد عربي مختص بالتجارة الإلكترونية لعملاء ضاد DAAD. التزم بالعربية وبمواضيع المتجر فقط.',
//   ),
// );


//       // اختبار سريع للمفتاح والاتصال (بدون history)
//       final test = await _model!.generateContent([Content.AppText(title:'ping')]);
//       if ((test.text ?? '').isEmpty) {
//         print('⚠️ API responded but no text');
//       }

//       _initializeChat();         // جهّز جلسة محادثة
//       _isInitialized = true;
//       print('✅ Gemini API initialized successfully with $_defaultModel');
//       return true;

//     } on GenerativeAIException catch (e) {
//       // أخطاء الـ API بـ status واضح
//       print('❌ GenerativeAIException: code=${e.message}, message=${e.message}');
//       _isInitialized = false;
//       return false;

//     } catch (e) {
//       print('❌ Unknown error initializing Gemini: $e');
//       _isInitialized = false;
//       return false;
//     }
//   }

//   void _initializeChat() {
//     _chat = _model!.startChat(history: [
//       Content.text(
//         'ابدأ كمساعد تجارة إلكترونية لعملاء ضاد. رحّب بالمستخدم باختصار واسأله كيف تساعده.',
//       ),
//     ]);
//   }

//   Future<String> sendMessage(String message) async {
//     if (!_isInitialized || _chat == null) {
//       return 'عذرًا، المساعد الذكي غير متاح حاليًا. يرجى المحاولة لاحقًا.';
//     }

//     try {
//       final response = await _chat!
//           .sendMessage(Content.text(message))
//           .timeout(const Duration(seconds: 30));

//       final text = response.text?.trim();
//       if (text == null || text.isEmpty) {
//         return 'عذرًا، لم أفهم طلبك. هل يمكنك توضيح سؤالك؟';
//       }
//       return text;

//     } on GenerativeAIException catch (e) {
//       if ((e.message ?? '').toLowerCase().contains('api key')) {
//         return 'خطأ في المفتاح البرمجي. تأكد من صحة مفتاح Gemini من Google AI Studio.';
//       }
//       if ((e.message ?? '').toLowerCase().contains('not found') ||
//           (e.message ?? '').toLowerCase().contains('model')) {
//         return 'النموذج غير مدعوم. حدّث التطبيق لاستخدام gemini-1.5-flash أو gemini-1.5-pro.';
//       }
//       if ((e.message ?? '').toLowerCase().contains('quota') ||
//           (e.message ?? '').toLowerCase().contains('limit')) {
//         return 'تم تجاوز حد الاستخدام. حاول لاحقًا.';
//       }
//       return 'حدث خطأ في الخدمة: ${e.message ?? e.toString()}';

//     } on TimeoutException {
//       return 'المهلة انتهت. تحقق من اتصالك وحاول مرة أخرى.';
//     } catch (e) {
//       return 'عذرًا، حدث خطأ غير متوقع. حاول مرة أخرى.';
//     }
//   }

//   void resetChat() {
//     if (_isInitialized && _model != null) {
//       _initializeChat();
//     }
//   }

//   bool get isInitialized => _isInitialized;
// }
