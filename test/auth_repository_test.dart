import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_donor_oasis/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Fresh visits and old permissive sessions require login', () async {
    SharedPreferences.setMockInitialValues({});
    var repo = await LocalAuthRepository.create();
    expect(await repo.getCurrentUser(), isNull);
    SharedPreferences.setMockInitialValues({
      'blood_auth_session_v1': jsonEncode({
        'username': 'admin',
        'displayName': 'old',
        'role': 'admin',
        'isAuthenticated': true,
      }),
      'blood_donors_v1': 'untouched donor data',
    });
    repo = await LocalAuthRepository.create();
    expect(await repo.getCurrentUser(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('blood_donors_v1'),
      'untouched donor data',
    );
  });

  test(
    'Only the requested demo pair is accepted; session persists until logout',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await LocalAuthRepository.create();
      for (final pair in [
        ['admin', '123456'],
        ['2026', 'wrong'],
        ['wrong', '100100'],
        ['', '100100'],
        ['2026', ''],
        ['2026 ', '100100'],
        ['2026', '100100 '],
      ]) {
        await expectLater(repo.login(pair[0], pair[1]), throwsA(isA<String>()));
        expect(await repo.getCurrentUser(), isNull);
      }
      final session = await repo.login('2026', '100100');
      expect(session.isAuthenticated, isTrue);
      expect((await repo.getCurrentUser())?.username, '2026');
      await repo.logout();
      expect(await repo.getCurrentUser(), isNull);
    },
  );

  test('Corrupt or mismatched stored session is ignored', () async {
    for (final value in [
      'not-json',
      jsonEncode({
        'username': 'admin',
        'displayName': '',
        'role': '',
        'isAuthenticated': true,
      }),
    ]) {
      SharedPreferences.setMockInitialValues({'blood_auth_session_v2': value});
      final repo = await LocalAuthRepository.create();
      expect(await repo.getCurrentUser(), isNull);
    }
  });
}
