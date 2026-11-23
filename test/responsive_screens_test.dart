import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_donor_oasis/providers/navigation_provider.dart';
import 'package:blood_donor_oasis/views/shell/main_scaffold.dart';
import 'package:blood_donor_oasis/views/donors/donor_form_dialog.dart';
import 'package:blood_donor_oasis/views/campaigns/campaign_form_dialog.dart';
import 'responsive_dashboard_test.dart' show loadApp;

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0, 768.0, 820.0, 1024.0]) {
    for (var screen = 0; screen < 10; screen++) {
      testWidgets('Screen $screen fits $width px', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        FlutterError.resetErrorCount();
        final originalHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          originalHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalHandler);
        SharedPreferences.setMockInitialValues({});
        await loadApp(tester);
        final context = tester.element(find.byType(MainScaffold));
        if (screen < 8) {
          context.read<NavigationProvider>().setIndex(screen);
        } else {
          showDialog<void>(context: context, builder: (_) => screen == 8
            ? const DonorFormDialog() : const CampaignFormDialog());
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
