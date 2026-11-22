import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final carpeta = Directory('../../.impeccable/review')
    ..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (nombre, bytes, [argumentos]) async {
      await File('${carpeta.path}/$nombre.png').writeAsBytes(bytes);
      return bytes.length > 1000;
    },
  );
}
