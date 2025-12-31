class ValidatorUtils {
  static String? name(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return 'name cannot be empty';
    }
    if (displayName.length < 3 || displayName.length > 20) {
      return 'name must be between 3 and 20 characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value!.isEmpty) {
      return 'Please enter an email';
    }
    if (!RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    ).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value!.isEmpty) {
      return 'Please enter an phone';
    }
    if (value.isEmpty) {
      return 'Phone number is required';
    } else if (value.length != 11) {
      return 'Phone number must be exactly 11 digits long';
    }
    return null;
  }
  static String? password(String? value) {
    if (value!.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static String? nationalId(String? value) {
    if (value!.isEmpty) {
      return 'Please enter a  nationalId';
    }
    if (value.length != 14) {
      return 'nationalId must be at least 14 characters long';
    }
    return null;
  }

  static String? repeatPassword({String? value, String? password}) {
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? gender({String? value}) {
    if (value!.isEmpty) {
      return 'please enter gender';
    }
    return null;
  }

  static String? image(String? image) {
    if (image == null || image.isEmpty) {
      return 'Image cannot be empty';
    }
    return null;
  }

  static String? token(String? val) {
    if (val == null || val.isEmpty) {
      return 'token cannot be empty';
    }
    return null;
  }

  static String? standered(String? val) {
    if (val == null || val.isEmpty) {
      return 'missing field';
    }
    return null;
  }
}
class KsaPhone {
  // تحويل الأرقام العربية-الهندية إلى لاتينية
  static String _toWesternDigits(String input) {
    const map = {
      '٠':'0','١':'1','٢':'2','٣':'3','٤':'4',
      '٥':'5','٦':'6','٧':'7','٨':'8','٩':'9'
    };
    return input.split('').map((c) => map[c] ?? c).join();
  }

  /// يُرجع E.164 (+9665XXXXXXXX) أو null إن لم يكن صالحًا
  static String? normalizeToE164(String raw) {
    if (raw.trim().isEmpty) return null;

    // تنظيف: أرقام عربية -> لاتينية + إزالة المسافات/الشرطات/الأقواس
    var s = _toWesternDigits(raw).replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // إزالة بادئات البلد المحتملة
    if (s.startsWith('+')) s = s.substring(1);     // +9665...
    if (s.startsWith('00966')) {
      s = s.substring(5);                           // 009665...
    } else if (s.startsWith('966')) {
      s = s.substring(3);                           // 9665...
    }

    // إزالة الصفر الأول المحلي
    if (s.startsWith('0')) s = s.substring(1);      // 05XXXXXXXX -> 5XXXXXXXX

    // يجب أن تكون الآن 9 أرقام وتبدأ بـ 5
    // تحقق أكثر صرامة لبدايات شركات KSA الشائعة: 50, 53, 54, 55, 56, 57, 58, 59
    final ksaMobile = RegExp(r'^5(0|3|4|5|6|7|8|9)\d{7}$');
    if (!ksaMobile.hasMatch(s)) return null;

    return '+966$s';
  }

  /// Validator لواجهة المستخدم
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'من فضلك أدخل رقم الجوال';
    }
    final e164 = normalizeToE164(value);
    if (e164 == null) {
      return 'رقم جوال سعودي غير صالح. استخدم 05XXXXXXXX أو +9665XXXXXXXX';
    }
    return null;
  }
}


