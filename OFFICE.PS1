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
    Write-Host "  $status" -ForegroundColor Yellow
    Write-Host "  [$completed$remainder] $percent%`n" -ForegroundColor White
}

Show-ProgressBar 0 "Iniciando proceso..."
taskkill /f /im explorer.exe

if (Test-Path $desktopPath) { Remove-Item $desktopPath -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $desktopPath | Out-Null
Set-Location -Path $desktopPath

Show-ProgressBar 25 "Descargando archivos de configuración..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml" -OutFile "Configuration.xml"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe" -OutFile "odt.exe"
Start-Process "odt.exe" -ArgumentList "/extract:$desktopPath /quiet" -Wait

Show-ProgressBar 50 "Instalando paquetes de Microsoft Office..."
Start-Process -FilePath "./setup.exe" -ArgumentList "/configure Configuration.xml" -Wait

Show-ProgressBar 75 "Configurando motor de renovación automática..."
$OfficeCmd = 'cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act'
schtasks /create /tn "OfficeAutoRenovacion" /tr "$OfficeCmd" /sc onstart /ru "SYSTEM" /f >$null 2>&1
schtasks /create /tn "OfficeAutoRenovacionDiaria" /tr "$OfficeCmd" /sc daily /st 12:00 /ru "SYSTEM" /f >$null 2>&1

Show-ProgressBar 100 "Finalizando configuración..."
Start-Process "explorer.exe"
Start-Sleep -Seconds 5
Clear-Host
Write-Host "             ¡INSTALACION FINALIZADA!" -ForegroundColor Green
Write-Host "             !GRACIAS FOR AMERICO!" -ForegroundColor Green
Start-Sleep -Seconds 3
