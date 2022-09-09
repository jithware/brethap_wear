// To execute test run:
// flutter test integration_test/demo_test.dart

import 'package:brethap/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:brethap_wear/main.dart';
import 'package:brethap_wear/main.dart' as app;

// ignore_for_file: dead_code
bool demoRunning = true, demoPresets = true, demoCustom = true;

const Duration wait = Duration(milliseconds: 1000);

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('Demo', (WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle();

    Stopwatch stopwatch = Stopwatch()..start();
    String envVars = "";

    await tester.pump(wait);
    envVars += "HOME_SNAP=${stopwatch.elapsed - wait}\n";

    // Running
    if (demoRunning) {
      debugPrint("Demo Running(${stopwatch.elapsed})...");
      await tester.pump(wait);

      // tap start
      Finder finder = find.byType(ElevatedButton);
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump(wait);

      envVars += "INHALE_SNAP=${stopwatch.elapsed + wait * 2}\n";

      // running
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // tap stop
      finder = find.byType(ElevatedButton);
      expect(finder, findsOneWidget);
      await tester.tap(finder);

      await tester.pumpAndSettle();
      envVars += "DURATION_SNAP=${stopwatch.elapsed}\n";

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
      envVars += "PRESET1_SNAP=${stopwatch.elapsed}\n";

      await tester.pump(wait);

      // drag to bottom of presets
      await tester.dragUntilVisible(find.byKey(const Key(BOX_TEXT)),
          find.byKey(const Key(DEFAULT_TEXT)), const Offset(0, -1));

      await tester.pumpAndSettle();
      envVars += "PRESET2_SNAP=${stopwatch.elapsed}\n";

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

      // tap presets
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pump(wait);

      // tap custom
      await tester.tap(find.byKey(const Key(HomeWidget.phonePreference)));

      await tester.pumpAndSettle();
      envVars += "CUSTOM_SNAP=${stopwatch.elapsed}\n";

      await tester.pump(wait);

      // Tapping title closes snackbar
      await tester.tap(find.byKey(const Key(HomeWidget.keyTitle)));
      await tester.pump(wait);

      // tap phone
      await tester.tap(find.byType(IconButton).first);
      await tester.pump(wait);

      await tester.pumpAndSettle();
      envVars += "CUSTOM_END=${stopwatch.elapsed}\n";
    }

    await tester.pump(wait);
    envVars += "DEMO_END=${stopwatch.elapsed}\n";

    debugPrint("\nVariables for demo.sh script:");
    debugPrint(envVars);

    //await tester.pump(wait * 20);
  });
}
