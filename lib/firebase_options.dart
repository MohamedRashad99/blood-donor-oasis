import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase web configuration. These values identify the project and are
/// public by design; access is controlled by Firebase Authentication.
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBeQoAt9NaFvu0yM8_R5WBKKfjVI9bIuT0',
    appId: '1:258508807196:web:be1e85613516aaa99453d9',
    messagingSenderId: '258508807196',
    projectId: 'blood-donor-oasis',
    authDomain: 'blood-donor-oasis.firebaseapp.com',
    storageBucket: 'blood-donor-oasis.firebasestorage.app',
    measurementId: 'G-G5P21ZH4JR',
  );
}
