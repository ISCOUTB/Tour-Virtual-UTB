import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_virtual/ui/comunes/ilustracion_max.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Una imagen que falta no rompe la compilación: Max saldría en blanco.
  test('cada pose de Max y su parpadeo están en el paquete', () async {
    for (final pose in PoseMax.values) {
      final rutas = [pose.ruta, if (pose.parpadea) pose.rutaOjos];
      for (final ruta in rutas) {
        final datos = await rootBundle.load('packages/tour_virtual/$ruta');
        expect(datos.lengthInBytes, greaterThan(0), reason: ruta);
      }
    }
  });

  test('las poses que van en pantallas parpadean', () {
    for (final pose in [
      PoseMax.saludo,
      PoseMax.senalando,
      PoseMax.celebrando,
      PoseMax.pensativo,
      PoseMax.apenado,
      PoseMax.mapa,
    ]) {
      expect(pose.parpadea, isTrue, reason: pose.name);
    }
  });
}
