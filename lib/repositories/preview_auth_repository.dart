import '../models/user_session.dart';
import 'auth_repository.dart';

/// Preview builds only (--dart-define=PREVIEW=true): always signed in, no network.
class PreviewAuthRepository implements AuthRepository {
  static final UserSession _session = UserSession(
    username: 'preview',
    displayName: 'معاينة',
    role: 'مدير النظام',
    loginTime: DateTime(2026, 11, 24),
  );

  @override
  Future<UserSession?> getCurrentUser() async => _session;

  @override
  Future<UserSession> login(String username, String password) async => _session;

  @override
  Future<void> logout() async {}
}
