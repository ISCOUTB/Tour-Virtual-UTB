# UTB Tour Virtual

Recorrido virtual inmersivo del campus de la **Universidad Tecnológica de Bolívar (UTB)**, desarrollado para facilitar la exploración de sus espacios mediante una experiencia digital interactiva.

El proyecto está compuesto por una aplicación móvil desarrollada con **Flutter** y una API REST construida con **ASP.NET Core**, Entity Framework Core y SQL Server.

## Tabla de contenidos

- [Características](#características)
- [Tecnologías](#tecnologías)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Configuración del backend](#configuración-del-backend)
- [Migraciones de base de datos](#migraciones-de-base-de-datos)
- [Documentación](#documentación)
- [Seguridad](#seguridad)
- [Flujo de trabajo con Git](#flujo-de-trabajo-con-git)

## Características

- Recorrido virtual interactivo del campus universitario.
- Aplicación móvil multiplataforma basada en Flutter.
- API REST desarrollada con ASP.NET Core.
- Acceso a datos mediante Entity Framework Core.
- Persistencia de información mediante una base de datos relacional.
- Configuración segura de credenciales mediante `dotnet user-secrets`.
- Documentación técnica, requisitos y lineamientos de desarrollo centralizados.

Consulta la documentación del proyecto para conocer el alcance funcional implementado y las funcionalidades pendientes.

## Tecnologías

| Componente | Tecnología |
|---|---|
| Aplicación móvil | Flutter / Dart |
| Backend | ASP.NET Core |
| Acceso a datos | Entity Framework Core 9 |
| Base de datos | SQL Server |
| Contratos de API | OpenAPI |
| Almacenamiento de objetos | Supabase Storage mediante S3 |
| Gestión de secretos | .NET User Secrets |

> **Nota:** El proyecto contiene referencias históricas a Supabase y PostgreSQL. Verifica la configuración vigente en la API y en `docs/GUIA_DESARROLLO.md` antes de configurar una base de datos nueva.

## Estructura del proyecto

```text
.
├── apps/
│   └── mobile/              # Aplicación Flutter
├── services/
│   └── api/                 # API ASP.NET Core y EF Core
├── packages/
│   └── contracts/           # Contratos OpenAPI administrativos
├── supabase/                # Esquema histórico y datos de referencia
├── docs/
│   ├── GUIA_DESARROLLO.md   # Guía principal de desarrollo
│   ├── arquitectura.md      # Arquitectura, seguridad y cumplimiento
│   └── utb-tour-inmersivo-mvp.md
├── PRODUCT.md               # Definición y estado del producto
└── README.md
```

## Requisitos previos

Antes de ejecutar el proyecto, instala las siguientes herramientas:

- [Git](https://git-scm.com/)
- [.NET SDK](https://dotnet.microsoft.com/download)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Visual Studio](https://visualstudio.microsoft.com/) o Visual Studio Code
- SQL Server y un usuario con permisos sobre la base de datos.
- [EF Core CLI](https://learn.microsoft.com/ef/core/cli/dotnet), para gestionar las migraciones.

Verifica que las herramientas estén disponibles:

```powershell
git --version
dotnet --version
flutter --version
```

Para comprobar la configuración de Flutter:

```powershell
flutter doctor
```

## Instalación y ejecución

### 1. Clonar el repositorio

Si todavía no tienes una copia local, clona el repositorio y entra en su directorio:

```powershell
git clone <URL_DEL_REPOSITORIO>
cd <DIRECTORIO_DEL_PROYECTO>
```

Si ya tienes el proyecto descargado, omite este paso.

### 2. Seleccionar la rama de trabajo

```powershell
git switch integration/backend-unification
```

Asegúrate de utilizar la rama indicada por el equipo para tu entorno de desarrollo.

### 3. Ejecutar el backend

Abre una terminal en la raíz del proyecto y ejecuta:

```powershell
cd services/api
dotnet restore
dotnet run --launch-profile http
```

La API estará disponible localmente en:

`http://localhost:5209`

Mantén esta terminal abierta mientras utilizas la aplicación.

### 4. Ejecutar la aplicación Flutter

Abre una segunda terminal desde la raíz del repositorio:

```powershell
cd apps/mobile
flutter pub get
flutter run -d windows
```

Este comando ejecuta la aplicación para Windows. Para utilizar otro dispositivo, consulta los dispositivos disponibles:

```powershell
flutter devices
```

Selecciona el dispositivo deseado y sustituye `windows` por su identificador.

### 5. Configurar la dirección de la API

La configuración local documentada utiliza las siguientes direcciones:

- **Backend:** `http://localhost:5209`
- **Aplicación móvil Windows:** `http://127.0.0.1:5209`

Ambas direcciones apuntan al equipo local cuando se ejecutan en la misma máquina.

Si ejecutas la aplicación en un emulador o dispositivo físico, es posible que debas configurar la dirección IP del equipo donde se ejecuta el backend. Consulta `docs/GUIA_DESARROLLO.md` para conocer la configuración específica de la aplicación.

## Configuración del backend

El backend utiliza `dotnet user-secrets` para almacenar información sensible durante el desarrollo local, evitando que las credenciales se incluyan en el código fuente.

### 1. Inicializar User Secrets

Desde el directorio de la API:

```powershell
cd services/api
dotnet user-secrets init
```

Este comando inicializa el almacenamiento de secretos asociado al proyecto .NET.

### 2. Configurar la cadena de conexión

La base de datos es el Postgres de Supabase. Usa el **session pooler** (puerto `5432`); con el transaction pooler (puerto `6543`) la API se queda colgada al conectar. La conexión directa (`db.[PROYECTO].supabase.co`) solo funciona con IPv6, así que en la mayoría de redes no sirve.

```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=aws-1-us-west-2.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.qjnusmpwznaegeburldo;Password=[CONTRASEÑA_DB];SSL Mode=Require"
```

La contraseña es la de la base de datos (Supabase → Project Settings → Database), no la de tu cuenta. Fíjate en que el usuario lleva el id del proyecto pegado (`postgres.qjnusmpwznaegeburldo`): con el pooler, `postgres` a secas no entra.

### 3. Configurar Supabase Storage mediante S3

Si el backend utiliza el almacenamiento S3 compatible de Supabase, configura sus credenciales:

```powershell
dotnet user-secrets set "SupabaseS3:ServiceUrl" "https://[PROYECTO].supabase.co/storage/v1/s3"
dotnet user-secrets set "SupabaseS3:AccessKey" "[ACCESS_KEY]"
dotnet user-secrets set "SupabaseS3:SecretKey" "[SECRET_KEY]"
```

Reemplaza los valores de ejemplo por las credenciales correspondientes a tu proyecto. No compartas las claves reales ni las incluyas en archivos versionados.

**Importante:** los nombres de las claves deben coincidir exactamente con los que lee la configuración del backend. Si el proyecto utiliza otra base de datos o proveedor de almacenamiento, sigue la configuración definida en el código y en la guía de desarrollo.

### 4. Configurar la clave de administración

Los endpoints que escriben contenido (`/api/admin/*` y `POST /api/lugares/{id}/mapa`) piden la cabecera `X-Admin-Key`. Define la clave con:

```powershell
dotnet user-secrets set "Admin:ApiKey" "[UNA_CLAVE_LARGA_Y_ALEATORIA]"
```

En Swagger, pulsa **Authorize** y pega la clave. Si no la configuras, en `Development` esos endpoints quedan abiertos (la API lo avisa en el log al arrancar) y en cualquier otro entorno responden `503`.

### 5. Verificar los secretos configurados

```powershell
dotnet user-secrets list
```

Este comando muestra los nombres y valores almacenados. Evita compartir su salida, ya que puede contener credenciales.

## Subir contenido

Todo se hace desde Swagger (`http://localhost:5209/swagger`) con la clave de administración.

- **Videos, audios y fotos de un POI:** `POST /api/admin/pois/{poiId}/medios`. Sube el archivo y crea el medio en un solo paso. Elige `Tipo` (`video`, `audio` o `imagen`); las imágenes piden `TextoAlt`. Para video usa MP4 (H.264 + AAC), que es lo que reproducen Android, iOS y web; el límite es 50 MB, el mismo que pone Supabase en el plan gratuito. Las fotos se reducen a 2048 px y pierden los metadatos EXIF.
- **Panorámicas:** crea la escena con `POST /api/admin/escenas` dejando `ImagenUrl` vacío, y sube la imagen con `POST /api/admin/escenas/{id}/imagen`. El servidor la reduce a 4096x2048, genera la versión de 1024x512 y borra los metadatos EXIF; guarda las dos rutas.
- **Carpeta** es opcional. Si la dejas vacía (o con el `string` que pone Swagger) se usa la carpeta por defecto; si la indicas debe ser una de `panoramas`, `mapas`, `medios`, `imagenes`, `videos` o `audios`.

Un medio también puede apuntar a una URL externa (`https://...`) creándolo con `POST /api/admin/medios`; esa URL se entrega tal cual, sin firmar.

## Migraciones de base de datos

Antes de ejecutar las migraciones, verifica que:

- La instancia de base de datos esté disponible.
- La cadena de conexión sea correcta.
- Las credenciales tengan los permisos necesarios.
- El proveedor configurado en Entity Framework Core coincida con la base de datos.

Si el proyecto utiliza migraciones de EF Core, ejecuta desde `services/api`:

```powershell
dotnet ef database update
```

Si la herramienta de EF Core no está instalada:

```powershell
dotnet tool install --global dotnet-ef
```

Si ya está instalada, puedes actualizarla cuando sea necesario:

```powershell
dotnet tool update --global dotnet-ef
```

> Ejecuta `database update` únicamente contra la base de datos prevista para tu entorno. No generes ni apliques migraciones sin revisar previamente el estado del esquema y las instrucciones del equipo.

## Documentación

La documentación técnica y operativa está centralizada en el directorio `docs/`.

| Documento | Descripción |
|---|---|
| [`docs/GUIA_DESARROLLO.md`](docs/GUIA_DESARROLLO.md) | Instalación, ejecución, configuración, contrato HTTP, pruebas, Git y continuidad del proyecto. |
| [`docs/arquitectura.md`](docs/arquitectura.md) | Arquitectura del sistema, seguridad y cumplimiento. |
| [`docs/utb-tour-inmersivo-mvp.md`](docs/utb-tour-inmersivo-mvp.md) | Alcance funcional y requisitos del producto mínimo viable. |
| [`PRODUCT.md`](PRODUCT.md) | Usuarios, principios y estado actual del producto. |
| `docs/SRSIEEE830TourVirtualUTBv3.1.pdf` | Especificación de requisitos de software. |

Se recomienda leer primero `docs/GUIA_DESARROLLO.md`, ya que contiene las instrucciones operativas para trabajar con el proyecto.

## Seguridad

Para proteger el código y la infraestructura:

- No incluyas contraseñas, claves API ni credenciales en el repositorio.
- Utiliza `dotnet user-secrets` para las credenciales de desarrollo local.
- Mantén los archivos de configuración sensibles fuera del control de versiones.
- No publiques documentos internos ni material institucional sin autorización.
- No expongas credenciales de producción en ejemplos, capturas de pantalla o registros.
- Verifica los permisos y la configuración de acceso de la API, la base de datos y el almacenamiento de objetos.

## Flujo de trabajo con Git

Antes de comenzar a trabajar, verifica la rama y el estado del repositorio:

```powershell
git branch --show-current
git status
```

Actualiza tu rama siguiendo las instrucciones del equipo y evita sobrescribir cambios de otros colaboradores.

Buenas prácticas:

1. Trabaja en la rama asignada a tu tarea.
2. Realiza cambios pequeños y con un propósito claro.
3. Ejecuta las pruebas correspondientes antes de confirmar los cambios.
4. Utiliza mensajes de commit descriptivos.
5. Revisa los cambios antes de crear un commit o una solicitud de integración.

Ejemplo:

```powershell
git diff
git status
git add .
git commit -m "docs: mejorar README del proyecto"
```

## Estado del proyecto

El alcance vigente, las funcionalidades implementadas y las tareas pendientes deben consultarse en [`PRODUCT.md`](PRODUCT.md) y en la documentación técnica del repositorio.

---

**UTB Tour Virtual** — Proyecto de recorrido virtual inmersivo de la Universidad Tecnológica de Bolívar.
