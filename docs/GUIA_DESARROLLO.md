# UTB Tour Virtual — guía de uso y continuidad

Manual operativo único del repositorio. Describe lo que está implementado en
la rama de integración, cómo ejecutarlo, cómo probarlo, cómo modificarlo y qué
debe hacer el equipo para continuar el backend sin romper la aplicación móvil.

## 1. Estado y decisiones actuales

`master` contiene la última versión integrada de las tres partes. Las ramas
anteriores a la reorganización del 2026-10-29 quedaron archivadas como
etiquetas (ver sección 12).

| Parte | Carpeta | Tecnología | Estado |
|---|---|---|---|
| Frontend móvil | `packages/tour_virtual`, `apps/mobile` | Flutter/Dart, Riverpod, go_router | Funcional, con contenido remoto o local |
| Backend | `services/api` | ASP.NET Core sobre .NET 10, EF Core 10 | Funcional en desarrollo |
| Persistencia | — | PostgreSQL y Storage (S3) de Supabase | Migraciones EF versionadas |
| Frontend de administración | `apps/admin` | Next.js 16 | Listado de POI; formularios pendientes |
| Contrato | `packages/contracts` | OpenAPI, DTOs `snake_case` | Implementado |
| CI | `.github/workflows` | GitHub Actions | Móvil, API y contrato |
| Autenticación y autorización | — | Sesión de la UTB APP | Pendiente; depende de la UTB |

El móvil no consulta la base directamente. Lee el contenido de la API mediante
`RepositorioContenido`, o del contenido incluido en el módulo mediante
`RepositorioDemo`. Cuál de los dos se usará en producción, y cómo se integra
con la UTB APP, no depende del equipo: las dos vías están listas y
documentadas en [`docs/integracion-utb-app.md`](./integracion-utb-app.md).

La migración futura a Firebase/Firestore y la incorporación de AR pertenecen al
roadmap del SRS, pero todavía no están implementadas. No deben iniciarse
eliminando el contrato actual sin una migración verificable.

### Documentos que siguen siendo autoridad

- Esta guía: operación y continuidad del código actual.
- [`docs/arquitectura.md`](./arquitectura.md): seguridad, cumplimiento y
  decisiones arquitectónicas no cubiertas por el SRS. Sus decisiones de
  backend anteriores deben leerse junto con este estado de integración.
- [`docs/utb-tour-inmersivo-mvp.md`](./utb-tour-inmersivo-mvp.md): alcance del
  producto y flujo del MVP.
- `docs/SRSIEEE830TourVirtualUTBv3.1.pdf`: requisitos funcionales definitivos.
- [`PRODUCT.md`](../PRODUCT.md): usuarios, principios de producto y contenido
  todavía ausente.
- [`docs/ACCESIBILIDAD.md`](./ACCESIBILIDAD.md): idiomas de la interfaz,
  accesibilidad, formato de audios y subtítulos, y lo que falta del backend
  para traducir el contenido.

## 2. Qué hay en el repositorio

```text
packages/tour_virtual/  Frontend móvil: el módulo Flutter que se incrusta en la UTB APP
apps/mobile/            App de demostración que abre el módulo; genera el APK y corre las pruebas
apps/admin/             Frontend de administración (Next.js)
services/api/           Backend: API ASP.NET Core y modelo EF Core
packages/contracts/     Contrato OpenAPI administrativo
scripts/                Mapa del campus, narraciones, medios y APK de demostración
supabase/               Esquema y datos históricos de la implementación anterior
docs/                   Requisitos, arquitectura, integración y esta guía
.github/workflows/      Validaciones automáticas
```

Cómo encaja el módulo en la UTB APP: [integracion-utb-app.md](integracion-utb-app.md).

La API y el móvil comparten conceptualmente estas entidades:

```text
Lugar
├── Poi
│   ├── Escena
│   └── Medio
├── Ruta ── RutaPoi ── Poi
└── Escena ── Hotspot ── Escena destino
```

El seed contiene un campus, cinco POI, cinco escenas, seis hotspots, cinco
medios de audio y tres rutas. El visitante externo ve cuatro POI; el puente
A3-A5 se reserva para estudiantes y docentes.

## 3. Requisitos de instalación

### Móvil

- Flutter estable con Dart compatible con el `pubspec.yaml`.
- En Windows: Visual Studio Build Tools con **Desktop development with C++** y
  Windows SDK.
- Android SDK y `adb` solo si se prueba en emulador o dispositivo.
- VS Code con extensiones Dart y Flutter.

