import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_session.dart';
import 'auth_repository.dart';

/// Signs users in with Firebase Authentication (email and password).
///
/// Users type a plain username. It is mapped to a hidden email
/// (`<username>@blooddonor.app`). Typing a full email also works.
/// There is no sign-up: accounts are created and disabled by the owner in
/// the Firebase console.
class FirebaseAuthRepository implements AuthRepository {
  static const String emailDomain = 'blooddonor.app';

  final FirebaseAuth _auth;

  FirebaseAuthRepository([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  static String usernameToEmail(String username) {
    final value = username.trim().toLowerCase();
    return value.contains('@') ? value : '$value@$emailDomain';
  }

  static String emailToUsername(String email) {
    final suffix = '@$emailDomain';
    return email.endsWith(suffix)
        ? email.substring(0, email.length - suffix.length)
        : email;
  }

  UserSession _toSession(User user) => UserSession(
        username: emailToUsername(user.email ?? ''),
        displayName: (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : 'إدارة جمعية كفالة اليتيم',
        role: 'مدير النظام',
        isAuthenticated: true,
        loginTime: user.metadata.lastSignInTime ?? DateTime.now(),
      );

  @override
  Future<UserSession?> getCurrentUser() async {
    // The first event restores any saved session from the browser.
    final user = await _auth.authStateChanges().first;
    return user == null ? null : _toSession(user);
  }

  @override
  Future<UserSession> login(String username, String password) async {
    if (username.trim().isEmpty) throw 'يرجى إدخال اسم المستخدم';
    if (password.trim().isEmpty) throw 'يرجى إدخال كلمة المرور';
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: usernameToEmail(username),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw 'تعذر تسجيل الدخول';
      return _toSession(user);
    } on FirebaseAuthException catch (e) {
      throw messageForCode(e.code);
    }
  }

  static String messageForCode(String code) {
    switch (code) {
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب. تواصل مع الإدارة.';
      case 'too-many-requests':
        return 'محاولات كثيرة. حاول مرة أخرى لاحقاً.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت. حاول مرة أخرى.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
      default:
        return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    }
  }

  @override
  Future<void> logout() => _auth.signOut();
}
