# UTB Virtual Placeholder (Flutter)

Proyecto placeholder para el nuevo módulo de recorrido inmersivo de UTB Virtual.

## Qué incluye

- Pantalla de mapa aéreo (mock) con 5 puntos clave del MVP.
- Vista tipo streetview like (simulada) con botones flotantes.
- Detalle de POI con secciones de imágenes, video y audio (placeholder).

## Requisitos en Windows

- Flutter SDK estable.
- Visual Studio Build Tools con **Desktop development with C++**.
- Windows SDK (10 u 11).
- VS Code con extensiones Flutter y Dart.

## Verificación de entorno

```bash
flutter doctor -v
```

Debe aparecer en verde:
- Flutter
- Visual Studio (C++)
- Windows desktop device

## Ejecutar el proyecto

```bash
cd apps/mobile
flutter pub get
flutter run -d windows
```

## Probar como teléfono desde PC (emulador Android)

1. Inicia emulador:

```bash
flutter emulators --launch UTB_Pixel_API_35
```

2. Ejecuta en Android:

```bash
flutter run -d emulator-5554
```

## Generar APK (debug)

```bash
flutter build apk --debug
```

APK generado en:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Instalar APK manualmente en emulador:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Notas

- Este proyecto es base funcional para demo interna.
- El siguiente paso es reemplazar mocks por:
	- mapa real (`flutter_map` o Mapbox),
	- escenas 360 reales,
	- backend de contenido (Firebase/Supabase).
