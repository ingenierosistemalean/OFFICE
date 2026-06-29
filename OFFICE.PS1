# Iniciar Instalacion Profesional
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$work = "$env:USERPROFILE\Desktop\office_instalador"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -Path $work -ItemType Directory | Out-Null
Set-Location $work

# Descarga de herramientas
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml" -OutFile "Configuration.xml"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe" -OutFile "odt.exe"
Start-Process "odt.exe" -ArgumentList "/extract:$work /quiet" -Wait

# Ocultar Escritorio
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

# Instalacion
Start-Process "setup.exe" -ArgumentList "/configure Configuration.xml" -Wait

# Tareas
$cmd = 'cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act'
schtasks /create /tn "OfficeRenov" /tr $cmd /sc onstart /ru "SYSTEM" /f | Out-Null

# Limpieza y Regreso
Set-Location $env:USERPROFILE
Remove-Item $work -Recurse -Force
Start-Process "explorer.exe"
Write-Host "Proceso Completado Exitosamente" -ForegroundColor Green
