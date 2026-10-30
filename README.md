# UTB Tour Virtual

Recorrido virtual inmersivo del Campus Tecnológico de Ternera de la **Universidad Tecnológica de Bolívar**. Incluye un mapa del campus, panorámicas 360°, narraciones en 11 idiomas con subtítulos y ajustes de accesibilidad (WCAG 2.2 AA).

El tour está diseñado como **un módulo de la app oficial UTB APP**, con su mismo lenguaje visual, y se puede incrustar en ella como un paquete Flutter. Mientras esa integración no ocurra, una app de demostración lo abre por su cuenta, con o sin servidor.

## Las tres partes

| Parte | Carpeta | Tecnología | Qué hace |
|---|---|---|---|
| **Backend** | [`services/api/`](services/api) | ASP.NET Core (.NET 10), EF Core, PostgreSQL y Storage de Supabase | API de contenido para la app y API de administración para el panel. |
| **Frontend móvil** | [`packages/tour_virtual/`](packages/tour_virtual) | Flutter, Riverpod, go_router | **El módulo**: todo el tour, listo para incrustarse en la UTB APP. |
| | [`apps/mobile/`](apps/mobile) | Flutter | App de demostración que abre el módulo, genera el APK y corre las pruebas. |
| **Frontend admin** | [`apps/admin/`](apps/admin) | Next.js 16, React 19 | Panel para editar lugares, escenas y medios. Hoy lista los POI. |

Además:

| Carpeta | Qué es |
|---|---|
| [`packages/contracts/`](packages/contracts) | Contrato OpenAPI de la API. |
| [`scripts/`](scripts) | Plano del campus (OpenStreetMap), narraciones, carga de medios y APK de demostración. |
| [`supabase/`](supabase) | Esquema y políticas RLS de la primera versión, que leía Supabase directamente. Es histórico: la API usa las migraciones de EF Core. |
| [`docs/`](docs) | Documentación (ver abajo). |

## Integración con la UTB APP

La UTB APP agrega el módulo como dependencia y lo abre como una pantalla más:

```yaml
dependencies:
  tour_virtual:
    git:
      url: https://github.com/ISCOUTB/Tour-Virtual-UTB
      path: packages/tour_virtual
```

```dart
Navigator.of(context).push(MaterialPageRoute<void>(
  builder: (context) => TourVirtual(
    configuracion: ConfiguracionTour(
      fuente: const ContenidoRemoto(urlApi: 'https://api.tour.utb.edu.co'),
      alSalir: () => Navigator.of(context).pop(),
    ),
  ),
));
```

Ni la integración ni la decisión entre **datos en la nube** (`ContenidoRemoto`, la API de `services/api`) y **datos locales** (`ContenidoLocal`, sin servidor) dependen del equipo. Las dos vías están implementadas y se elige una con un solo parámetro. Requisitos, opciones y pendientes de la UTB: [`docs/integracion-utb-app.md`](docs/integracion-utb-app.md).

## Cómo ejecutar cada parte

### Frontend móvil

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=DATOS=demo        # sin servidor: contenido local, sin medios
flutter run                                 # contra la API local (http://127.0.0.1:5209)
flutter test
```

Desde un emulador Android la API local es `http://10.0.2.2:5209`; la app ya lo resuelve. Para un APK que funciona sin red y con medios: `python scripts/preparar_apk_demo.py` (necesita los medios institucionales, que no se versionan).

Para trabajar en el código del módulo (modelos, textos):

```bash
cd packages/tour_virtual
flutter pub get
dart run build_runner build   # tras cambiar un modelo
flutter gen-l10n              # tras cambiar un .arb
```

### Backend

Requiere el SDK de .NET 10 y acceso a la base del proyecto en Supabase. Las credenciales se guardan con `dotnet user-secrets`, nunca en el repositorio:

```powershell
cd services/api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=aws-1-us-west-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.qjnusmpwznaegeburldo;Password=[CONTRASEÑA_DB];SSL Mode=Require"
dotnet user-secrets set "SupabaseS3:ServiceUrl" "https://[PROYECTO].supabase.co/storage/v1/s3"
dotnet user-secrets set "SupabaseS3:AccessKey" "[ACCESS_KEY]"
dotnet user-secrets set "SupabaseS3:SecretKey" "[SECRET_KEY]"
dotnet user-secrets set "Admin:ApiKey" "[UNA_CLAVE_LARGA_Y_ALEATORIA]"
dotnet run --launch-profile http
```

- **Base de datos:** usa el *session pooler* (puerto `5432`). Con el *transaction pooler* (puerto `6543`) la API se queda colgada al conectar. La conexión directa (`db.[PROYECTO].supabase.co`) solo funciona con IPv6. La contraseña es la de la base (Supabase → Project Settings → Database), y el usuario lleva el id del proyecto pegado.
- **Clave de administración:** los endpoints que escriben (`/api/admin/*`) piden la cabecera `X-Admin-Key`. Sin clave configurada, en `Development` quedan abiertos (la API lo avisa al arrancar) y en cualquier otro entorno responden `503`.
- **Uso:** la API queda en `http://localhost:5209` y Swagger en `/swagger` (botón **Authorize** para la clave). `scripts/correr_api.ps1` la levanta y reenvía el puerto a un teléfono conectado por USB.
- **Migraciones:** `dotnet ef database update`, solo contra la base prevista para tu entorno.

