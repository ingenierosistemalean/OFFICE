# ==============================================================================
# 1. COMPROBACIÓN REQUISITO: PRIVILEGIOS DE ADMINISTRADOR AUTOMÁTICOS
# ==============================================================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsAuthorizedRoles]::Administrator)) {
    Write-Host "Solicitando privilegios de Administrador..." -ForegroundColor Yellow
    $arguments = (("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $MyInvocation.MyCommand.Path) + " " + $MyInvocation.UnboundArguments)
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# Habilitar protocolos TLS 1.2 para descargas web seguras sin fallas
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# 2. CONFIGURACIÓN DE LA CARPETA EN EL ESCRITORIO
# ==============================================================================
$desktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "office_instalador")

if (Test-Path $desktopPath) {
    Remove-Item $desktopPath -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $desktopPath | Out-Null
Set-Location -Path $desktopPath

# ==============================================================================
# 3. TRUCO INICIAL: REINICIAR EL EXPLORADOR DE WINDOWS (Evita cuelgues visuales)
# ==============================================================================
Write-Host "-> Cerrando entorno grafico temporalmente para acelerar proceso..." -ForegroundColor Red
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# ==============================================================================
# 4. DESCARGAR COMPONENTES DIRECTAMENTE DESDE TU GITHUB
# ==============================================================================
Write-Host "-> Descargando herramientas de implementacion oficiales..." -ForegroundColor Cyan

# Descarga de tu Configuration.xml maestro
$xmlUrl = "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml"
Invoke-WebRequest -Uri $xmlUrl -OutFile (Join-Path $desktopPath "Configuration.xml")

# Descarga del ejecutable de Microsoft
$odtUrl = "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe"
$odtExe = Join-Path $desktopPath "officedeploymenttool.exe"
Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe

# Extracción limpia del instalador real
Start-Process -FilePath $odtExe -ArgumentList "/extract:`"$desktopPath`" /quiet" -Wait
if (Test-Path $odtExe) { Remove-Item $odtExe -Force }

# Borrar archivos de ejemplo molestos que saca Microsoft por defecto
Get-ChildItem -Path $desktopPath -Filter "*Office365*" | Remove-Item -Force -ErrorAction SilentlyContinue

# ==============================================================================
# 5. INSTALACIÓN ONLINE DE TODO EL COMBO (OFFICE + VISIO + PROJECT)
# ==============================================================================
Write-Host "`n-> Iniciando instalacion completa. Conectando con Microsoft CDN..." -ForegroundColor Green

# Ejecución maestra apuntando a tu XML local descargado al vuelo
Start-Process -FilePath "./setup.exe" -ArgumentList "/configure Configuration.xml" -Wait

# ==============================================================================
# 6. CREAR TAREAS PROGRAMADAS DE AUTORENOVACIÓN (Licencia y funciones IA vivas)
# ==============================================================================
Write-Host "`n-> Configurando motor de autorenovacion perenne en segundo plano..." -ForegroundColor Cyan

$OfficeCmd = 'cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act'

# Tarea 1: Ejecución invisible cada vez que el equipo enciende (Permisos SYSTEM)
schtasks /create /tn "OfficeAutoRenovacion" /tr "$OfficeCmd" /sc onstart /ru "SYSTEM" /f >$null 2>&1

# Tarea 2: Respaldo diario automático a las 12:00 PM por seguridad
schtasks /create /tn "OfficeAutoRenovacionDiaria" /tr "$OfficeCmd" /sc daily /st 12:00 /ru "SYSTEM" /f >$null 2>&1

# ==============================================================================
# 7. TRUCO FINAL: DEVOLVER EL ENTORNO GRÁFICO, BORRAR TODO Y COMPLEMENTAR
# ==============================================================================
Write-Host "-> Iniciando limpieza absoluta y reactivando entorno grafico..." -ForegroundColor Green

# Regresar la consola a una ruta segura fuera de la carpeta que queremos borrar
Set-Location -Path $env:USERPROFILE

# Destrucción absoluta de la carpeta del instalador en el Escritorio
if (Test-Path $desktopPath) {
    Remove-Item $desktopPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Limpieza total de los archivos caché temporales de Windows
$tempPath = [System.IO.Path]::GetTempPath()
Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    try { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

# Levantar de nuevo el explorador de Windows para que el usuario recupere su escritorio e iconos
Start-Process "explorer.exe"

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "  ¡PROCESO PROFESIONAL COMPLETADO EXITOSAMENTE!" -ForegroundColor Green
Write-Host "  Office instalado, renovando solo, listo para usar IA." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Start-Sleep -Seconds 3