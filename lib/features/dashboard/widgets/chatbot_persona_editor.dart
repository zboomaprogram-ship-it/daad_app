import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/utils/app_colors/app_colors.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatBotPersonaEditor extends StatefulWidget {
  const ChatBotPersonaEditor({super.key});

  @override
  State<ChatBotPersonaEditor> createState() => _ChatBotPersonaEditorState();
}

class _ChatBotPersonaEditorState extends State<ChatBotPersonaEditor> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _botNameCtrl;
  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyDescCtrl;
  late TextEditingController _botRoleCtrl;
  late TextEditingController _personalityCtrl;
  late TextEditingController _communicationCtrl;
  late TextEditingController _firstWelcomeCtrl;
  late TextEditingController _returningWelcomeCtrl;
  late TextEditingController _systemPromptCtrl;
  late TextEditingController _temperatureCtrl;
  late TextEditingController _maxTokensCtrl;

  bool _enableServiceRec = true;
  bool _enableMarketingAdvice = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadPersona();
  }

  void _initControllers() {
    _botNameCtrl = TextEditingController();
    _companyNameCtrl = TextEditingController();
    _companyDescCtrl = TextEditingController();
    _botRoleCtrl = TextEditingController();
    _personalityCtrl = TextEditingController();
    _communicationCtrl = TextEditingController();
    _firstWelcomeCtrl = TextEditingController();
    _returningWelcomeCtrl = TextEditingController();
    _systemPromptCtrl = TextEditingController();
    _temperatureCtrl = TextEditingController(text: '0.8');
    _maxTokensCtrl = TextEditingController(text: '8000');
  }

  @override
  void dispose() {
    _botNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyDescCtrl.dispose();
    _botRoleCtrl.dispose();
    _personalityCtrl.dispose();
    _communicationCtrl.dispose();
    _firstWelcomeCtrl.dispose();
    _returningWelcomeCtrl.dispose();
    _systemPromptCtrl.dispose();
    _temperatureCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPersona() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chatbot_settings')
          .doc('persona')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _botNameCtrl.text = data['botName'] ?? 'مساعد ضاد';
          _companyNameCtrl.text = data['companyName'] ?? 'شركة ضاد';
          _companyDescCtrl.text = data['companyDescription'] ?? '';
          _botRoleCtrl.text = data['botRole'] ?? 'مستشار';
          _personalityCtrl.text = data['personalityTraits'] ?? '';
          _communicationCtrl.text = data['communicationStyle'] ?? '';
          _firstWelcomeCtrl.text = data['firstTimeWelcome'] ?? '';
          _returningWelcomeCtrl.text = data['returningUserWelcome'] ?? '';
          _systemPromptCtrl.text = data['systemPrompt'] ?? '';
          _temperatureCtrl.text = (data['temperature'] ?? 0.8).toString();
          _maxTokensCtrl.text = (data['maxTokens'] ?? 8000).toString();
          _enableServiceRec = data['enableServiceRecommendations'] ?? true;
          _enableMarketingAdvice = data['enableMarketingAdvice'] ?? true;
          _isLoading = false;
        });
      } else {
        // إنشاء إعدادات افتراضية
        await _createDefaultPersona();
      }
    } catch (e) {
      print('❌ Error loading persona: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultPersona() async {
    final defaultData = {
      'botName': 'مساعد ضاد',
      'companyName': 'شركة ضاد للتسويق الإلكتروني',
      'companyDescription': 'شركة مصرية / سعودية بخبرة تتجاوز 10 سنوات',
      'botRole': 'مستشار أعمال وتسويق إلكتروني',
      'personalityTraits': 'لطيف، ذكي، محترف، منظم، واقعي',
      'communicationStyle': 'عربية فصحى واضحة، يتكيف مع مستوى العميل',
      'firstTimeWelcome':
          '''مرحباً بك! أنا {botName}، {botRole} في {companyName}.

أنا هنا لمساعدتك في:
• استشارات التسويق الإلكتروني
• إدارة الأعمال والنمو
• تحليل الأسواق والمنافسين
• حلول عملية لتطوير عملك

كيف يمكنني مساعدتك اليوم؟''',
      'returningUserWelcome': 'أهلاً بعودتك! كيف يمكنني مساعدتك اليوم؟',
      'systemPrompt': _getDefaultSystemPrompt(),
      'temperature': 0.8,
      'maxTokens': 8000,
      'enableServiceRecommendations': true,
      'enableMarketingAdvice': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('chatbot_settings')
        .doc('persona')
        .set(defaultData);

    setState(() {
      _botNameCtrl.text = defaultData['botName'] as String;
      _companyNameCtrl.text = defaultData['companyName'] as String;
      _companyDescCtrl.text = defaultData['companyDescription'] as String;
      _botRoleCtrl.text = defaultData['botRole'] as String;
      _personalityCtrl.text = defaultData['personalityTraits'] as String;
      _communicationCtrl.text = defaultData['communicationStyle'] as String;
      _firstWelcomeCtrl.text = defaultData['firstTimeWelcome'] as String;
      _returningWelcomeCtrl.text =
          defaultData['returningUserWelcome'] as String;
      _systemPromptCtrl.text = defaultData['systemPrompt'] as String;
      _isLoading = false;
    });
  }

  String _getDefaultSystemPrompt() {
    return '''أنت "{botName}" - {botRole} مطوّر خصيصًا لـ{companyName}.

🎯 هويتك:
- الاسم: {botName}
- الشركة: {companyName} ({companyDescription})
- التخصص: إدارة الأعمال، التسويق الإلكتروني

🧠 شخصيتك: {personalityTraits}
📱 أسلوبك: {communicationStyle}

📌 قواعد الرد:
1. لا تعيد التعريف بنفسك
2. اقرأ مستوى العميل
3. قدم حلول عملية
4. كن صادقاً ولا تبالغ''';
  }

  Future<void> _savePersona() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'botName': _botNameCtrl.text.trim(),
        'companyName': _companyNameCtrl.text.trim(),
        'companyDescription': _companyDescCtrl.text.trim(),
        'botRole': _botRoleCtrl.text.trim(),
        'personalityTraits': _personalityCtrl.text.trim(),
        'communicationStyle': _communicationCtrl.text.trim(),
        'firstTimeWelcome': _firstWelcomeCtrl.text.trim(),
        'returningUserWelcome': _returningWelcomeCtrl.text.trim(),
        'systemPrompt': _systemPromptCtrl.text.trim(),
        'temperature': double.tryParse(_temperatureCtrl.text) ?? 0.8,
        'maxTokens': int.tryParse(_maxTokensCtrl.text) ?? 8000,
        'enableServiceRecommendations': _enableServiceRec,
        'enableMarketingAdvice': _enableMarketingAdvice,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('chatbot_settings')
          .doc('persona')
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(title: '✅ تم حفظ إعدادات البوت بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(title: '❌ خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppText(title: 'إعدادات شخصية البوت'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, color: AppColors.textColor),
            onPressed: _isSaving ? null : _savePersona,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            // معلومات أساسية
            _buildSectionTitle('المعلومات الأساسية'),
            _buildTextField(
              controller: _botNameCtrl,
              label: 'اسم البوت',
              hint: 'مساعد ضاد',
            ),
            _buildTextField(
              controller: _companyNameCtrl,
              label: 'اسم الشركة',
              hint: 'شركة ضاد',
            ),
            _buildTextField(
              controller: _companyDescCtrl,
              label: 'وصف الشركة',
              hint: 'شركة مصرية / سعودية',
              maxLines: 2,
            ),
            _buildTextField(
              controller: _botRoleCtrl,
              label: 'دور البوت',
              hint: 'مستشار أعمال',
            ),

            SizedBox(height: 24.h),

            // الشخصية والأسلوب
            _buildSectionTitle('الشخصية والأسلوب'),
            _buildTextField(
              controller: _personalityCtrl,
              label: 'الصفات الشخصية',
              hint: 'لطيف، ذكي، محترف',
              maxLines: 3,
            ),
            _buildTextField(
              controller: _communicationCtrl,
              label: 'أسلوب التواصل',
              hint: 'عربية فصحى واضحة',
              maxLines: 3,
            ),

            SizedBox(height: 24.h),

            // رسائل الترحيب
            _buildSectionTitle('رسائل الترحيب'),
            // const Text(
            //   'يمكنك استخدام المتغيرات: {botName}, {companyName}, {botRole}',
            //   style: TextStyle(fontSize: 12, color: Colors.grey),
            // ),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _firstWelcomeCtrl,
              label: 'رسالة الترحيب للمستخدمين الجدد',
              maxLines: 6,
            ),
            _buildTextField(
              controller: _returningWelcomeCtrl,
              label: 'رسالة الترحيب للمستخدمين العائدين',
              maxLines: 3,
            ),

            SizedBox(height: 24.h),

            // System Prompt
            _buildSectionTitle('التعليمات النظامية (System Prompt)'),
            _buildTextField(
              controller: _systemPromptCtrl,
              label: 'System Prompt',
              maxLines: 15,
            ),

            SizedBox(height: 24.h),

            // إعدادات متقدمة
            _buildSectionTitle('إعدادات متقدمة'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _temperatureCtrl,
                    label: 'Temperature',
                    hint: '0.8',
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextField(
                    controller: _maxTokensCtrl,
                    label: 'Max Tokens',
                    hint: '8000',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            SwitchListTile(
              title: const Text('تفعيل توصيات الخدمات'),
              value: _enableServiceRec,
              onChanged: (v) => setState(() => _enableServiceRec = v),
            ),
            SwitchListTile(
              title: const Text('تفعيل النصائح التسويقية'),
              value: _enableMarketingAdvice,
              onChanged: (v) => setState(() => _enableMarketingAdvice = v),
            ),

            SizedBox(height: 32.h),

            // زر الحفظ
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePersona,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: AppText(
                title: _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
      child: AppText(title: title, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textColor,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textColor),
          hintText: hint,
          border: const OutlineInputBorder(),
          hintStyle: const TextStyle(color: AppColors.textColor),
        ),

        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
      ),
    );
  }
}
