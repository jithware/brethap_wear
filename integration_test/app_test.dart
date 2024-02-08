// To execute integration test run:
// flutter drive -d emulator-5554 --no-pub --driver=integration_test/driver.dart --target=integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:brethap_wear/main.dart' as app;
import '../test/home_widget_test.dart';

const Duration wait = Duration(milliseconds: 500);

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration test', (WidgetTester tester) async {
    app.main();

    await tester.pump(wait);

    await testHomeWidget(tester);

    await tester.pump(wait);
  });
}