#### Subir contenido

Todo se hace desde Swagger con la clave de administración.

- **Videos, audios y fotos de un POI:** `POST /api/admin/pois/{poiId}/medios`. Sube el archivo y crea el medio en un solo paso.
  - Elige `Tipo` (`video`, `audio` o `imagen`). Las imágenes piden `TextoAlt`.
  - Para video usa MP4 (H.264 + AAC). El límite es 50 MB.
  - Las fotos se reducen a 2048 px y pierden los metadatos EXIF.
- **Panorámicas:**
  1. Crea la escena con `POST /api/admin/escenas`, con `ImagenUrl` vacío.
  2. Sube la imagen con `POST /api/admin/escenas/{id}/imagen`. El servidor la reduce a 4096×2048, genera la vista previa de 1024×512 y borra el EXIF.
- **Carpeta** es opcional. Si se indica, debe ser `panoramas`, `mapas`, `medios`, `imagenes`, `videos` o `audios`.
- **URL externa:** un medio también puede apuntar a una URL `https://...` creándolo con `POST /api/admin/medios`. Se entrega tal cual, sin firmar.

Las tareas pendientes del backend están en [`docs/tareas-backend.md`](docs/tareas-backend.md) (issue #10).

### Frontend admin

Con la API corriendo en `http://localhost:5209`, que el panel alcanza mediante el proxy de `next.config.ts`:

```bash
cd apps/admin
npm install
npm run dev     # http://localhost:3000
```

## Ramas

- **`master`** contiene la última versión integrada de las tres partes.
- Las ramas de trabajo salen de `master` y vuelven por pull request. Se nombran `<parte>/<tema>`, por ejemplo `movil/realidad-aumentada`, `backend/medios-idioma` o `admin/formulario-poi`.
- Las ramas anteriores a la reorganización del 2026-10-29 están archivadas como etiquetas `archivo/<rama>`. Se recuperan con `git switch -c <rama> archivo/<rama>`.

CI (GitHub Actions) verifica en cada pull request:

- el módulo: formato, código generado y análisis;
- la app de demostración: pruebas y APK de depuración;
- la API: compilación y dependencias vulnerables;
- el panel admin: dependencias vulnerables, análisis y compilación;
- el contrato OpenAPI.

## Documentación

| Documento | Para qué |
|---|---|
| [`docs/GUIA_DESARROLLO.md`](docs/GUIA_DESARROLLO.md) | Manual operativo: instalación, ejecución, contrato HTTP, pruebas y flujo Git. |
| [`docs/integracion-utb-app.md`](docs/integracion-utb-app.md) | Cómo se incrusta el módulo en la UTB APP y qué falta del lado de la UTB. |
| [`docs/tareas-backend.md`](docs/tareas-backend.md) | Lo que le falta al backend y al panel. |
| [`docs/arquitectura.md`](docs/arquitectura.md) | Arquitectura, seguridad y cumplimiento de la Ley 1581 (sección 7). |
| [`docs/ACCESIBILIDAD.md`](docs/ACCESIBILIDAD.md) | Idiomas, accesibilidad, formato de audios y subtítulos. |
| [`docs/mapa-osm.md`](docs/mapa-osm.md) | El plano del campus: origen, correcciones y precisión de cada lugar. |
| [`docs/plan-realidad-aumentada.md`](docs/plan-realidad-aumentada.md) | Plan para la navegación con realidad aumentada del SRS. |
| [`docs/utb-tour-inmersivo-mvp.md`](docs/utb-tour-inmersivo-mvp.md) | Alcance original del MVP. |
| [`PRODUCT.md`](PRODUCT.md), [`DESIGN.md`](DESIGN.md) | Producto y sistema visual. |

El SRS (`SRSIEEE830TourVirtualUTBv3.1.pdf`) es la autoridad sobre los requisitos. Como el resto del material institucional, no está en el repositorio: se pide al equipo.

## Seguridad y material institucional

- No se versionan credenciales, `.env`, keystores ni cadenas de conexión reales.
- Panorámicas, audios, el mapa ilustrado y los documentos fuente son material de la universidad. Viven fuera del repositorio (`assets/`, ignorado).
- Toda panorámica pasa por el difuminado de caras y la eliminación de EXIF antes de publicarse (Ley 1581; ver `docs/arquitectura.md`, sección 7).
- Las capturas de la UTB APP muestran datos personales y no se suben.
- El panel admin **nunca** envía `X-Admin-Key` desde el navegador. Cuando escriba contenido, debe hacerlo desde el servidor de Next.js (route handlers o server actions), con la clave en una variable de entorno sin el prefijo `NEXT_PUBLIC_`. Además, el panel necesita su propio inicio de sesión antes de publicarse.
- La API solo acepta imágenes que puede volver a codificar (JPEG, PNG, WebP; nunca SVG) y de hasta 64 megapíxeles.
- El CI falla si una dependencia tiene una vulnerabilidad conocida: `npm audit` en el panel y `dotnet list package --vulnerable` en la API. Las acciones de terceros van fijadas por commit, y los workflows solo tienen permiso de lectura.
