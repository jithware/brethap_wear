// To execute demo run:
// flutter test integration_test/demo_test.dart
// To execute demo with screenshots saved run:
// flutter drive --no-pub --driver=integration_test/driver.dart --target=integration_test/demo_test.dart
// To execute demo script run:
// ../brethap/screenshots/demo.sh emulator-5554

import 'package:brethap/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:brethap_wear/main.dart';
import 'package:brethap_wear/main.dart' as app;
import 'screenshot.dart';

// ignore_for_file: dead_code
bool demoRunning = true, demoPresets = true, demoCustom = true;

const Duration wait = Duration(milliseconds: 1000);

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('Demo', (WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle();

    Stopwatch stopwatch = Stopwatch()..start();
    String envVars = "";
    int snapshot = 1;

    await tester.pump(wait);

    await tester.pumpAndSettle();
    takeScreenshot(binding, "${snapshot++}_home.png");

    // Running
    if (demoRunning) {
      debugPrint("Demo Running(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap start
      Finder finder = find.byKey(const Key(HomeWidget.keyStart));
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump(wait);

      // running
      for (int i = 0; i < 100; i++) {
        if (i == 20) {
          takeScreenshot(binding, "${snapshot++}_inhale.png");
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      // tap stop
      finder = find.byKey(const Key(HomeWidget.keyStart));
      expect(finder, findsOneWidget);
      await tester.tap(finder);

      await tester.pumpAndSettle();
      takeScreenshot(binding, "${snapshot++}_duration.png");

      await tester.pump(wait);

      // drag to close snackbar
      finder = find.byKey(const Key(HomeWidget.keyDrag));
      expect(finder, findsOneWidget);
      await tester.drag(finder, const Offset(0, 100));
      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "RUNNING_END=${stopwatch.elapsed - wait}\n";
    }

    // Presets
    if (demoPresets) {
      debugPrint("Demo Presets(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap presets
      await tester.tap(find.byType(PopupMenuButton<String>));

      await tester.pumpAndSettle();
      takeScreenshot(binding, "${snapshot++}_preset.png");

      await tester.pump(wait);

      // drag to bottom of presets
      await tester.dragUntilVisible(find.byKey(const Key(BOX_TEXT)),
          find.byKey(const Key(DEFAULT_TEXT)), const Offset(0, -1));

      await tester.pumpAndSettle();
      takeScreenshot(binding, "${snapshot++}_preset.png");

      // tap default
      await tester.pump(wait);
      await tester.tap(find.byKey(const Key(DEFAULT_TEXT)));
      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "PRESETS_END=${stopwatch.elapsed - wait}\n";
    }

    // Custom
    if (demoCustom) {
      debugPrint("Demo Custom(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap presets
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // tap phone preference
      await tester.pump(wait);
      await tester.tap(find.byKey(const Key(HomeWidget.phonePreference)));
      await tester.pumpAndSettle();

      // wait for snackbar to close
      await tester.pump(wait * 3);
      await tester.pumpAndSettle();

      // tap connect
      await tester.tap(find.byKey(const Key(HomeWidget.keyConnect)));
      await tester.pump(wait);

      await tester.pumpAndSettle();
      takeScreenshot(binding, "${snapshot++}_custom.png");

      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "CUSTOM_END=${stopwatch.elapsed - wait}\n";
    }

    await tester.pump(wait);
    envVars += "DEMO_END=${stopwatch.elapsed}\n";

    debugPrint("\nVariables for demo.sh script:");
    debugPrint(envVars);

    //await tester.pump(wait * 20);
  });
}
