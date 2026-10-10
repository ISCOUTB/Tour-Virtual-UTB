# UTB Tour Virtual (Flutter)

Aplicación móvil del recorrido virtual inmersivo de la Universidad Tecnológica
de Bolívar.

La guía principal está en
[docs/GUIA_DESARROLLO.md](../../docs/GUIA_DESARROLLO.md). Este archivo conserva
los comandos rápidos para trabajar desde `apps/mobile`.

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

- Supabase/Postgres es el backend operativo actual; la migración a
  Firebase/Firestore está acordada, pero aún no comenzó.
- Los medios institucionales no están versionados. Deben solicitarse por el
  canal autorizado y colocarse en las rutas indicadas en la guía.
- No uses `service_role` en la aplicación móvil.
