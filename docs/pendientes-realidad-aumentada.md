# Realidad aumentada: pendiente de terminar

Estado al 19 de noviembre de 2026: **trabajo en desarrollo; falta terminarlo**.
Esta rama conserva el avance para retomarlo. El alcance y los criterios de
aceptación están en [el plan de realidad aumentada](plan-realidad-aumentada.md).

## Avance guardado

- Navegación a pie desde «Cómo llegar», con cálculo de rutas, seguimiento,
  recálculo y guía por voz.
- Vista del plano y flecha sobre la cámara, usando GPS y brújula.
- Permisos de ubicación y cámara, traducciones y pruebas de navegación.
- Grafo peatonal inicial y herramienta para medir accesos, rumbos y recorridos.

## Para terminarlo

- Revisar la implementación contra las fases 0 a 3 y los criterios del plan.
- Hacer el levantamiento en el campus: comprobar entradas, senderos, escaleras,
  rampas y tramos techados. Los accesos del grafo siguen sin verificar.
- Medir la precisión del GPS y la brújula, calibrar los rumbos y validar la
  llegada, los giros y el recálculo caminando las cinco paradas.
- Probar en teléfonos reales los permisos, la cámara, la voz, la pérdida de
  señal y el regreso a la app. Completar la revisión de accesibilidad.

Para abrir la herramienta de levantamiento, desde `apps/mobile`:

```sh
flutter run --dart-define=LEVANTAMIENTO=true
```

## Comprobación de este avance

Desde `apps/mobile`, pasaron las 43 pruebas de:

```sh
flutter test --no-pub test/navegacion_test.dart test/navegacion_pantalla_test.dart test/textos_test.dart
```

La comprobación de este guardado se limita a esas pruebas; no incluye una
validación en el campus ni en un dispositivo físico.
