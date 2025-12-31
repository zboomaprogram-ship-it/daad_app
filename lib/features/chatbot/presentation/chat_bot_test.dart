import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
// 'AIzaSyDAswcXa-xrVZ3kG6Wts0fxVya8t1oHI7k'
// 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
// "'gemini-2.5-flash-lite'"
import 'package:http/http.dart' as http;

// 🧪 صفحة اختبار API مباشرة
class QuickGeminiTest extends StatefulWidget {
  const QuickGeminiTest({super.key});

  @override
  State<QuickGeminiTest> createState() => _QuickGeminiTestState();
}

class _QuickGeminiTestState extends State<QuickGeminiTest> {
  String _result = 'اضغط على "اختبار" للبدء...';
  bool _isLoading = false;
  final TextEditingController _apiKeyController = TextEditingController();

  Future<void> _testAPI() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _result = '⚠️ يرجى إدخال API Key';
      });
      return;
    }
    //AIzaSyBbLTvCc0j5IcZNlihdLVGt_iDZsdNzU7Q

    setState(() {
      _isLoading = true;
      _result = '🔄 جاري الاختبار...\n';
    });

    try {
      // ✅ استخدام gemini-1.5-flash بدلاً من gemini-pro
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'قل مرحبا بالعربية'},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 100},
      };

      print('🌐 Sending request...');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];

          setState(() {
            _result =
                '✅ نجح الاختبار!\n\n'
                '📝 الرد من Gemini:\n$text\n\n'
                '🎉 API Key يعمل بشكل صحيح!\n'
                'يمكنك الآن استخدام المساعد الذكي.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _result = '⚠️ استجابة غير متوقعة:\n${json.encode(data)}';
            _isLoading = false;
          });
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _result =
              '❌ خطأ من API:\n'
              'Status: ${response.statusCode}\n'
              'Error: ${errorData['error']['message']}\n\n'
              'الحلول الممكنة:\n'
              '1. تأكد من صحة API Key\n'
              '2. فعّل Generative Language API في Console\n'
              '3. تحقق من حد الاستخدام اليومي';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result =
            '❌ خطأ في الاتصال:\n$e\n\n'
            'تأكد من:\n'
            '1. الاتصال بالإنترنت\n'
            '2. صحة API Key\n'
            '3. عدم وجود Firewall';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText(title: 'اختبار Gemini API')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔑 أدخل API Key:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () {
                    // Paste functionality would go here
                  },
                ),
              ),
            ),
            SizedBox(height: 8.h),
            const Text(
              'احصل على مفتاح من:\nhttps://makersuite.google.com/app/apikey',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAPI,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16.r)),
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(strokeWidth: 2.w),
                    )
                  : const AppText(title: '🧪 اختبار API', fontSize: 16),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              constraints: BoxConstraints(minHeight: 200.h),
              child: SelectableText(
                _result,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
            SizedBox(height: 16.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 ملاحظات مهمة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '• يستخدم gemini-1.5-flash (أسرع وأحدث)\n'
                      '• يعمل مع v1beta API\n'
                      '• مجاني 100%\n'
                      '• 15 طلب/دقيقة، 1500 طلب/يوم (مجاني)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
