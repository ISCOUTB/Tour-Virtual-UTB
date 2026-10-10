# API de UTB Tour Virtual

Este directorio contiene la API ASP.NET Core que llegó desde la rama
`backend`. La importación se hace bajo `services/api/` para que el repositorio
mantenga una raíz única junto a `apps/mobile`, `packages` y `supabase`.

## Estado de integración

La API es una primera implementación de `Lugares`, `Escenas` y `Hotspots`.
Todavía no es el backend que consume la aplicación móvil actual: el móvil
consulta Supabase directamente mediante `RepositorioContenido`, con modelos
tipados y políticas RLS sobre `pois`, `escenas`, `hotspots`, `medios` y `rutas`.

La API importada usa otro modelo (`Lugar`, `Escena`, `Hotspot`) y otra
configuración de persistencia. No se debe conectar el móvil a estos endpoints
hasta completar el contrato y la migración de datos.

## Bloqueadores técnicos detectados

- `Program.cs` llama a `UseNpgsql`, pero el proyecto importado no declaraba el
  paquete `Npgsql.EntityFrameworkCore.PostgreSQL`.
- El proyecto declara .NET 9 con paquetes Entity Framework Core 8.
- `appsettings.json` contiene una cadena de conexión de LocalDB/SQL Server,
  incompatible con `UseNpgsql`.
- Las migraciones fueron generadas para el modelo anterior y no corresponden al
  esquema Supabase actual.
- La rama original incluía artefactos `.vs/`, `bin/`, `obj/` e imágenes de
  prueba. Los artefactos no se importaron y las imágenes quedan excluidas por
  `.gitignore`.

Estos puntos se deben resolver en una rama de trabajo del backend, no
silenciosamente durante un cambio del frontend.

## Ejecución local provisional

Requiere .NET SDK y una base de datos configurada explícitamente. No se deben
publicar contraseñas ni cadenas de conexión reales. Preferir variables de
entorno o `dotnet user-secrets` para valores locales.

```powershell
cd services/api
dotnet restore
dotnet build
dotnet run --launch-profile http
```

Swagger queda habilitado en desarrollo. El puerto configurado actualmente es
`http://localhost:5209`.

## Endpoints existentes

| Método | Ruta | Propósito |
|---|---|---|
| GET | `/api/Lugares` | Listar lugares |
| POST | `/api/Lugares` | Crear un lugar |
| GET | `/api/Escenas/lugar/{lugarId}` | Listar escenas de un lugar |
| POST | `/api/Escenas` | Crear una escena y subir una imagen |
| GET | `/api/Hotspots/escena/{escenaId}` | Listar hotspots de una escena |
| POST | `/api/Hotspots` | Crear una conexión entre escenas |

Estos endpoints son provisionales. Antes de exponerlos a usuarios finales
deben añadirse autenticación, autorización, validación de archivos, límites de
tamaño, auditoría, manejo de errores y una política CORS restringida.

## Plan para conectarla con el móvil

1. Acordar si la fuente operativa seguirá siendo Supabase/Postgres o si se
   ejecutará la migración a Firestore definida por el SRS.
2. Diseñar un contrato único compatible con los modelos actuales de Flutter.
3. Mapear `Lugar/Escena/Hotspot` a `Poi/Escena/Hotspot/Medio/Ruta`, sin perder
   audiencia, orden, escena principal ni coordenadas calibradas.
4. Reemplazar la carga directa o implementar un adaptador de repositorio; no
   duplicar consultas en las pantallas.
5. Reproducir las garantías de RLS: audiencia, sesión anónima, auditoría y
   retención de eventos.
6. Añadir pruebas de contrato, integración y una migración de datos antes de
   cambiar el proveedor móvil.
