import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/donor_files_repository.dart';
import 'repositories/preview_auth_repository.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'repositories/donor_repository.dart';
import 'repositories/campaign_repository.dart';
import 'repositories/donation_repository.dart';
import 'repositories/auth_repository.dart';
import 'providers/donor_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/donation_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'views/shell/main_scaffold.dart';
import 'views/auth/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  // Initialize data repositories
  final donorRepository = await LocalDonorRepository.create();
  final campaignRepository = await LocalCampaignRepository.create();
  final donationRepository = await LocalDonationRepository.create();
  // Preview builds (--dart-define=PREVIEW=true) skip login and save nothing.
  const preview = bool.fromEnvironment('PREVIEW');
  final AuthRepository authRepository =
      preview ? PreviewAuthRepository() : FirebaseAuthRepository();
  final DonorFilesRepository donorFilesRepository = preview
      ? InMemoryDonorFilesRepository()
      : FirestoreDonorFilesRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DonorProvider(donorRepository)),
        ChangeNotifierProvider(create: (_) => CampaignProvider(campaignRepository)),
        ChangeNotifierProvider(create: (_) => DonationProvider(donationRepository)),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        Provider<DonorFilesRepository>.value(value: donorFilesRepository),
      ],
      child: const BloodDonorApp(),
    ),
  );
}

class BloodDonorApp extends StatelessWidget {
  const BloodDonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.orgName} | ${AppConstants.appTitle}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginView();
          }
          return const MainScaffold();
        },
      ),
    );
  }
}
