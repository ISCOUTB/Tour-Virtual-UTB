# UTB Tour Virtual

Recorrido virtual inmersivo del campus de la Universidad Tecnológica de Bolívar.
Consta de una aplicación móvil para visitantes, estudiantes y docentes, y un
panel web de administración.

## Documentación

| Documento | Contenido |
|---|---|
| [docs/GUIA_DESARROLLO.md](docs/GUIA_DESARROLLO.md) | Instalación, ejecución, pruebas, arquitectura, publicación y coordinación del equipo |
| [docs/utb-tour-inmersivo-mvp.md](docs/utb-tour-inmersivo-mvp.md) | Alcance del producto, POIs, KPIs y flujo de usuario |
| [docs/arquitectura.md](docs/arquitectura.md) | Decisiones técnicas, modelo de datos, autenticación, seguridad y plan por fases |

## Estructura

```
apps/mobile/          Flutter — aplicación de usuarios
apps/admin/           Next.js — panel de administración (Fase 3)
services/api/         .NET 9 Minimal API (fuera del repositorio por ahora)
packages/contracts/   Contrato OpenAPI, fuente de verdad de la interfaz
supabase/migrations/  Esquema y políticas RLS
docs/
```

## Requisitos

- Flutter SDK estable y Dart 3.11 o superior.
- En Windows, Visual Studio Build Tools con *Desktop development with C++* para
  compilar el objetivo de escritorio.
- Node 22 o superior para validar el contrato OpenAPI.

Verificación del entorno:

```bash
flutter doctor -v
```

## Comandos

Todos los comandos de la app móvil se ejecutan desde `apps/mobile`:

```bash
cd apps/mobile
flutter pub get
flutter run -d windows            # escritorio
flutter run -d emulator-5554      # emulador Android
flutter analyze --fatal-infos     # análisis estático, igual que en CI
dart format .                     # formato, igual que en CI
flutter test                      # pruebas
flutter build apk --debug
```

Validación del contrato de API, desde la raíz:

```bash
npx --yes @redocly/cli@latest lint packages/contracts/openapi.yaml
```

## Notas de desarrollo

La API .NET corre en HTTP local durante el desarrollo. El manifest principal de
Android declara `usesCleartextTraffic="false"`, de modo que las compilaciones de
release exigen HTTPS; la excepción para el host de desarrollo vive únicamente en
la configuración de red de debug, en
`apps/mobile/android/app/src/debug/res/xml/network_security_config.xml`.

Desde el emulador de Android, `localhost` es el propio emulador. El equipo
anfitrión es `10.0.2.2`.

Los medios institucionales y los documentos fuente no se publican con el
código. Consulta la [guía de desarrollo](docs/GUIA_DESARROLLO.md) para preparar
los insumos locales, ejecutar Supabase, probar la app y revisar qué archivos se
pueden subir.
