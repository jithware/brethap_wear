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

    await tester.pump(wait);

    await tester.pumpAndSettle();
    takeScreenshot(binding, "1_home.png");

    // Running
    if (demoRunning) {
      debugPrint("Demo Running(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap start
      Finder finder = find.byType(ElevatedButton);
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump(wait);

      // running
      for (int i = 0; i < 100; i++) {
        if (i == 20) {
          takeScreenshot(binding, "2_inhale.png");
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      // tap stop
      finder = find.byType(ElevatedButton);
      expect(finder, findsOneWidget);
      await tester.tap(finder);

      await tester.pumpAndSettle();
      takeScreenshot(binding, "3_duration.png");

      // Tapping title closes snackbar
      await tester.pump(wait);
      await tester.tap(find.byKey(const Key(HomeWidget.keyTitle)));
      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "RUNNING_END=${stopwatch.elapsed}\n";
    }

    // Presets
    if (demoPresets) {
      debugPrint("Demo Presets(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap presets
      await tester.tap(find.byType(PopupMenuButton<String>));

      await tester.pumpAndSettle();
      takeScreenshot(binding, "4_preset.png");

      await tester.pump(wait);

      // drag to bottom of presets
      await tester.dragUntilVisible(find.byKey(const Key(BOX_TEXT)),
          find.byKey(const Key(DEFAULT_TEXT)), const Offset(0, -1));

      await tester.pumpAndSettle();
      takeScreenshot(binding, "5_preset.png");

      // tap default
      await tester.pump(wait);
      await tester.tap(find.byKey(const Key(DEFAULT_TEXT)));
      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "PRESETS_END=${stopwatch.elapsed}\n";
    }

    // Custom
    if (demoCustom) {
      debugPrint("Demo Custom(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap connect
      await tester.tap(find.byKey(const Key(HomeWidget.keyConnect)));

      await tester.pumpAndSettle();
      takeScreenshot(binding, "6_custom.png");

      await tester.pump(wait);

      // Tapping title closes snackbar
      await tester.tap(find.byKey(const Key(HomeWidget.keyTitle)));
      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "CUSTOM_END=${stopwatch.elapsed}\n";
    }

    //await tester.pumpAndSettle();
    //takeScreenshot(binding, "7_dark.png");

    await tester.pump(wait);
    envVars += "DEMO_END=${stopwatch.elapsed}\n";

    debugPrint("\nVariables for demo.sh script:");
    debugPrint(envVars);

    //await tester.pump(wait * 20);
  });
}
