import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_donor_oasis/core/theme/app_theme.dart';
import 'package:blood_donor_oasis/providers/auth_provider.dart';
import 'package:blood_donor_oasis/repositories/auth_repository.dart';
import 'package:blood_donor_oasis/views/auth/login_view.dart';

Future<AuthProvider> loadLogin(
  WidgetTester tester,
  Size size, {
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint(details.toString());
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
  SharedPreferences.setMockInitialValues({});
  final auth = AuthProvider(await LocalAuthRepository.create());
  await auth.checkCurrentUser();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const LoginView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  for (final width in [320.0, 390.0, 768.0, 849.0, 850.0, 1024.0, 1440.0]) {
    testWidgets('Login fits width $width', (tester) async {
      await loadLogin(tester, Size(width, 844));
      expect(tester.takeException(), isNull);
      expect(find.text('أهلاً بعودتك'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        Directionality.of(tester.element(find.byType(Form))),
        TextDirection.rtl,
      );
    });
  }

  testWidgets('Login fits enlarged text and short keyboard viewport', (
    tester,
  ) async {
    await loadLogin(tester, const Size(390, 420), scale: 1.6);
    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Empty fields validate, password toggles, and Enter submits through existing provider',
    (tester) async {
      final auth = await loadLogin(tester, const Size(390, 844));
      await auth.logout();
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('login-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('يرجى إدخال اسم المستخدم'), findsOneWidget);
      expect(find.text('يرجى إدخال كلمة المرور'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
      final username = find.byKey(const ValueKey('login-username'));
      final password = find.byKey(const ValueKey('login-password'));
      await tester.enterText(username, '2026');
      await tester.enterText(password, '100100');
      expect(tester.widget<TextFormField>(password).controller?.text, '100100');
      await tester.tap(find.byTooltip('إظهار كلمة المرور'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('إخفاء كلمة المرور'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user.username, '2026');
      expect(tester.takeException(), isNull);
    },
  );
}
