$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = (("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $MyInvocation.MyCommand.Path) + " " + $MyInvocation.UnboundArguments)
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$desktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "office_instalador")

function Show-ProgressBar ($percent, $status) {
    $barLength = 40
    $completedLength = [math]::Min($barLength, [math]::Max(0, [int]($percent / 100 * $barLength)))
    $remainderLength = [math]::Max(0, $barLength - $completedLength)
    $completed = "█" * $completedLength
    $remainder = "░" * $remainderLength
    Clear-Host
    Write-Host "`n"
    Write-Host "  Estado: $status" -ForegroundColor Yellow
    Write-Host "  Progreso: [$completed$remainder] $percent%" -ForegroundColor White
}

# 1. Ocultar entorno grafico
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

# 2. Iniciar Proceso
Show-ProgressBar 0 "Iniciando despliegue de componentes..."
if (Test-Path $desktopPath) { Remove-Item $desktopPath -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $desktopPath | Out-Null
Set-Location -Path $desktopPath

# 3. Descarga
Show-ProgressBar 25 "Preparando archivos de instalacion..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml" -OutFile "Configuration.xml"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe" -OutFile "odt.exe"
Start-Process "odt.exe" -ArgumentList "/extract:$desktopPath /quiet" -Wait

# 4. Instalacion Real (La barra se queda en 50% mientras trabaja Microsoft)
Show-ProgressBar 50 "Instalando Microsoft Office (Este proceso puede tardar)..."
Start-Process -FilePath "./setup.exe" -ArgumentList "/configure Configuration.xml" -Wait

# 5. Activacion
Show-ProgressBar 75 "Configurando tareas de renovacion..."
$OfficeCmd = 'cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act'
schtasks /create /tn "OfficeAutoRenovacion" /tr "$OfficeCmd" /sc onstart /ru "SYSTEM" /f >$null 2>&1
schtasks /create /tn "OfficeAutoRenovacionDiaria" /tr "$OfficeCmd" /sc daily /st 12:00 /ru "SYSTEM" /f >$null 2>&1

# 6. Finalizacion y regreso del escritorio
Show-ProgressBar 100 "Limpiando y restaurando entorno..."
Start-Sleep -Seconds 3
Start-Process "explorer.exe"
exit
