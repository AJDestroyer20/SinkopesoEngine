@echo off
setlocal
title AutoCommit - SinkopesoEngine
color 0A

echo =====================================================
echo   AUTOCOMMIT TOOL
echo =====================================================
echo.

for /f %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set CURRENT_BRANCH=%%i
if "%CURRENT_BRANCH%"=="" (
	echo [ERROR] No se pudo detectar la rama actual.
	pause
	exit /b 1
)

echo Rama actual: %CURRENT_BRANCH%
echo.
echo Agregando cambios...
git add -A

git diff --cached --quiet
if %errorlevel%==0 (
	echo.
	echo [INFO] No hay cambios para commitear.
	pause
	exit /b 0
)

set /p commitMessage=Nombre del commit (enter = auto):
if "%commitMessage%"=="" set commitMessage=chore: auto-commit %date% %time%

echo.
echo Commiteando...
git commit -m "%commitMessage%"
if errorlevel 1 (
	echo [ERROR] Fallo el commit.
	pause
	exit /b 1
)

echo.
echo Sincronizando con remoto (pull --rebase)...
git pull --rebase origin %CURRENT_BRANCH%
if errorlevel 1 (
	echo [ERROR] Fallo pull --rebase. Revisa conflictos.
	pause
	exit /b 1
)

echo.
echo Subiendo cambios...
git push origin %CURRENT_BRANCH%
if errorlevel 1 (
	echo [ERROR] Fallo push.
	pause
	exit /b 1
)

echo.
echo [OK] Commit y push completados.
pause
