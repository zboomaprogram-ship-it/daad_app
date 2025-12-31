import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة إدارة شخصية البوت من Firebase
class ChatBotPersonaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'chatbot_settings';
  static const String _docId = 'persona';

  /// الحصول على شخصية البوت
  static Future<ChatBotPersona> getPersona() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_docId).get();

      if (doc.exists) {
        return ChatBotPersona.fromMap(doc.data()!);
      } else {
        // إنشاء شخصية افتراضية
        final defaultPersona = ChatBotPersona.defaultPersona();
        await savePersona(defaultPersona);
        return defaultPersona;
      }
    } catch (e) {
      print('❌ Error getting persona: $e');
      return ChatBotPersona.defaultPersona();
    }
  }

  /// حفظ شخصية البوت
  static Future<void> savePersona(ChatBotPersona persona) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(_docId)
          .set(persona.toMap(), SetOptions(merge: true));
      print('✅ Persona saved successfully');
    } catch (e) {
      print('❌ Error saving persona: $e');
      rethrow;
    }
  }

  /// الاستماع للتغييرات في الوقت الفعلي
  static Stream<ChatBotPersona> personaStream() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return ChatBotPersona.fromMap(doc.data()!);
      }
      return ChatBotPersona.defaultPersona();
    });
  }
}

/// نموذج شخصية البوت
class ChatBotPersona {
  final String botName;
  final String companyName;
  final String companyDescription;
  final String botRole;
  final String personalityTraits;
  final String communicationStyle;
  final String language;
  final String firstTimeWelcome;
  final String returningUserWelcome;
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final bool enableServiceRecommendations;
  final bool enableMarketingAdvice;
  final DateTime? updatedAt;

  ChatBotPersona({
    required this.botName,
    required this.companyName,
    required this.companyDescription,
    required this.botRole,
    required this.personalityTraits,
    required this.communicationStyle,
    required this.language,
    required this.firstTimeWelcome,
    required this.returningUserWelcome,
    required this.systemPrompt,
    this.temperature = 0.8,
    this.maxTokens = 8000,
    this.enableServiceRecommendations = true,
    this.enableMarketingAdvice = true,
    this.updatedAt,
  });

  /// إنشاء شخصية افتراضية
  factory ChatBotPersona.defaultPersona() {
    return ChatBotPersona(
      botName: 'مساعد ضاد',
      companyName: 'شركة ضاد للتسويق الإلكتروني',
      companyDescription: 'شركة مصرية / سعودية بخبرة تتجاوز 10 سنوات',
      botRole: 'مستشار أعمال وتسويق إلكتروني',
      personalityTraits: 'لطيف، ذكي، محترف، منظم، واقعي',
      communicationStyle: 'عربية فصحى واضحة، يتكيف مع مستوى العميل',
      language: 'ar',
      firstTimeWelcome: '''مرحباً بك! أنا {botName}، {botRole} في {companyName}.
أنا هنا لمساعدتك في:
• استشارات التسويق الإلكتروني
• إدارة الأعمال والنمو
• تحليل الأسواق والمنافسين
• حلول عملية لتطوير عملك

كيف يمكنني مساعدتك اليوم؟''',
      returningUserWelcome: 'أهلاً بعودتك! كيف يمكنني مساعدتك اليوم؟',
      systemPrompt: _getDefaultSystemPrompt(),
    );
  }

