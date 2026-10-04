import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:utb_tour/datos/progreso.dart';

/// El progreso se lee del disco de forma asincrona y el conjunto arranca
/// vacio. Esa ventana causaba que el cierre del recorrido saliera habiendo
/// visitado un solo lugar: el primer toque veia el conjunto vacio, se contaba
/// como primera visita, y al cerrar la ficha la carga ya habia traido los
/// lugares de sesiones anteriores.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cargado espera a que el progreso guardado este en memoria', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.poisVisitados': ['1', '2', '5'],
    });
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    // Antes de esperar, lo unico garantizado es el conjunto vacio: por eso
    // quien decide si un lugar es nuevo tiene que esperar primero.
    expect(contenedor.read(progresoProvider), isEmpty);

    await contenedor.read(progresoProvider.notifier).cargado;

    expect(contenedor.read(progresoProvider), {1, 2, 5});
  });

  test('una visita marcada antes de la carga no se pierde', () async {
    // La carga hacia `state = ids`, que pisaba lo marcado mientras tanto.
    // Ahora es union.
    SharedPreferences.setMockInitialValues({
      'flutter.poisVisitados': ['1', '2'],
    });
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    final progreso = contenedor.read(progresoProvider.notifier);
    progreso.marcarVisitado(9);
    await progreso.cargado;

    expect(contenedor.read(progresoProvider), {1, 2, 9});
  });

  test('una visita se persiste aunque el almacen no estuviera listo', () async {
    // `_guardar` se saltaba la escritura si las preferencias aun no habian
    // abierto, y las visitas de los primeros segundos se perdian en silencio.
    SharedPreferences.setMockInitialValues({});
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    final progreso = contenedor.read(progresoProvider.notifier);
    progreso.marcarVisitado(7);
    await progreso.cargado;
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('poisVisitados'), ['7']);
  });

  test('marcar dos veces el mismo lugar solo cuenta la primera', () {
    SharedPreferences.setMockInitialValues({});
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    final progreso = contenedor.read(progresoProvider.notifier);
    expect(progreso.marcarVisitado(3), isTrue);
    expect(progreso.marcarVisitado(3), isFalse);
  });
}
