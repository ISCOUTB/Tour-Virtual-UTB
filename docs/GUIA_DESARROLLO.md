# Guía de desarrollo y entrega

Esta guía describe el estado publicable de **UTB Tour Virtual**, cómo ejecutar
la aplicación, cómo probarla y cómo continuar el trabajo sin subir credenciales
ni material institucional sin autorización.

## 1. Estado actual

El repositorio contiene la aplicación móvil Flutter, la base de datos local de
Supabase y una API ASP.NET Core inicial importada bajo `services/api/`. La API
todavía no está conectada al móvil y el panel web aún no existe.

Ya está implementado:

- Mapa ilustrado del campus con POI posicionados mediante `map_x` y `map_y`.
- Navegación por las pantallas de inicio, mapa, recorrido 360 y ficha de POI.
- Modelos tipados con Freezed y JSON Serializable.
- Proveedores Riverpod y un único repositorio para las lecturas de contenido.
- Sesión anónima para visitantes y lectura filtrada por RLS.
- Escenas, hotspots, galerías y reproducción de audio.
- Rutas profundas para abrir un lugar y, opcionalmente, una escena concreta.
- Migraciones SQL, pruebas de modelos y pruebas de widget.
- CI para formato, análisis, pruebas, generación de código y APK de debug.
- API inicial para lugares, escenas y hotspots, importada desde la rama
  `backend`.

### Decisión importante de arquitectura

La implementación que existe hoy usa **Supabase/Postgres**. El SRS v3.1
posterior propone migrar a Node.js/Firebase/Firestore y cambiar el mapa por
Google Maps, Mapbox u OSM. Esa migración está acordada, pero todavía no está
implementada. No se debe cambiar el móvil a medias: mientras no exista una
decisión de migración ejecutada, Supabase y sus políticas RLS son la fuente
operativa actual.

## 2. Qué se publica y qué se mantiene fuera

### Sí se publica

- Código Dart, pruebas y archivos generados (`*.g.dart`, `*.freezed.dart`).
- Migraciones SQL y configuración no secreta.
- Contrato OpenAPI.
- Workflows de GitHub Actions.
- Documentación técnica redactada para el equipo.
- Iconos y assets genéricos que ya estén versionados.

### No se publica

- `assets/` y el mapa institucional local.
- Panoramas, audios, videos y otros medios reales.
- PDFs, DOCX y XLSX institucionales de trabajo.
- `docs/contenido-estaciones.md`, mientras no se confirme que su contenido
  puede hacerse público.
- `CLAUDE.md`, archivos `.env`, claves privadas, keystores y configuraciones
  locales.
- `.dart_tool/`, `build/`, `.gradle/`, `local.properties` y demás artefactos
  generados.

Las exclusiones están reforzadas en los `.gitignore`. Antes de cada commit se
debe revisar `git status --short` y comprobar que no aparece ningún medio o
credencial.

## 3. Requisitos de desarrollo

- Flutter estable con Dart 3.11 o superior.
- Visual Studio Build Tools en Windows, con **Desktop development with C++**.
- Windows SDK.
- VS Code con las extensiones Dart y Flutter.
- Docker Desktop y Supabase CLI si se quiere ejecutar la base local.
- Node.js 22 o superior para validar OpenAPI.
- `adb` solo es necesario para instalar en un emulador Android.

Comprobar Flutter:

```bash
flutter doctor -v
```

Los comandos de la aplicación se ejecutan desde `apps/mobile`, salvo que se
indique lo contrario.

## 4. Preparar una copia nueva

```bash
git clone https://github.com/ISCOUTB/Tour-Virtual-UTB.git
cd Tour-Virtual-UTB/apps/mobile
flutter pub get
```

Los medios institucionales no vienen en Git. El equipo debe entregar los
archivos por el canal autorizado y colocarlos únicamente en sus rutas locales.
El mapa usado por la aplicación debe quedar en:

```text
apps/mobile/android/app/src/assets/mapa_campus.webp
```

