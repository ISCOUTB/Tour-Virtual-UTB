# Tour Virtual UTB - API Backend

Backend del proyecto **Tour Virtual UTB**, desarrollado con **ASP.NET Core Web API y .NET 8**, encargado de gestionar los lugares del campus, las escenas panorámicas de 360° y los puntos interactivos (*hotspots*) utilizados por la aplicación móvil desarrollada en Flutter.

La API permite consultar lugares, registrar escenas fotográficas y establecer conexiones interactivas entre diferentes ubicaciones para facilitar la navegación dentro del tour virtual.

---

## 🛠️ Tecnologías utilizadas

- **C# y .NET 8:** desarrollo del backend.
- **ASP.NET Core Web API:** creación de endpoints REST.
- **Entity Framework Core 8:** acceso y gestión de datos mediante un ORM.
- **Microsoft SQL Server:** sistema de gestión de base de datos relacional.
- **Swagger / OpenAPI:** documentación y pruebas de los endpoints.
- **wwwroot:** almacenamiento y publicación de archivos estáticos, como imágenes panorámicas.

---

## 📂 Arquitectura del proyecto

```text
TourVirtualUTB.Api/
│
├── Controllers/
│   ├── EscenasController.cs
│   ├── HotspotsController.cs
│   └── LugaresController.cs
│
├── Data/
│   └── TourDbContext.cs
│
├── DTOs/
│   └── EscenaCreateDto.cs
│
├── Models/
│   ├── Escena.cs
│   ├── Hotspot.cs
│   └── Lugar.cs
│
├── wwwroot/
│   └── images/
│
├── Program.cs
├── appsettings.json
└── TourVirtualUTB.Api.csproj
```

### Descripción de los directorios

| Directorio o archivo | Descripción |
|---|---|
| `Controllers/` | Contiene los controladores que exponen los endpoints REST. |
| `Data/` | Contiene el contexto de Entity Framework Core para interactuar con la base de datos. |
| `DTOs/` | Define los objetos utilizados para transferir información entre el cliente y la API. |
| `Models/` | Contiene las entidades que representan los datos del sistema. |
| `wwwroot/images/` | Almacena las imágenes y los recursos estáticos del tour virtual. |
| `Program.cs` | Configura los servicios, CORS, middlewares y el inicio de la aplicación. |
| `appsettings.json` | Contiene la configuración de la aplicación y la cadena de conexión. |

---

## 🚀 Endpoints de la API

La API está organizada en tres recursos principales: lugares, escenas y hotspots.

### 1. Lugares

Ruta base: `/api/Lugares`

| Método HTTP | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/Lugares` | Obtiene la lista de lugares o edificios registrados. |
| `POST` | `/api/Lugares` | Registra un nuevo lugar en el sistema. |

### 2. Escenas

Ruta base: `/api/Escenas`

| Método HTTP | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/Escenas/lugar/{lugarId}` | Obtiene las escenas asociadas a un lugar específico. |
| `POST` | `/api/Escenas` | Registra una nueva escena y permite cargar su imagen panorámica al servidor. |

### 3. Hotspots

Ruta base: `/api/Hotspots`

| Método HTTP | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/Hotspots/escena/{escenaId}` | Consulta los puntos interactivos asociados a una escena. |
| `POST` | `/api/Hotspots` | Registra un punto interactivo que conecta una escena de origen con una escena de destino. |

Los hotspots utilizan coordenadas de orientación como `Pitch` y `Yaw` para determinar la posición de los puntos interactivos dentro de las imágenes panorámicas de 360°.

> **Nota:** Los endpoints descritos corresponden a la estructura documentada del proyecto. Los métodos HTTP, las rutas y los parámetros definitivos deben coincidir con la implementación de los controladores.

---

## ⚙️ Instalación y configuración

### Requisitos previos

Antes de ejecutar el proyecto, asegúrate de tener instalado:

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0).
- Microsoft SQL Server, SQL Server Express o LocalDB.
- Git.
- Herramienta de línea de comandos `dotnet-ef`, si necesitas ejecutar migraciones de Entity Framework Core.

### 1. Clonar el repositorio

Clona el repositorio y accede al directorio del backend:

```bash
git clone <URL_DEL_REPOSITORIO>
cd TourVirtualUTB.Api
```

Si el backend se encuentra en una rama específica llamada `backend`, puedes cambiar a ella con:

```bash
git checkout backend
```

Ajusta la ruta del directorio según la estructura real del repositorio.

### 2. Configurar la conexión a base de datos

Abre el archivo `appsettings.json` y configura la cadena de conexión:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=TU_SERVIDOR;Database=TourVirtualUTB;Trusted_Connection=True;TrustServerCertificate=True"
  }
}
```

