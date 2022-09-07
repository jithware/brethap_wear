import 'package:brethap/constants.dart';
import 'package:brethap/hive_storage.dart';
import 'package:brethap/wear.dart';
import 'package:brethap_wear/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration wait = Duration(seconds: 2);

Future<void> testHomeWidget(WidgetTester tester) async {
  const Duration shortWait = Duration(milliseconds: 500);
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

  // Press stop button
  await tester.tap(find.byType(ElevatedButton));

  // Wait a bit
  await tester.pump(shortWait);
  totalTime += shortWait;

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
  await tester.pump(shortWait);
  totalTime += shortWait;

  // Forward ahead to inhale
  await tester.pump(exhale);
  totalTime += exhale;

  // Press stop button
  await tester.tap(find.byType(ElevatedButton));

  // Wait a bit
  await tester.pump(shortWait);
  totalTime += shortWait;

  // Verify reset timer text
  expect(find.text(getDurationString(duration)), findsOneWidget);

  // Verify session
  await tester.pump(shortWait);
  totalTime += shortWait;
  expect(find.byType(SnackBar), findsOneWidget);

  await tester.pump(wait);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pump(shortWait);

  // Tap preset
  preference = Preference.get478Pref();
  await tester.ensureVisible(find.text(PRESET_478_TEXT, skipOffstage: false));
  await tester.tap(find.text(PRESET_478_TEXT));
  await tester.pump(shortWait);
  expect(
      find.text(
        getDurationString(Duration(seconds: preference.duration)),
      ),
      findsOneWidget);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pump(shortWait);

  // Tap preset
  preference = Preference.getBoxPref();
  await tester.ensureVisible(find.text(BOX_TEXT));
  await tester.tap(find.text(BOX_TEXT));
  await tester.pump(shortWait);
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pump(shortWait);

  // Tap preset
  preference = Preference.getPhysSighPref();
  await tester.ensureVisible(find.text(PHYS_SIGH_TEXT));
  await tester.tap(find.text(PHYS_SIGH_TEXT));
  await tester.pump(shortWait);
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  // Tap presets
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pump(shortWait);

  // Tap preset
  preference = Preference.getDefaultPref();
  await tester.ensureVisible(find.text(DEFAULT_TEXT));
  await tester.tap(find.text(DEFAULT_TEXT));
  await tester.pump(shortWait);
  expect(find.text(getDurationString(Duration(seconds: preference.duration))),
      findsOneWidget);

  await tester.pumpAndSettle();
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
