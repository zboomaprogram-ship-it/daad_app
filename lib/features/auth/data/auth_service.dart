import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // دالة تسجيل الدخول
  static Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // دالة التسجيل
  static Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // بعد التسجيل، يمكن إضافة معلومات إضافية للمستخدم إلى Firestore
      return userCredential.user;
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }

  // دالة تسجيل الخروج
  static Future<void> signOut() async {
    await _auth.signOut();
  }
   // دالة التحقق من المستخدم الحالي
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