La carpeta de assets se declara en `pubspec.yaml`; no se debe crear una ruta
paralela para cada plataforma.

## 5. Ejecutar la aplicación

### Con Supabase local

Desde la raíz del repositorio:

```bash
supabase start
supabase db reset
```

Después de un `db reset`, el índice de Storage local también se vacía. Si se
dispone de los medios autorizados, hay que reconstruir los buckets con el
proceso interno `scripts/subir_medios.py`. Ese script no contiene credenciales
para producción y no debe recibir `service_role` en un commit.

En Windows:

```bash
cd apps/mobile
flutter run -d windows
```

En Android, el emulador ve al equipo anfitrión como `10.0.2.2`, no como
`localhost`:

```bash
flutter emulators --launch UTB_Pixel_API_35
flutter run -d emulator-5554
```

La configuración local de la aplicación usa por defecto el Supabase local.
Para apuntar a otro entorno se pasan valores en tiempo de compilación:

```bash
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://proyecto.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

La clave publicable puede estar en el cliente; `service_role` nunca puede
estar en la aplicación. La protección de los datos depende de RLS.

### Abrir una pantalla concreta

Para revisar el visor sin navegar manualmente:

```bash
flutter run -d windows --dart-define=RUTA_INICIAL=/recorrido/1
```

También se puede abrir una escena concreta:

```text
/recorrido/1?escena=12
```

## 6. Cómo está organizado el código

| Ruta | Responsabilidad |
|---|---|
| `apps/mobile/lib/main.dart` | Arranque, tema, mapa y composición principal |
| `apps/mobile/lib/recorrido_screen.dart` | Visor 360 y navegación entre escenas |
| `apps/mobile/lib/datos/modelos/` | Modelos Freezed/JSON y contrato de datos |
| `apps/mobile/lib/datos/proveedores.dart` | Providers Riverpod y arranque de Supabase |
| `apps/mobile/lib/datos/repositorio_contenido.dart` | Único punto de lectura de red |
| `apps/mobile/lib/datos/progreso.dart` | Progreso local del recorrido |
| `apps/mobile/lib/ui/` | Fichas, audio, estados async y componentes de recorrido |
| `apps/mobile/lib/nucleo/rutas.dart` | Rutas y enlaces profundos |
| `apps/mobile/lib/nucleo/configuracion.dart` | Variables `--dart-define` y defaults locales |
| `apps/mobile/lib/nucleo/errores.dart` | Errores de dominio presentables en UI |
| `supabase/migrations/` | Esquema, auth, RLS, auditoría y analítica |
| `packages/contracts/openapi.yaml` | Contrato de la API administrativa |

El repositorio se diseñó para que la futura migración de backend quede
concentrada: las pantallas consumen providers y el proveedor usa
`RepositorioContenido`; las vistas no deben hacer consultas directas a
Supabase.

## 7. Modificar o agregar funcionalidad

### Cambiar un modelo o una columna

1. Crear una nueva migración SQL numerada; no editar una migración ya aplicada.
2. Actualizar el modelo en `lib/datos/modelos/modelos.dart`.
3. Regenerar archivos:

   ```bash
   cd apps/mobile
   dart run build_runner build
   ```

4. Actualizar el repositorio, providers, UI y pruebas afectadas.
5. Revisar que el filtro de audiencia siga estando en RLS, no en Dart.

### Agregar una consulta de contenido

La consulta debe vivir en `RepositorioContenido`. Debe:

- usar el JWT del usuario actual mediante el cliente Supabase normal;
- aplicar timeout y traducir el error a `FalloApp`;
- ordenar explícitamente (`ascending: true`) cuando el orden sea funcional;
- resolver medios con rutas de Storage, sin incrustar URLs privadas;
- respetar las políticas RLS sin duplicar permisos en el cliente.

### Agregar una pantalla o ruta

1. Crear la pantalla en `lib/` o `lib/ui/` siguiendo los patrones existentes.
2. Declarar la ruta en `lib/nucleo/rutas.dart`.
3. Usar providers para datos y `VistaAsync` para loading/error/retry.
4. Añadir una prueba de widget para la navegación y los estados visibles.

### Agregar assets

Los assets institucionales deben pasar primero por el proceso de autorización,
limpieza de EXIF/GPS y revisión de privacidad. En particular, las panorámicas
con personas deben difuminar rostros antes de publicarse en Storage. No se
deben añadir al repositorio como una solución rápida.

## 8. Probar y validar

Desde `apps/mobile`:

```bash
dart format .
dart run build_runner build
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

