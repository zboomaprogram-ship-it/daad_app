import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
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
      const SnackBar(content: Text('تم حجز الاستشارة بنجاح')),
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
        title: Text('حجز استشارة - ${widget.serviceTitle}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إملأ بياناتك لحجز الاستشارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Name Input Field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Email Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Phone Input Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

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
              const SizedBox(height: 12),

              // Book Consultation Button
              Center(
                child: ElevatedButton(
                  onPressed: _bookConsultation,
                  child: const Text('حجز الاستشارة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
