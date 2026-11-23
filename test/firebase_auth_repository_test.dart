import 'package:flutter_test/flutter_test.dart';
import 'package:blood_donor_oasis/repositories/firebase_auth_repository.dart';

void main() {
  test('plain usernames map to the hidden email domain', () {
    expect(FirebaseAuthRepository.usernameToEmail(' Admin '),
        'admin@blooddonor.app');
    expect(FirebaseAuthRepository.usernameToEmail('a@b.com'), 'a@b.com');
    expect(FirebaseAuthRepository.emailToUsername('admin@blooddonor.app'),
        'admin');
  });

  test('error codes give Arabic messages and never reveal which part failed',
      () {
    expect(FirebaseAuthRepository.messageForCode('user-not-found'),
        FirebaseAuthRepository.messageForCode('wrong-password'));
    expect(FirebaseAuthRepository.messageForCode('user-disabled'),
        contains('إيقاف'));
  });
}