La validación del contrato se ejecuta desde la raíz:

```bash
npx --yes @redocly/cli@latest lint packages/contracts/openapi.yaml
```

Las pruebas no necesitan red: sustituyen
`repositorioContenidoProvider` por un fake. En pruebas de widget no usar
`pumpAndSettle` indiscriminadamente porque la pantalla de carga y el mapa tienen
animaciones repetitivas. Avanzar el reloj con `pump(Duration(...))` y drenar los
timers pendientes.

El workflow de la app ejecuta automáticamente generación, formato, análisis,
pruebas y compilación de APK. El workflow del contrato valida OpenAPI en cada
cambio relevante.

## 9. Coordinación con backend

La API importada está documentada en
[services/api/README.md](../services/api/README.md). Tiene un modelo de datos
anterior al móvil actual y no debe conectarse todavía a las pantallas.

Mientras el backend continúe en Supabase:

- Las lecturas móviles pasan por PostgREST y las filtra RLS.
- `service_role` solo se permite en tareas de servidor sin usuario final.
- Las migraciones SQL son parte del contrato y deben revisarse junto con los
  cambios de modelos.
- Las rutas OpenAPI describen la API administrativa, no sustituyen la lectura
  directa que hoy realiza el móvil.

Cuando se inicie la migración a Firestore, el equipo debe acordar antes:

1. estructura equivalente de documentos y referencias;
2. reglas de seguridad equivalentes a la audiencia actual;
3. autenticación y propagación de identidad;
4. auditoría, retención de eventos y publicación de contenido;
5. estrategia de compatibilidad y datos de transición.

No se debe eliminar RLS ni cambiar el repositorio móvil hasta tener una
implementación verificable de esas garantías.

### Secuencia de integración acordada

1. Mantener `frontend-development` como base estable de la aplicación.
2. Trabajar la API importada en una rama independiente bajo `services/api/`.
3. Corregir proveedor de base de datos, versión de EF Core, secretos, CORS y
   pruebas de arranque.
4. Alinear DTOs y contrato con los modelos reales de Flutter y las migraciones.
5. Probar lecturas anónimas, perfiles institucionales, medios y hotspots.
6. Abrir un pull request de integración; no mezclar directamente ramas con
   historias Git sin ancestro común.
7. Cambiar el repositorio móvil solo después de verificar contrato y migración
   de datos.

## 10. Flujo de trabajo Git

Antes de publicar:

```bash
git status --short
git diff --check
git diff --stat
```

Agregar únicamente los archivos esperados:

```bash
git add .gitignore README.md docs/GUIA_DESARROLLO.md
git add apps/mobile packages supabase .github PRODUCT.md
git diff --cached --name-status
```

Después de revisar el área staged:

```bash
git commit -m "Documentar estado y flujo de desarrollo"
git push origin frontend-development
```

El equipo de backend puede trabajar sobre su rama sin mezclar cambios del
frontend. Los cambios que afecten tablas, RLS o el contrato deben coordinarse
mediante pull request y revisarse conjuntamente.

## 11. Limitaciones conocidas

- El panel administrativo aún no existe.
- La migración a Firebase/Firestore y la incorporación de AR están pendientes.
- El contenido institucional real no se distribuye con el código.
- La disponibilidad de panorámicas, audio y subtítulos depende del pipeline de
  contenido autorizado.
- El objetivo visual principal de validación es Windows con una ventana
  estrecha; la geometría táctil real debe validarse también en pruebas de
  widget o dispositivo.
