# API de UTB Tour Virtual

Este directorio contiene la API ASP.NET Core que llegó desde la rama
`backend`. La importación se hace bajo `services/api/` para que el repositorio
mantenga una raíz única junto a `apps/mobile`, `packages` y `supabase`.

## Estado de integración

La API expone el contenido que consume la aplicación móvil mediante
`RepositorioContenido`, con los mismos modelos tipados y campos que usaba la
implementación anterior sobre `pois`, `escenas`, `hotspots`, `medios` y
`rutas`.

La API importada usa otro modelo (`Lugar`, `Escena`, `Hotspot`) y otra
configuración de persistencia. No se debe conectar el móvil a estos endpoints
hasta completar el contrato y la migración de datos.

La configuración actual usa SQL Server porque las migraciones y el paquete
instalado están generados para SQL Server. La llamada anterior a `UseNpgsql`
era inconsistente y ya fue corregida. Esto no decide la migración futura del
móvil a Firestore.

## Bloqueadores técnicos detectados

- El proyecto declara .NET 9 con paquetes Entity Framework Core 8; el equipo
  backend debe alinear ambas versiones antes de producción.
- La configuración local usa LocalDB/SQL Server; cada desarrollador debe
  sustituirla por su entorno mediante user-secrets o variables de entorno.
- Las migraciones fueron generadas para el modelo anterior y no corresponden al
  esquema Supabase actual.
- La rama original incluía artefactos `.vs/`, `bin/`, `obj/` e imágenes de
  prueba. Los artefactos no se importaron y las imágenes quedan excluidas por
  `.gitignore`.

Los puntos pendientes se deben resolver en una rama de trabajo del backend, no
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

En Development, al arrancar se crea el esquema SQL Server vacío y se cargan
los cinco POI, cinco escenas, seis hotspots, cinco audios y tres rutas que
existían en `supabase/seed.sql`. Esto permite probar el flujo completo sin
copiar credenciales de Supabase ni medios institucionales al repositorio.
Las rutas de medios son relativas y deben existir en el almacenamiento local
autorizado del equipo.

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
deben añadirse autenticación, autorización, auditoría y manejo de errores. La
subida ya tiene una validación inicial de formato y tamaño, y CORS se configura
con `Cors:AllowedOrigins`; una lista vacía conserva el comportamiento abierto
solo para desarrollo local y hace fallar el arranque fuera de Development si no
se configura explícitamente.

## Plan para conectarla con el móvil

1. Acordar si SQL Server será la persistencia del backend o si posteriormente se
   ejecutará la migración a Firestore definida por el SRS.
2. Mantener el contrato HTTP actual, compatible con los modelos de Flutter.
3. Mantener el mapeo `Lugar/Escena/Hotspot` a `Poi/Escena/Hotspot/Medio/Ruta`, sin perder
   audiencia, orden, escena principal ni coordenadas calibradas.
4. Reemplazar la carga directa o implementar un adaptador de repositorio; no
   duplicar consultas en las pantallas.
5. Reproducir las garantías de RLS: audiencia, sesión anónima, auditoría y
   retención de eventos.
6. Añadir pruebas de contrato, integración y una migración de datos antes de
   cambiar el proveedor móvil.
