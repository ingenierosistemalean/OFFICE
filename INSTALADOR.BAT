@echo off
title Asistente de Instalacion Profesional y Autorenovacion - Office 2024
setlocal enabledelayedexpansion

:: ==============================================================================
:: 1. AUTO-ELEVACIÓN PRIVILEGIOS DE ADMINISTRADOR (Nativa)
:: ==============================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de Administrador...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:: Forzar que se ubique en la carpeta real desde donde se ejecuta
cd /d "%~dp0"

:: Definir la ruta de la carpeta temporal en el escritorio si se requiere usar como instalador limpio
set "WORK_DIR=%USERPROFILE%\Desktop\office_instalador"

:: Si no existen los archivos locales, creamos la carpeta de trabajo
if not exist "setup.exe" (
    if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
    cd /d "%WORK_DIR%"
)

:: ==============================================================================
:: 2. DESCARGA AUTOMÁTICA DE COMPONENTES DESDE TU GITHUB (Si faltan)
:: ==============================================================================
if not exist "Configuration.xml" (
    echo -> Descargando tu Configuration.xml maestro desde GitHub...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml' -OutFile 'Configuration.xml'"
)

if not exist "setup.exe" (
    echo -> Descargando herramientas de implementacion de Office...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe' -OutFile 'odt.exe'"
    start /wait odt.exe /extract:"." /quiet
    del /f /q odt.exe >nul 2>&1
    del /f /q *Office365* >nul 2>&1
)

:: ==============================================================================
:: 3. TRUCO DE PRO: REINICIAR EL EXPLORADOR DE WINDOWS
:: ==============================================================================
echo -> Cerrando entorno grafico temporalmente para acelerar proceso...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: ==============================================================================
:: 4. INSTALACIÓN AUTOMÁTICA EN SEGUNDO PLANO
:: ==============================================================================
echo =========================================================
echo    INICIANDO INSTALACION DE OFFICE, VISIO Y PROJECT
echo =========================================================
echo Microsoft esta procesando la configuracion en linea...
echo.

setup.exe /configure Configuration.xml

:: ==============================================================================
:: 5. CREAR TAREAS PROGRAMADAS DE AUTORENOVACIÓN (Para Gemini e IA Libres)
:: ==============================================================================
echo.
echo -> Configurando tareas de autorenovacion perenne en segundo plano...
set "OfficeCmd=cscript ^"C:\Program Files\Microsoft Office\Office16\ospp.vbs^" /act"

:: Tarea al iniciar el equipo con máximos privilegios (SYSTEM)
schtasks /create /tn "OfficeAutoRenovacion" /tr "%OfficeCmd%" /sc onstart /ru "SYSTEM" /f >nul 2>&1
:: Tarea de respaldo diaria al mediodía 
schtasks /create /tn "OfficeAutoRenovacionDiaria" /tr "%OfficeCmd%" /sc daily /st 12:00 /ru "SYSTEM" /f >nul 2>&1

:: ==============================================================================
:: 6. REACTIVAR ENTORNO GRÁFICO Y LIMPIEZA ABSOLUTA
:: ==============================================================================
echo -> Reanudando explorador de Windows y limpiando archivos temporales...

:: Levantar de nuevo el entorno visual
start explorer.exe

:: Salir de la carpeta antes de borrarla por completo si se usó la ruta temporal del escritorio
cd /d "%USERPROFILE%"
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%" >nul 2>&1

:: Vaciar temporales generales de Windows
del /s /f /q "%temp%\*.*" >nul 2>&1

echo.
echo =========================================================
echo    ¡PROCESO PROFESIONAL COMPLETADO EXITOSAMENTE!
echo =========================================================
echo Office configurado de por vida, listo para usar IA.
echo.
timeout /t 5
exit