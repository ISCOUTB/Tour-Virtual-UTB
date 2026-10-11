# UTB Tour Virtual

Recorrido virtual inmersivo del campus de la Universidad Tecnológica de
Bolívar. Esta rama contiene la aplicación Flutter y la API ASP.NET Core que la
alimenta mediante SQL Server.

## Empezar

La documentación operativa está consolidada en
[`docs/GUIA_DESARROLLO.md`](docs/GUIA_DESARROLLO.md). Allí están la instalación,
ejecución, configuración del backend, contrato HTTP, pruebas, reglas Git y
roadmap de continuidad.

Resumen rápido:

```powershell
git switch integration/backend-unification

cd services/api
dotnet restore
dotnet run --launch-profile http

# En otra terminal:
cd apps/mobile
flutter pub get
flutter run -d windows
```

La API local usa `http://localhost:5209` y el móvil usa por defecto
`http://127.0.0.1:5209`.

## Estructura

```text
apps/mobile/          Aplicación Flutter
services/api/         API ASP.NET Core + EF Core 9 + SQL Server
packages/contracts/   Contrato OpenAPI administrativo
supabase/             Esquema histórico y datos de referencia
docs/                 Requisitos, arquitectura y guía operativa
```
## Configuración del Entorno Local (Backend)

Este proyecto utiliza `dotnet user-secrets` para manejar las credenciales de conexión a PostgreSQL y Supabase S3 de forma segura, evitando exponerlas en el código fuente.

dotnet user-secrets set "SupabaseS3:ServiceUrl" "https://[proyecto].supabase.co/storage/v1/s3"
dotnet user-secrets set "SupabaseS3:AccessKey" "[AQUI_EL_ACCESS_KEY]"
dotnet user-secrets set "SupabaseS3:SecretKey" "[AQUI_EL_SECRET_KEY]"
ConnectionStrings:DefaultConnection = "[AQUI_EL_SECRET_KEY]"

Para verificar que todo quedó guardado correctamente en tu máquina, ejecuta:
dotnet user-secrets list

Una vez configurados los secretos, aplica las migraciones de Entity Framework Core para crear las tablas en tu base de datos:
dotnet ef database update

### Pasos para configurar los secretos:

1. Abre una terminal y ubícate en la raíz del proyecto backend (donde está el archivo `.csproj`).
2. Inicializa la herramienta de secretos (si no lo has hecho antes):
   ```bash
   dotnet user-secrets init

## Documentación de referencia

- [`docs/GUIA_DESARROLLO.md`](docs/GUIA_DESARROLLO.md): manual único para
  desarrollar, probar, ejecutar y continuar el proyecto.
- [`docs/arquitectura.md`](docs/arquitectura.md): arquitectura, seguridad y
  cumplimiento.
- [`docs/utb-tour-inmersivo-mvp.md`](docs/utb-tour-inmersivo-mvp.md): alcance
  funcional del MVP.
- [`PRODUCT.md`](PRODUCT.md): usuarios, principios y estado del producto.
- `docs/SRSIEEE830TourVirtualUTBv3.1.pdf`: requisitos funcionales definitivos.

Los medios institucionales, secretos y documentos de trabajo no se publican
con el código.
