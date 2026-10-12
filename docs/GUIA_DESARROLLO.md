# UTB Tour Virtual — guía de uso y continuidad

Manual operativo único del repositorio. Describe lo que está implementado en
la rama de integración, cómo ejecutarlo, cómo probarlo, cómo modificarlo y qué
debe hacer el equipo para continuar el backend sin romper la aplicación móvil.

## 1. Estado y decisiones actuales

La rama de integración es:

```text
integration/backend-unification
```

El trabajo se revisa en el [PR #8](https://github.com/ISCOUTB/Tour-Virtual-UTB/pull/8).
La base actual es:

| Parte | Tecnología | Estado |
|---|---|---|
| Aplicación | Flutter/Dart, Riverpod, go_router | Funcional |
| API | ASP.NET Core sobre .NET 9 | Funcional en desarrollo |
| Persistencia | SQL Server + Entity Framework Core 9 | Modelo y seed de desarrollo |
| Contrato móvil | JSON HTTP con DTOs `snake_case` | Implementado |
| CI | GitHub Actions | API, análisis, pruebas y APK debug |
| Panel administrativo | Next.js | No iniciado |
| Autenticación y autorización | Claims/identidad de producción | Pendiente |
| Migración SQL Server productiva | Migración EF versionada | Pendiente |

La integración conserva el stack que existía en la rama `backend`: **.NET 9 +
EF Core 9 + SQL Server**. El móvil ya no consulta Supabase directamente; lee
contenido mediante `RepositorioContenido` contra la API.

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
apps/mobile/          Aplicación Flutter para visitantes, estudiantes y docentes
services/api/         API ASP.NET Core y modelo EF Core
packages/contracts/   Contrato OpenAPI administrativo
supabase/             Esquema y datos históricos de la implementación anterior
docs/                 Requisitos, arquitectura y esta guía
.github/workflows/    Validaciones automáticas
```

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

- .NET SDK 9.
- SQL Server o LocalDB.
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
git switch --track origin/integration/backend-unification
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

La configuración de desarrollo usa LocalDB:

```text
Server=(localdb)\mssqllocaldb
Database=TourVirtualDb
```

Si el equipo utiliza otra instancia, no se modifica el archivo versionado con
secretos. Se configura mediante user-secrets o variables de entorno.

Ejemplo con user-secrets:

```powershell
cd services/api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Database=TourVirtualDb;Trusted_Connection=True;TrustServerCertificate=True"
dotnet run --launch-profile http
```

La API queda disponible en:

```text
http://localhost:5209
```

En `Development`, `ContenidoInicial` ejecuta `EnsureCreated` y carga el seed
si la base está vacía. Esto es exclusivamente para desarrollo: no reemplaza
una migración EF Core versionada ni una carga de datos de producción.

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
[`RepositorioContenido`](../apps/mobile/lib/datos/repositorio_contenido.dart).
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
están en [`modelos.dart`](../apps/mobile/lib/datos/modelos/modelos.dart).

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
| [`main.dart`](../apps/mobile/lib/main.dart) | Arranque, tema, idioma y ajustes de accesibilidad |
| [`tema.dart`](../apps/mobile/lib/nucleo/tema.dart) | Colores medidos de la app UTB, paleta de alto contraste, tipografía y tema M3 |
| [`l10n/`](../apps/mobile/lib/l10n/) | Textos de la interfaz, uno por idioma (`textos_es.arb` es la plantilla) |
| [`idiomas.dart`](../apps/mobile/lib/nucleo/idiomas.dart) | Idiomas disponibles y cómo se elige uno |
| [`preferencias.dart`](../apps/mobile/lib/datos/preferencias.dart) | Idioma, tamaño de texto, contraste, movimiento y subtítulos elegidos en el módulo |
| [`subtitulos.dart`](../apps/mobile/lib/datos/subtitulos.dart) | Lectura de WebVTT/SRT para subtítulos en vivo y transcripción |
| [`movimiento.dart`](../apps/mobile/lib/nucleo/movimiento.dart) | Duraciones, curvas y «quitar animaciones» |
| [`pantalla_tour.dart`](../apps/mobile/lib/ui/inicio/pantalla_tour.dart) | Pantalla del módulo: cabecera, selector Recorrido/Mapa |
| [`vista_mapa.dart`](../apps/mobile/lib/ui/inicio/vista_mapa.dart) | Mapa del campus, marcadores y carrusel |
| [`ui/comunes/`](../apps/mobile/lib/ui/comunes/) | Piezas compartidas: tarjetas, fondos con arcos, anillos, 3D |
| [`repositorio_contenido.dart`](../apps/mobile/lib/datos/repositorio_contenido.dart) | Lecturas HTTP |
| [`proveedores.dart`](../apps/mobile/lib/datos/proveedores.dart) | Providers Riverpod |
| [`modelos.dart`](../apps/mobile/lib/datos/modelos/modelos.dart) | Modelos Freezed/JSON |
| [`configuracion.dart`](../apps/mobile/lib/nucleo/configuracion.dart) | `--dart-define` y defaults |
| [`rutas.dart`](../apps/mobile/lib/nucleo/rutas.dart) | Navegación |
| [`errores.dart`](../apps/mobile/lib/nucleo/errores.dart) | Errores mostrables |

Al cambiar un modelo:

```powershell
cd apps/mobile
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
- `Program.cs`: SQL Server, CORS, Swagger y arranque.

Al cambiar una entidad:

1. Actualizar el modelo y `TourDbContext`.
2. Crear una migración EF Core, nunca editar una ya aplicada.
3. Revisar los DTOs y la respuesta JSON.
4. Actualizar el repositorio Dart.
5. Añadir pruebas de contrato e integración.
6. Verificar audiencia, orden, relaciones y URLs de medios.

La migración EF Core productiva todavía debe generarse cuando el equipo tenga
el SDK y una instancia SQL Server disponible:

```powershell
cd services/api
dotnet ef migrations add InicializacionContenido
dotnet ef database update
```

Antes de ejecutar esos comandos se debe decidir si se conserva el seed actual,
cómo se preservan los IDs y cómo se importan los datos existentes. No se debe
usar `EnsureCreated` en producción.

## 10. Contenido y archivos sensibles

No se publican panoramas, audios, videos, PDFs institucionales ni capturas de
trabajo sin autorización. Los medios deben:

1. proceder de un canal autorizado;
2. pasar revisión institucional;
3. difuminar rostros cuando corresponda;
4. eliminar EXIF/GPS;
5. tener texto alternativo y subtítulos/transcripción cuando aplique;
6. almacenarse fuera de Git y servirse mediante el almacenamiento acordado.

El mapa y los assets actualmente versionados se encuentran bajo
`apps/mobile/android/app/src/assets/`. No se debe crear otra ruta de assets sin
actualizar `pubspec.yaml` y todas las plataformas afectadas.

## 11. Pruebas y validación

Móvil:

```powershell
cd apps/mobile
dart format .
dart run build_runner build
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

Crear ramas desde la rama actualizada:

```powershell
git fetch origin
git switch integration/backend-unification
git pull --ff-only
git switch -c feature/nombre-corto
```

Reglas:

- cambios de API, modelo o contrato se revisan mediante pull request;
- no se suben secretos ni medios institucionales;
- no se hace merge directo de las ramas históricas sin ancestro común;
- el backend y Flutter se validan juntos cuando cambia el contrato;
- no se fuerza un cambio de base de datos sin plan de migración y rollback.

## 13. Roadmap de continuidad

### Bloque inmediato — estabilizar la integración

1. Mantener el PR de integración y resolver cualquier cambio de la rama
   `backend` mediante revisión conjunta.
2. Generar y revisar la migración EF Core 9 para SQL Server.
3. Cargar los datos existentes con preservación de IDs, relaciones y conteos.
4. Añadir pruebas de integración contra SQL Server.
5. Decidir el almacenamiento de panoramas y audios para desarrollo y staging.

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
