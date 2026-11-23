import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:blood_donor_oasis/main.dart' as app;
import 'package:blood_donor_oasis/repositories/donor_repository.dart';
import 'package:blood_donor_oasis/repositories/campaign_repository.dart';
import 'package:blood_donor_oasis/repositories/donation_repository.dart';
import 'package:blood_donor_oasis/repositories/auth_repository.dart';
import 'package:blood_donor_oasis/providers/donor_provider.dart';
import 'package:blood_donor_oasis/providers/campaign_provider.dart';
import 'package:blood_donor_oasis/providers/donation_provider.dart';
import 'package:blood_donor_oasis/providers/auth_provider.dart';
import 'package:blood_donor_oasis/providers/navigation_provider.dart';
import 'package:blood_donor_oasis/views/shell/main_scaffold.dart';

Future<void> loadApp(WidgetTester tester) async {
  final widget = await tester.runAsync(() async {
    final donor = DonorProvider(await LocalDonorRepository.create());
    final campaign = CampaignProvider(await LocalCampaignRepository.create());
    final donation = DonationProvider(await LocalDonationRepository.create());
    final auth = AuthProvider(await LocalAuthRepository.create());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: donor),
        ChangeNotifierProvider.value(value: campaign),
        ChangeNotifierProvider.value(value: donation),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const app.BloodDonorApp(),
    );
  });
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [
    320.0,
    360.0,
    390.0,
    430.0,
    768.0,
    820.0,
    1024.0,
    1440.0,
  ]) {
    testWidgets(
      'Dashboard fits a $width px viewport and keeps navigation usable',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        await loadApp(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('لوحة متابعة وإحصائيات بنك الدم'), findsOneWidget);
        expect(find.text('إضافة متبرع'), findsOneWidget);
        expect(find.text('توزيع المتبرعين حسب فصيلة الدم'), findsOneWidget);
        if (width < 1024) {
          final menu = find.byTooltip('القائمة الرئيسية');
          expect(menu, findsOneWidget);
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(find.byType(Drawer), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