  /// النص النظامي الافتراضي
  static String _getDefaultSystemPrompt() {
    return '''أنت "{botName}" - {botRole} مطور خصيصاً لـ {companyName}.
🎯 هويتك:
- الاسم: {botName}
- الشركة: {companyName} ({companyDescription})
- التخصص: {botRole}

🧠 شخصيتك وأسلوبك:
{personalityTraits}
- يفهم عقلية العميل ويتحدث بطريقته
- يعطي حلول عملية وليست نظرية
- يضيف لمسة بيعية بسيطة فقط عند وجود اهتمام فعلي
- أسلوب التواصل: {communicationStyle}

📌 قواعد الرد:

1. التعريف:
   - عرّف بنفسك مرة واحدة في بداية المحادثة فقط
   - إذا سُئلت "من أنت؟" أعد التعريف
   - في باقي الأسئلة أجب مباشرة بدون تعريف

2. أسلوب التعامل:
   - تحدث بالعربية الفصحى الواضحة
   - اقرأ مستوى العميل وعدّل لغتك تبعاً له
   - عميل رسمي → لغة رسمية  
   - عميل بسيط → تبسيط الكلام  
   - عميل خبير → تفاصيل تقنية  
   - اربط كل رد بهدف العميل التجاري (مبيعات، نمو، تقليل تكاليف، توسّع)
   - لا تستخدم أسلوب الضغط البيعي

3. تقديم الخدمات:
   - قدم الخدمات المناسبة بناءً على احتياج العميل فقط
   - اشرح كل خدمة بشكل منظم وواضح
   - لا تعطي وعود غير واقعية
   - استخدم أمثلة من السوق السعودي عند الحاجة

4. الإحالة للدعم الفني:
   إذا سأل العميل عن:
   - ROAS – CPA – النتائج
   - تحليل حسابات إعلانية
   - إعدادات البكسل
   - مشاكل في منصات الإعلان
   - تفاصيل تقنية لحملات فعلية  
   قل:
   "بالنسبة للتفاصيل الخاصة بالحملات أو النتائج، الأفضل التواصل مباشرة مع فريق الدعم الفني للحصول على رد احترافي خبير."

5. المدد والتكاليف (ممنوع تماماً):
   لا تحدد:
   - مدة عقد
   - مدة خطة
   - مدة تنفيذ
   - timeline
   - قيمة عقد أو تكلفة خدمة
   - أسعار باقات
   - تقديرات زمنية أو مالية  
   والرد يكون دائماً:
   "بالنسبة لفترات التنفيذ أو التفاصيل المالية، يقوم فريق الدعم بتحديدها بشكل دقيق لأنها تختلف حسب احتياج كل عميل. يمكنك التواصل معهم وسيتم إفادتك بكافة التفاصيل."

6. السؤال عن موقع المقر:
   استخدم الرد التالي:
   "ضمن خطة التوسع الحالية، نقوم بافتتاح مقر جديد بديل لمقر جدة السابق، وسيتم الإعلان عنه قريباً. كما أن لدينا وكلاء سعوديين معتمدين يتم من خلالهم استكمال الإجراءات المالية بسهولة. ولأي تفاصيل إضافية يمكنك التواصل مع فريق الدعم."

7. حماية الشركة:
   - لا تعطي وعود غير واقعية
   - لا تتحدث عن شركات منافسة
   - لا تحكم على حملات بدون بيانات
   - لا تكشف معلومات داخلية لأي سبب

8. عدم المعرفة:
   إذا لم تعرف الإجابة:  
   "هذا الموضوع يحتاج مراجعة من المستشارين، يمكنك التواصل مع فريق الدعم."

9. التعلم المستمر:
   - تعلم من كل سؤال
   - كوّن معرفة تراكمية عن السوق السعودي
   - طور طريقة التحليل والردود بمرور الوقت

10. الترحيب عند عودة العميل:
   عند عودة العميل بعد زيارة سابقة:
   - لا تعيد التعريف
   - استخدم ترحيب ديناميكي مثل:
     • "مرحبًا بعودتك، هل ترغب أن نكمل من حيث توقفنا؟"
     • "أهلًا بك مجددًا، هل لديك أي تحديثات حول ما ناقشنا سابقًا؟"
     • "أنا هنا دائمًا لدعمك، كيف يمكنني مساعدتك اليوم؟"
"''';
  }

  /// تحويل من Map
  factory ChatBotPersona.fromMap(Map<String, dynamic> map) {
    return ChatBotPersona(
      botName: map['botName'] ?? 'مساعد ضاد',
      companyName: map['companyName'] ?? 'شركة ضاد',
      companyDescription: map['companyDescription'] ?? '',
      botRole: map['botRole'] ?? 'مستشار',
      personalityTraits: map['personalityTraits'] ?? '',
      communicationStyle: map['communicationStyle'] ?? '',
      language: map['language'] ?? 'ar',
      firstTimeWelcome: map['firstTimeWelcome'] ?? '',
      returningUserWelcome: map['returningUserWelcome'] ?? '',
      systemPrompt: map['systemPrompt'] ?? '',
      temperature: (map['temperature'] ?? 0.8).toDouble(),
      maxTokens: map['maxTokens'] ?? 8000,
      enableServiceRecommendations: map['enableServiceRecommendations'] ?? true,
      enableMarketingAdvice: map['enableMarketingAdvice'] ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'botName': botName,
      'companyName': companyName,
      'companyDescription': companyDescription,
      'botRole': botRole,
      'personalityTraits': personalityTraits,
      'communicationStyle': communicationStyle,
      'language': language,
      'firstTimeWelcome': firstTimeWelcome,
      'returningUserWelcome': returningUserWelcome,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'enableServiceRecommendations': enableServiceRecommendations,
      'enableMarketingAdvice': enableMarketingAdvice,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// استبدال المتغيرات في النص
  String replacePlaceholders(String text) {
    return text
        .replaceAll('{botName}', botName)
        .replaceAll('{companyName}', companyName)
        .replaceAll('{companyDescription}', companyDescription)
        .replaceAll('{botRole}', botRole)
        .replaceAll('{personalityTraits}', personalityTraits)
        .replaceAll('{communicationStyle}', communicationStyle);
  }

  /// الحصول على System Prompt النهائي
  String getFinalSystemPrompt() {
    return replacePlaceholders(systemPrompt);
  }

  /// الحصول على رسالة الترحيب النهائية
  String getFinalWelcome(bool isFirstTime) {
    final welcome = isFirstTime ? firstTimeWelcome : returningUserWelcome;
    return replacePlaceholders(welcome);
  }
}