### Backend

- .NET SDK 10.
- Acceso a la base PostgreSQL y al Storage del proyecto en Supabase. Las
  credenciales las entrega el equipo de backend y nunca se versionan.
- Visual Studio, VS Code o Rider con soporte C# opcional.

### Herramientas auxiliares

- Git.
- Node.js 22 o superior para validar OpenAPI.
- Docker Desktop y Supabase CLI solo para estudiar o mantener la base histórica
  de `supabase/`; no son necesarios para ejecutar la API integrada.

Verificar el entorno móvil:

```powershell
flutter doctor -v
```

Verificar el backend:

```powershell
dotnet --info
```

## 4. Preparar una copia nueva

Desde PowerShell:

```powershell
git clone https://github.com/ISCOUTB/Tour-Virtual-UTB.git
cd Tour-Virtual-UTB
git fetch origin
git switch master
```

Preparar Flutter:

```powershell
cd apps/mobile
flutter pub get
```

Preparar la API:

```powershell
cd ..\..\services\api
dotnet restore
dotnet build
```

No se deben copiar al repositorio credenciales, archivos `.env`, certificados,
keystores, cadenas de conexión privadas ni medios institucionales sin
autorización.

## 5. Ejecutar el backend

La API usa la base PostgreSQL del proyecto en Supabase y su Storage
compatible con S3. Las credenciales se configuran con `dotnet user-secrets`,
nunca en un archivo versionado. Los comandos exactos, incluida la cadena del
pooler de Supabase, están en el [`README.md`](../README.md#backend).

```powershell
cd services/api
dotnet run --launch-profile http
```

`scripts/correr_api.ps1` hace lo mismo y, si hay un teléfono Android conectado
por USB, le reenvía el puerto para que la app llegue a `http://127.0.0.1:5209`.

La API queda disponible en:

```text
http://localhost:5209
```

La base compartida solo cambia mediante los endpoints de administración o
SQL revisado. `ContenidoInicial.InicializarAsync`, que sembraba una base vacía,
está comentado en `Program.cs`.

Swagger está disponible en:

```text
http://localhost:5209/swagger
```

Probar manualmente:

```powershell
Invoke-RestMethod http://localhost:5209/api/lugares/1/pois
Invoke-RestMethod http://localhost:5209/api/lugares/1/recorrido
Invoke-RestMethod http://localhost:5209/api/pois/1
Invoke-RestMethod http://localhost:5209/api/lugares/1/ruta
```

Para probar contenido restringido en desarrollo se puede enviar el header
`X-UTB-Audiencia`:

```powershell
$headers = @{ "X-UTB-Audiencia" = "estudiante" }
Invoke-RestMethod http://localhost:5209/api/lugares/1/pois -Headers $headers
```

Este header es una facilidad de desarrollo, **no es autenticación** y no debe
considerarse una frontera de seguridad en producción.

## 6. Ejecutar el móvil

Con la API ejecutándose:

```powershell
cd apps/mobile
flutter run -d windows
```

La aplicación usa por defecto:

```text
http://127.0.0.1:5209
```

Para otra API:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=https://api.example.com
```

En el emulador Android, el host de Windows se alcanza como `10.0.2.2`:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5209
```

El parámetro `LUGAR_ID` permite cambiar el campus cuando exista más de uno:

```powershell
flutter run -d windows --dart-define=LUGAR_ID=1
```

Las rutas profundas útiles son:

```text
/recorrido/1
/recorrido/1?escena=12
```

El móvil resuelve las rutas relativas de medios (`panoramas/...`, `audios/...`)
contra `API_BASE_URL`. Los archivos reales no están versionados; si la API no
los sirve, el resto de la aplicación continúa mostrando el estado de error.

### Sin backend: modo demo

Para trabajar el frontend sin levantar la API (que hoy exige Postgres y
credenciales de Supabase S3):

```powershell
flutter run -d windows --dart-define=DATOS=demo
```

Carga los lugares del seed (`services/api/Data/ContenidoInicial.cs`) tal como
los ve un visitante externo, y el mapa empaquetado. Para ver además las
panorámicas y el audio, se sirve una carpeta con las mismas claves del seed
(`panoramas/<slug>.jpg`, `panoramas/<slug>-baja.jpg`, `audios/<slug>.mp3`):

```powershell
python -m http.server 8765 --bind 127.0.0.1   # dentro de esa carpeta
flutter run -d windows --dart-define=DATOS=demo --dart-define=MEDIOS_DEMO=http://127.0.0.1:8765
```

El pie de la lista muestra «Datos de demostración» para que nadie confunda
esa pantalla con contenido real.

En esa carpeta el demo también encuentra, si existen, narraciones por idioma
(`audios/<slug>.<idioma>.mp3`) y subtítulos (`subtitulos/<slug>.vtt`,
`subtitulos/<slug>.<idioma>.vtt`). Sirve para revisar audios y subtítulos en
la app antes de que el backend sepa guardarlos; el formato está en
[`ACCESIBILIDAD.md`](./ACCESIBILIDAD.md).

## 7. Contrato entre API y Flutter

El único punto de red del móvil es
[`RepositorioContenido`](../packages/tour_virtual/lib/datos/repositorio_contenido.dart).
Las pantallas no deben llamar HTTP ni acceder directamente a la base.

Endpoints actuales:

| Método | Endpoint | Respuesta |
|---|---|---|
| GET | `/api/lugares/{lugarId}/pois` | Lista de `Poi` visibles |
| GET | `/api/lugares/{lugarId}/recorrido` | `escenas` y `hotspots` |
| GET | `/api/pois/{poiId}` | `poi` y `medios` |
| GET | `/api/lugares/{lugarId}/ruta` | Ruta activa o `null` |

Los DTOs están en
[`ContenidoDtos.cs`](../services/api/DTOs/ContenidoDtos.cs). Los modelos Dart
están en [`modelos.dart`](../packages/tour_virtual/lib/datos/modelos/modelos.dart).

No se deben cambiar nombres como `lugar_id`, `map_x`, `imagen_url`,
`escena_destino_id` o `duracion_seg` sin actualizar ambos lados y sus pruebas.
Los enums se transmiten como texto:

```text
externo, estudiante, docente
navegacion, info
imagen, video, audio
```

El filtro de audiencia pertenece al servidor. Nunca se debe ocultar contenido
solo con una condición en Dart.

## 8. Trabajar en el móvil

Archivos principales:

| Archivo | Responsabilidad |
|---|---|
| [`tour_virtual.dart`](../packages/tour_virtual/lib/tour_virtual.dart) | Lo único que importa la app anfitriona: `TourVirtual`, `ConfiguracionTour` |
| [`configuracion_tour.dart`](../packages/tour_virtual/lib/configuracion_tour.dart) | Fuente de contenido (API o local), lugar, audiencia y salida |
| [`app_tour.dart`](../packages/tour_virtual/lib/app_tour.dart) | Widget `TourVirtual`, tema, idioma y ajustes de accesibilidad |
| [`main.dart`](../apps/mobile/lib/main.dart) | App de demostración: abre el módulo con la configuración de `--dart-define` |
| [`tema.dart`](../packages/tour_virtual/lib/nucleo/tema.dart) | Colores medidos de la app UTB, paleta de alto contraste, tipografía y tema M3 |
| [`l10n/`](../packages/tour_virtual/lib/l10n/) | Textos de la interfaz, uno por idioma (`textos_es.arb` es la plantilla) |
| [`idiomas.dart`](../packages/tour_virtual/lib/nucleo/idiomas.dart) | Idiomas disponibles y cómo se elige uno |
| [`preferencias.dart`](../packages/tour_virtual/lib/datos/preferencias.dart) | Idioma, tamaño de texto, contraste, movimiento y subtítulos elegidos en el módulo |
| [`subtitulos.dart`](../packages/tour_virtual/lib/datos/subtitulos.dart) | Lectura de WebVTT/SRT para subtítulos en vivo y transcripción |
| [`movimiento.dart`](../packages/tour_virtual/lib/nucleo/movimiento.dart) | Duraciones, curvas y «quitar animaciones» |
| [`pantalla_tour.dart`](../packages/tour_virtual/lib/ui/inicio/pantalla_tour.dart) | Pantalla del módulo: cabecera, selector Recorrido/Mapa |
| [`vista_mapa.dart`](../packages/tour_virtual/lib/ui/inicio/vista_mapa.dart) | Mapa del campus, marcadores y carrusel |
| [`ui/comunes/`](../packages/tour_virtual/lib/ui/comunes/) | Piezas compartidas: tarjetas, fondos con arcos, anillos, 3D |
| [`repositorio_contenido.dart`](../packages/tour_virtual/lib/datos/repositorio_contenido.dart) | Lecturas HTTP |
| [`proveedores.dart`](../packages/tour_virtual/lib/datos/proveedores.dart) | Providers Riverpod |
| [`modelos.dart`](../packages/tour_virtual/lib/datos/modelos/modelos.dart) | Modelos Freezed/JSON |
| [`configuracion.dart`](../packages/tour_virtual/lib/nucleo/configuracion.dart) | `--dart-define` y defaults |
| [`rutas.dart`](../packages/tour_virtual/lib/nucleo/rutas.dart) | Navegación |
| [`errores.dart`](../packages/tour_virtual/lib/nucleo/errores.dart) | Errores mostrables |

Al cambiar un modelo (el código del módulo vive en el paquete):

```powershell
cd packages/tour_virtual
dart run build_runner build
```

No se deben editar manualmente los archivos `*.freezed.dart` ni `*.g.dart`.
Después se actualizan repositorio, providers, UI y pruebas relacionadas.

El módulo vive dentro de la app UTB y copia su lenguaje visual: tema oscuro,
cabeceras azules con arcos, tarjetas grafito y Roboto. La referencia son las
capturas de `docs/capturas_utbapp/`, que no se versionan porque muestran datos
personales y se piden al equipo. No se escriben colores sueltos en las
pantallas: salen de `ColoresUtb` en `tema.dart` (o de `PaletaUtb.de(context)`
para los que cambian con el alto contraste), y si la app anfitriona cambia se
vuelven a medir allí. Todo efecto decorativo consulta `sinMovimiento()`.

Ningún texto de interfaz se escribe en el código: va en
`lib/l10n/textos_es.arb` y se traduce en los demás archivos de esa carpeta
(ver [`ACCESIBILIDAD.md`](./ACCESIBILIDAD.md)). Un botón que envuelve su
contenido en `Semantics(excludeSemantics: true)` necesita también `onTap` en
ese `Semantics`; si no, el lector de pantalla lo anuncia y el doble toque no
hace nada.

Para agregar una pantalla:

1. Crear la pantalla con las piezas de `lib/ui/comunes/`.
2. Declarar la ruta en `lib/nucleo/rutas.dart`.
3. Consumir providers y `VistaAsync`.
4. Añadir estados de carga, error, reintento y datos.
5. Poner sus textos en `lib/l10n/` y comprobarla con el texto al 200 %.
6. Crear o actualizar la prueba de widget.

## 9. Trabajar en la API

La API usa:

- `Models/Contenido.cs`: entidades y enums.
- `Data/TourDbContext.cs`: relaciones y restricciones EF.
- `Data/ContenidoInicial.cs`: seed local temporal.
- `Controllers/ContenidoController.cs`: endpoints de lectura.
- `DTOs/ContenidoDtos.cs`: contrato JSON.
- `Program.cs`: PostgreSQL (Npgsql), Storage S3, CORS, Swagger y arranque.

Al cambiar una entidad:

1. Actualizar el modelo y `TourDbContext`.
2. Crear una migración EF Core, nunca editar una ya aplicada.
3. Revisar los DTOs y la respuesta JSON.
4. Actualizar el repositorio Dart.
5. Añadir pruebas de contrato e integración.
6. Verificar audiencia, orden, relaciones y URLs de medios.

Las migraciones viven en `services/api/Migrations` (`InitialPostgres`,
`AgregarMapaUrl`, `EscenaImagenOpcional`). Una nueva se crea y aplica así:

```powershell
cd services/api
dotnet ef migrations add <Nombre>
dotnet ef database update
```

`database update` se ejecuta solo contra la base prevista para el entorno, y
nunca se edita una migración ya aplicada.

## 10. Contenido y archivos sensibles

No se publican panoramas, audios, videos, PDFs institucionales ni capturas de
trabajo sin autorización. Los medios deben:

1. proceder de un canal autorizado;
2. pasar revisión institucional;
3. difuminar rostros cuando corresponda;
4. eliminar EXIF/GPS;
5. tener texto alternativo y subtítulos/transcripción cuando aplique;
6. almacenarse fuera de Git y servirse mediante el almacenamiento acordado.

El mapa y los assets versionados se encuentran bajo
`packages/tour_virtual/assets/` y se declaran en el `pubspec.yaml` del paquete.
Desde el código se piden con el prefijo `packages/tour_virtual/` (o con
`package: 'tour_virtual'`), que es como los encuentra cualquier app que use el
módulo; sin él funcionarían en una app y fallarían en la UTB APP.

## 11. Pruebas y validación

Móvil:

```powershell
cd packages/tour_virtual          # el módulo
dart format .
dart run build_runner build
flutter gen-l10n
flutter analyze --fatal-infos

cd ../../apps/mobile              # la app de demostración, con las pruebas
dart format .
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

Pruebas enfocadas:

```powershell
flutter test test/modelos_test.dart
flutter test test/repositorio_contenido_test.dart
flutter test test/textos_test.dart
flutter test test/widget_test.dart
```

API:

```powershell
cd services/api
dotnet restore
dotnet build --configuration Release
```

Contrato administrativo:

```powershell
cd ..\..
npx --yes @redocly/cli@latest lint packages/contracts/openapi.yaml
```

Las pruebas del móvil no necesitan red: sobrescriben
`repositorioContenidoProvider` con un fake. Las pruebas de widget no deben
usar `pumpAndSettle` cuando haya animaciones repetitivas; deben avanzar el reloj
con `pump(Duration(...))`.

Los workflows de GitHub Actions ejecutan análisis, pruebas, generación de
código y APK debug para la rama de integración. La API tiene un workflow
separado de restore y build.

## 12. Flujo Git del equipo

Antes de publicar:

```powershell
git status --short
git diff --check
git diff --stat
```

`master` es la rama principal y siempre contiene la última versión integrada
de las tres partes (móvil, backend y administración). Las ramas de trabajo
salen de ella y vuelven a ella por pull request:

```powershell
git fetch origin
git switch master
git pull --ff-only
git switch -c <parte>/<tema>      # p. ej. movil/realidad-aumentada, backend/medios-idioma, admin/formulario-poi
```

Las ramas anteriores a la reorganización del 2026-10-29 quedaron archivadas
como etiquetas `archivo/<rama>`; se recuperan con `git switch -c <rama> archivo/<rama>`.

Reglas:

- cambios de API, modelo o contrato se revisan mediante pull request;
- no se suben secretos ni medios institucionales;
- no se hace merge directo de las ramas históricas sin ancestro común;
- el backend y Flutter se validan juntos cuando cambia el contrato;
- no se fuerza un cambio de base de datos sin plan de migración y rollback.

## 13. Roadmap de continuidad

### Bloque inmediato — estabilizar la integración

1. Completar las tareas de backend de [`docs/tareas-backend.md`](./tareas-backend.md)
   (issue #10): lat/lng, catálogo de lugares, narraciones por idioma,
   subtítulos y texto alternativo.
2. Completar el panel de administración: formularios de POI, escenas y medios.
3. Añadir pruebas de integración de la API contra PostgreSQL.
4. Acordar con la UTB la vía de integración y la fuente de contenido
   ([`docs/integracion-utb-app.md`](./integracion-utb-app.md)).

### Bloque de seguridad y producción

1. Implementar autenticación.
2. Derivar la audiencia desde claims verificados, no desde headers enviados por
   el cliente.
3. Separar permisos de lectura pública, lectura institucional y administración.
4. Añadir auditoría, retención y trazabilidad.
5. Validar MIME real, tamaño, escaneo y autorización de archivos.
6. Configurar CORS, HTTPS, secretos y observabilidad por entorno.

### Bloque de producto

1. Completar textos, panoramas, audios, subtítulos y textos alternativos.
2. Implementar el panel administrativo.
3. Alinear el contrato OpenAPI con los endpoints reales.
4. Validar accesibilidad y dispositivos de gama baja.
5. Medir apertura, escenas vistas, hotspots usados y recorridos completos.

### Bloque futuro condicionado por el SRS

La migración a Firestore, el mapa basado en Google Maps/Mapbox/OSM y AR solo
deben comenzar con:

- decisión técnica aprobada;
- equivalencia de reglas de seguridad;
- estrategia de migración y coexistencia;
- pruebas de regresión del contrato móvil;
- plan de retorno.

## 14. Lista de salida antes de producción

- [ ] Migraciones EF Core versionadas y aplicadas en un entorno de staging.
- [ ] Datos migrados y conteos verificados.
- [ ] API y móvil consumen el mismo contrato probado.
- [ ] Autenticación y autorización basadas en identidad.
- [ ] CORS y HTTPS configurados por entorno.
- [ ] Auditoría y retención implementadas.
- [ ] Medios revisados, anonimizados y almacenados fuera de Git.
- [ ] Texto alternativo, subtítulos y transcripciones disponibles.
- [ ] Pruebas de integración y regresión verdes.
- [ ] Build móvil firmado fuera del repositorio.
- [ ] Rollback documentado.