Reemplaza `TU_SERVIDOR` por el nombre de tu instancia de SQL Server.

Por ejemplo, para una instalación local con SQL Server Express:

```text
Server=.\SQLEXPRESS;Database=TourVirtualUTB;Trusted_Connection=True;TrustServerCertificate=True
```

**Importante:** utiliza la autenticación adecuada para tu entorno. No publiques contraseñas, credenciales ni cadenas de conexión sensibles en el repositorio.

### 3. Restaurar las dependencias

Desde el directorio que contiene el archivo `.csproj`, ejecuta:

```bash
dotnet restore
```

### 4. Aplicar las migraciones

Si el proyecto utiliza migraciones de Entity Framework Core y estas ya están creadas, instala la herramienta si todavía no la tienes:

```bash
dotnet tool install --global dotnet-ef
```

Si ya está instalada, puedes actualizarla según sea necesario:

```bash
dotnet tool update --global dotnet-ef
```

Después, aplica las migraciones:

```bash
dotnet ef database update
```

Si el contexto de base de datos o el proyecto de inicio se encuentran en proyectos diferentes, puede ser necesario especificarlos mediante `--project` y `--startup-project`.

Si el proyecto no utiliza migraciones, deberás crear o configurar la base de datos mediante el mecanismo definido en el repositorio.

### 5. Ejecutar la API

Inicia el backend con:

```bash
dotnet run
```

También puedes ejecutarlo en modo de desarrollo:

```bash
dotnet run --launch-profile https
```

Este último comando requiere que exista un perfil llamado `https` en `Properties/launchSettings.json`.

La aplicación mostrará en la consola las direcciones locales en las que está escuchando, por ejemplo:

```text
http://localhost:5000
https://localhost:7000
```

Las direcciones y los puertos son ilustrativos; utiliza los que indique la consola o el archivo `launchSettings.json`.

---

## 📖 Documentación con Swagger

Si Swagger está habilitado en el entorno de desarrollo, puedes utilizar su interfaz para consultar y probar los endpoints de la API.

Las rutas habituales son:

```text
https://localhost:<PUERTO_HTTPS>/swagger
http://localhost:<PUERTO_HTTP>/swagger
```

Sustituye el puerto por el correspondiente a tu configuración.

Desde Swagger puedes revisar los métodos disponibles, consultar sus parámetros y enviar solicitudes de prueba.

---

## 🔄 Funcionamiento general

El backend sirve como intermediario entre la aplicación móvil desarrollada en Flutter y la base de datos.

El flujo general es el siguiente:

1. La aplicación consulta los lugares disponibles.
2. El usuario selecciona un lugar del campus.
3. La aplicación solicita las escenas asociadas a ese lugar.
4. El backend proporciona la información de las escenas y sus imágenes panorámicas.
5. La aplicación consulta los hotspots de la escena actual.
6. El usuario selecciona un punto interactivo y navega hacia la escena de destino.

De esta manera, la API centraliza la gestión de la información necesaria para construir una experiencia de navegación virtual por las instalaciones de la Universidad Tecnológica de Bolívar (UTB).

---

## 🔐 Seguridad y buenas prácticas

- No almacenar credenciales reales en archivos de configuración versionados.
- Utilizar variables de entorno o mecanismos seguros de configuración para los secretos.
- Configurar CORS para permitir únicamente los orígenes que necesite la aplicación.
- Validar los datos recibidos en los endpoints antes de almacenarlos.
- Controlar el tipo y el tamaño de los archivos panorámicos que se cargan al servidor.
- Utilizar HTTPS en los entornos de despliegue.
- Mantener las dependencias de .NET y Entity Framework Core actualizadas dentro de las versiones compatibles.

---

## 👨‍💻 Autoría

**Proyecto:** Tour Virtual UTB  
**Backend:** ASP.NET Core Web API  
**Framework:** .NET 8  
**Base de datos:** Microsoft SQL Server  
**Cliente consumidor:** Aplicación móvil desarrollada en Flutter

Desarrollado como parte del proyecto Tour Virtual UTB.
