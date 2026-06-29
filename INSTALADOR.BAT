@echo off
title Sistema de Implementacion Automatizado
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
set "WORK_DIR=%USERPROFILE%\Desktop\office_instalador"

if not exist "setup.exe" (
    if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
    cd /d "%WORK_DIR%"
)

cls
echo ========================================================
echo  INICIANDO CONFIGURACION DEL ENTORNO...
echo ========================================================
echo [■░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 5%%
if not exist "Configuration.xml" (
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/Configuration.xml' -OutFile 'Configuration.xml'"
)

cls
echo ========================================================
echo  DESCARGANDO RECURSOS ADICIONALES...
echo ========================================================
echo [■■■■■■░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 15%%
if not exist "setup.exe" (
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ingenierosistemalean/OFFICE/main/officedeploymenttool_20026-20112.exe' -OutFile 'odt.exe'"
    start /wait odt.exe /extract:"." /quiet
    del /f /q odt.exe >nul 2>&1
    del /f /q *Office365* >nul 2>&1
)

cls
echo ========================================================
echo  ESTABILIZANDO PROCESOS DE INTERFAZ...
echo ========================================================
echo [■■■■■■■■■■■■░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 30%%
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

cls
echo ========================================================
echo  DESPLEGANDO COMPONENTES COMPLETO DEL SISTEMA...
echo ========================================================
echo [■■■■■■■■■■■■■■■■■■■■■■■░░░░░░░░░░░░░░░░░] 60%%
setup.exe /configure Configuration.xml

cls
echo ========================================================
echo  ESTABLECIENDO AUTOMATIZACION DE MANTENIMIENTO...
echo ========================================================
echo [■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■░░░░░░░░] 80%%
set "OfficeCmd=cscript ^"C:\Program Files\Microsoft Office\Office16\ospp.vbs^" /act"
schtasks /create /tn "OfficeAutoRenovacion" /tr "%OfficeCmd%" /sc onstart /ru "SYSTEM" /f >nul 2>&1
schtasks /create /tn "OfficeAutoRenovacionDiaria" /tr "%OfficeCmd%" /sc daily /st 12:00 /ru "SYSTEM" /f >nul 2>&1

cls
echo ========================================================
echo  RESTAURANDO INTERFAZ Y ELIMINANDO RESIDUOS...
echo ========================================================
echo [■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■░░] 95%%
start explorer.exe

cd /d "%USERPROFILE%"
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%" >nul 2>&1
del /s /f /q "%temp%\*.*" >nul 2>&1

cls
echo ========================================================
echo  ¡IMPLEMENTACION PROFESIONAL REALIZADA CON EXITO!
echo ========================================================
echo [■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■] 100%%
echo.
timeout /t 4
exit
