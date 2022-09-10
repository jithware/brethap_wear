// ignore_for_file: avoid_print

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  try {
    await Process.run(
      'adb',
      [
        'shell',
        'cmd uimode night no',
      ],
    );
    await integrationDriver(
      onScreenshot: (String name, List<int> bytes) async {
        final File image =
            await File('screenshots/android/$name').create(recursive: true);
        image.writeAsBytesSync(bytes);
        return true;
      },
    );
  } catch (e) {
    print('Error: $e');
  }
}
