import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دالة تسجيل الدخول
  static Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user should be logged out (token revoked)
      if (userCredential.user != null) {
        final shouldLogout = await _checkIfShouldLogout(userCredential.user!.uid);
        if (shouldLogout) {
          await signOut();
          return null;
        }
      }
      
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
      return userCredential.user;
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }

  // دالة تسجيل الخروج (من جميع الأجهزة)
  static Future<void> signOut({bool logoutAllDevices = true}) async {
    try {
      final user = _auth.currentUser;
      
      if (user != null && logoutAllDevices) {
        // Set logout timestamp in Firestore to invalidate all sessions
        await _firestore.collection('users').doc(user.uid).set({
          'forceLogoutAt': FieldValue.serverTimestamp(),
          'lastLogoutReason': 'manual_logout',
        }, SetOptions(merge: true));
      }
      
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // دالة تغيير كلمة المرور (تسجيل خروج من جميع الأجهزة تلقائياً)
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
      
      // Force logout on all devices
      await _firestore.collection('users').doc(user.uid).set({
        'forceLogoutAt': FieldValue.serverTimestamp(),
        'lastLogoutReason': 'password_changed',
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print("Error changing password: $e");
      return false;
    }
  }

  // دالة التحقق من حالة المستخدم الحالي
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
  // دالة للتحقق مما إذا كان يجب تسجيل خروج المستخدم
  static Future<bool> _checkIfShouldLogout(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) return false;
      
      final data = userDoc.data();
      if (data == null) return false;
      
      final forceLogoutAt = data['forceLogoutAt'] as Timestamp?;
      if (forceLogoutAt == null) return false;
      
      // Get current user's last sign in time
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final metadata = currentUser.metadata;
      final lastSignInTime = metadata.lastSignInTime;
      
      if (lastSignInTime == null) return false;
      
      // If force logout timestamp is after last sign in, force logout
      return forceLogoutAt.toDate().isAfter(lastSignInTime);
    } catch (e) {
      print("Error checking logout status: $e");
      return false;
    }
  }

  // دالة للتحقق الدوري من حالة تسجيل الخروج (استدعها في الصفحة الرئيسية)
  static Stream<bool> watchForceLogout() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data == null) return false;
      
      final forceLogoutAt = data['forceLogoutAt'] as Timestamp?;
      if (forceLogoutAt == null) return false;
      
      final metadata = user.metadata;
      final lastSignInTime = metadata.lastSignInTime;
      
      if (lastSignInTime == null) return false;
      
      return forceLogoutAt.toDate().isAfter(lastSignInTime);
    });
  }

  // إرسال بريد التحقق
  static Future<bool> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print("Error sending verification email: $e");
      return false;
    }
  }

  // إعادة تحميل المستخدم للتحقق من حالة التحقق
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // التحقق من حالة البريد الإلكتروني
  static bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // إرسال بريد إعادة تعيين كلمة المرور
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Error sending password reset email: $e");
      return false;
    }
  }

  // إعادة تعيين كلمة المرور باستخدام الكود
  static Future<bool> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return true;
    } catch (e) {
      print("Error confirming password reset: $e");
      return false;
    }
  }

  // التحقق من صحة كود إعادة التعيين
  static Future<String?> verifyPasswordResetCode(String code) async {
    try {
      String email = await _auth.verifyPasswordResetCode(code);
      return email;
    } catch (e) {
      print("Error verifying password reset code: $e");
      return null;
    }
  }
}