# Panel de administración (Flutter web)

Panel para administrar el contenido del Tour Virtual UTB: POIs, ubicación en
el mapa, multimedia (360°, fotos, video, audio con idioma y subtítulos),
métricas, actividad y administradores. Habla con la API de `services/api`.

## Requisitos

- Flutter 3.41 o superior (Dart 3.11), la misma versión del CI.
- La API corriendo en `http://localhost:5209` (ver el README de `services/api`).
- Una cuenta con rol `admin` en la tabla `perfiles` de Supabase.

## Cómo correrlo

1. Levantar la API:

   ```
   cd services/api
   dotnet run --launch-profile http
   ```

2. Correr el panel contra la API real, con inicio de sesión de Supabase:

   ```
   cd apps/admin_flutter
   flutter pub get
   flutter run -d chrome --dart-define=USE_MOCK=false --dart-define=SUPABASE_ANON_KEY=<publishable key>
   ```

   La publishable key está en Supabase → Project Settings → API Keys. Es
   pública (va en el navegador), pero no se guarda en el repo. Nunca usar la
   `secret` ni la `service_role` aquí.

## Dependencias y `pubspec.lock`

El `pubspec.lock` se genera con **Flutter 3.41** (Dart 3.11), la versión más
vieja del equipo y la que usa el CI. El CI corre `flutter pub get
--enforce-lockfile`: si el lock se resolvió con un Flutter más nuevo, falla.

Correr el panel o `flutter pub get` con un Flutter más nuevo no cambia el lock.
Para **agregar o actualizar paquetes** (`pub add`, `pub upgrade`), usar Flutter
3.41. Se puede tener aparte, sin tocar el Flutter de siempre:

```
C:\dev\flutter-3.41\flutter\bin\flutter.bat pub add <paquete>
```

Después, revisar que el final del lock diga `dart: ">=3.11.0 <4.0.0"`.

## Parámetros (`--dart-define`)

| Parámetro | Por defecto | Para qué |
|---|---|---|
| `USE_MOCK` | `true` | `true`: datos de ejemplo, sin API. `false`: API real. |
| `API_BASE_URL` | `http://localhost:5209` | Dirección de la API. |
| `SUPABASE_ANON_KEY` | vacío | Publishable key. Sin ella, el login es simulado. |
| `SUPABASE_URL` | proyecto del equipo | Solo si se usa otro proyecto de Supabase. |
| `BACKEND_CAMPOS_NUEVOS` | `true` | Editar lat/lng, idioma, subtítulos y texto alternativo. |
| `LUGAR_ID` | `1` | Campus que administra el panel. |

## Modos

- **Maqueta** (`USE_MOCK=true`): no necesita la API. Cualquier correo
  `@utb.edu.co` y cualquier contraseña entran. Útil para trabajar el diseño.
- **API real sin clave** (`USE_MOCK=false`, sin `SUPABASE_ANON_KEY`): datos
  reales, login simulado. En Development la API deja pasar sin token.
- **API real con login** (`USE_MOCK=false` + clave): inicio de sesión con
  Supabase; la API valida el token y exige rol `admin`.

## Subida de archivos

Las subidas pasan por la API, que las guarda en Supabase Storage. La API
necesita sus secretos `SupabaseS3:ServiceUrl`, `SupabaseS3:AccessKey` y
`SupabaseS3:SecretKey` (`dotnet user-secrets set ...`); sin ellos, leer
funciona pero subir falla.

Límites: imagen 5 MB, audio 10 MB, video 50 MB, panorámica 360° 50 MB (la API
la reduce a 4096x2048). El tope real es 50 MB por archivo, el máximo del plan
gratis de Supabase.

Reglas del SRS que aplica el panel: ninguna imagen sin texto alternativo y
ninguna narración (audio o video) sin subtítulos `.vtt`; una sola narración
por idioma en cada POI.
