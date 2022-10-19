import 'package:brethap/constants.dart';
import 'package:brethap/hive_storage.dart';
import 'package:brethap/wear.dart';
import 'package:brethap_wear/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration wait = Duration(seconds: 1);

Future<void> testHomeWidget(WidgetTester tester) async {
  Preference preference = Preference.getDefaultPref();
  Duration duration = Duration(seconds: preference.duration),
      totalTime = const Duration(),
      inhale =
          Duration(milliseconds: preference.inhale[0] + preference.inhale[1]),
      exhale =
          Duration(milliseconds: preference.exhale[0] + preference.exhale[1]);

  // Verify app name in title bar
  expect(find.text(HomeWidget.appName), findsOneWidget);

  // Verify button text
  expect(find.text("Start"), findsOneWidget);

  // Verify initial timer text
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  // Press start button
  await tester.tap(find.byType(ElevatedButton));

  // Wait a bit
  await tester.pump(wait);
  totalTime += wait;

  // Verify button text
  expect(find.text("Stop"), findsOneWidget);

  // Verify timer
  expect(find.text(getDurationString(duration - totalTime)), findsOneWidget);

  // Forward ahead to exhale
  await tester.pump(inhale);
  totalTime += inhale;

  // Verify timer
  expect(find.text(getDurationString(duration - totalTime)), findsOneWidget);

  // Wait a bit
  await tester.pump(wait);
  totalTime += wait;

  // Forward ahead to inhale
  await tester.pump(exhale);
  totalTime += exhale;

  // Press stop button
  await tester.tap(find.byType(ElevatedButton));

  // Wait a bit
  await tester.pump(wait);
  totalTime += wait;

  // Verify reset timer text
  expect(find.text(getDurationString(duration)), findsOneWidget);

  // Verify session
  await tester.pump(wait);
  totalTime += wait;
  expect(find.byType(SnackBar), findsOneWidget);

  // Tapping title closes snackbar
  await tester.tap(find.byKey(const Key(HomeWidget.keyTitle)));
  await tester.pump(wait);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();

  // Tap preset
  preference = Preference.get478Pref();
  Finder finder = find.byKey(const Key(PRESET_478_TEXT));
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();

  // Tap preset
  preference = Preference.getBoxPref();
  finder = find.byKey(const Key(BOX_TEXT));
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();

  // Tap preset
  preference = Preference.getPhysSighPref();
  finder = find.byKey(const Key(PHYS_SIGH_TEXT));
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();

  // Tap preset
  preference = Preference.getDefaultPref();
  finder = find.byKey(const Key(DEFAULT_TEXT));
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  await tester.pump(wait);
}

Future<void> main() async {
  setUpAll((() async {}));

  tearDownAll((() async {}));

  testWidgets('HomeWidget', (WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: HomeWidget(title: MainWidget.title)));

    await testHomeWidget(tester);

    await tester.pump();
  });
}
