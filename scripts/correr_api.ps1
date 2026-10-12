# Levanta la API .NET en http://localhost:5209 y, si hay un teléfono Android
# conectado por USB, le reenvía ese puerto para que la app lo alcance como
# http://127.0.0.1:5209 sin depender de la wifi ni del firewall.
#
# Requisitos (una sola vez por equipo):
#   - SDK de .NET 10. Si no está en el sistema, se instala solo para el
#     usuario en %USERPROFILE%\.dotnet:
#       & ([scriptblock]::Create((iwr https://dot.net/v1/dotnet-install.ps1 -UseBasicParsing))) -Channel 10.0 -InstallDir "$env:USERPROFILE\.dotnet" -NoPath
#   - Secretos de desarrollo (los da el equipo de backend), en services/api:
#       dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<cadena del pooler de Supabase>"
#       dotnet user-secrets set "SupabaseS3:ServiceUrl" "https://<proyecto>.supabase.co/storage/v1/s3"
#       dotnet user-secrets set "SupabaseS3:AccessKey" "<...>"
#       dotnet user-secrets set "SupabaseS3:SecretKey" "<...>"
#     La base de Supabase solo tiene IPv6 en su host directo: hay que usar el
#     pooler (aws-1-<región>.pooler.supabase.com, usuario postgres.<proyecto>)
#     en modo sesión, puerto 5432. En el 6543 (modo transacción) las consultas
#     de Npgsql se quedan colgadas.
#
# Uso: .\scripts\correr_api.ps1   (Ctrl+C para detenerla)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot

$dotnetUsuario = Join-Path $env:USERPROFILE '.dotnet'
if (Test-Path (Join-Path $dotnetUsuario 'dotnet.exe')) {
    $env:DOTNET_ROOT = $dotnetUsuario
    $env:Path = "$dotnetUsuario;$env:Path"
}

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (Test-Path $adb) {
    $telefonos = & $adb devices | Select-String -Pattern "`tdevice$"
    if ($telefonos) {
        & $adb reverse tcp:5209 tcp:5209 | Out-Null
        Write-Host 'Telefono conectado: su puerto 5209 apunta a esta API.'
    }
}

Set-Location (Join-Path $raiz 'services\api')
dotnet run --launch-profile http
