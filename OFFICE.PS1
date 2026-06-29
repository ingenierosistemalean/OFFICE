taskkill /IM explorer.exe /F
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
    Write-Host "  Progreso: [" -NoNewline
    Write-Host "$completed" -ForegroundColor Green -NoNewline
    Write-Host "$remainder" -ForegroundColor DarkGray -NoNewline
    Write-Host "] $percent%`n" -ForegroundColor White
}

Show-ProgressBar 5 "Preparando entorno..."
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Show-ProgressBar 15 "Limpiando directorios..."
if (Test-Path $desktopPath) {
    Remove-Item $desktopPath -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $desktopPath | Out-Null
Set-Location -Path $desktopPath

Show-ProgressBar 30 "Descargando configuracion..."
$xmlUrl = "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml"
Invoke-WebRequest -Uri $xmlUrl -OutFile (Join-Path $desktopPath "Configuration.xml")

Show-ProgressBar 45 "Descargando herramientas..."
$odtUrl = "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe"
$odtExe = Join-Path $desktopPath "officedeploymenttool.exe"
Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe

Show-ProgressBar 60 "Extrayendo archivos..."
Start-Process -FilePath $odtExe -ArgumentList "/extract:`"$desktopPath`" /quiet" -Wait
if (Test-Path $odtExe) { Remove-Item $odtExe -Force }
Get-ChildItem -Path $desktopPath -Filter "*Office365*" | Remove-Item -Force -ErrorAction SilentlyContinue

Show-ProgressBar 75 "Instalando suite..."
Start-Process -FilePath "./setup.exe" -ArgumentList "/configure Configuration.xml" -Wait

Show-ProgressBar 90 "Configurando tareas..."
$OfficeCmd = 'cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act'
schtasks /create /tn "OfficeAutoRenovacion" /tr "$OfficeCmd" /sc onstart /ru "SYSTEM" /f >$null 2>&1
schtasks /create /tn "OfficeAutoRenovacionDiaria" /tr "$OfficeCmd" /sc daily /st 12:00 /ru "SYSTEM" /f >$null 2>&1

Show-ProgressBar 98 "Finalizando..."
Set-Location -Path $env:USERPROFILE
if (Test-Path $desktopPath) {
    Remove-Item $desktopPath -Recurse -Force -ErrorAction SilentlyContinue
}

Start-Process "explorer.exe"
Show-ProgressBar 100 "¡PROCESO COMPLETADO!"

Write-Host " ========================================================" -ForegroundColor Green
Write-Host "   SISTEMA ACTIVO Y LISTO" -ForegroundColor Green
Write-Host " ========================================================`n" -ForegroundColor Green
Start-Sleep -Seconds 5
