import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daad_app/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConsultationScreen extends StatefulWidget {
  final String serviceTitle;

  const ConsultationScreen({super.key, required this.serviceTitle});

  @override
  _ConsultationScreenState createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;

  // Method to handle the consultation booking
  Future<void> _bookConsultation() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final serviceTitle = widget.serviceTitle;
    final date = _selectedDate;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText(title:'يرجى ملء جميع الحقول')),
      );
      return;
    }

    // Save the consultation details to Firestore
    await FirebaseFirestore.instance.collection('consultations').add({
      'name': name,
      'email': email,
      'phone': phone,
      'serviceTitle': serviceTitle,
      'preferredDate': date,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: AppText(title:'تم حجز الاستشارة بنجاح')),
    );

    // Optionally, navigate back to the previous screen
    Navigator.pop(context);
  }

  // Method to pick a date
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(title:'حجز استشارة - ${widget.serviceTitle}'),
      ),
      body: Padding(
        padding:   EdgeInsets.all(16.0.r),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(title:'إملأ بياناتك لحجز الاستشارة', fontSize: 18, fontWeight: FontWeight.bold),
                SizedBox(height: 16.h
),

              // Name Input Field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
                SizedBox(height: 12.h
),

              // Email Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
              ),
                SizedBox(height: 12.h
),

              // Phone Input Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
                SizedBox(height: 12.h
),

              // Date Picker
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _selectDate,
                    child: Text(_selectedDate == null
                        ? 'اختر التاريخ'
                        : 'التاريخ: ${_selectedDate!.toLocal()}'.split(' ')[0]),
                  ),
                ],
              ),
                SizedBox(height: 12.h
),

              // Book Consultation Button
              Center(
                child: ElevatedButton(
                  onPressed: _bookConsultation,
                  child: const AppText(title:'حجز الاستشارة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
