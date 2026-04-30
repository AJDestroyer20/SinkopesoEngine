@echo off
title Compile
color 02
cls
setlocal EnableExtensions EnableDelayedExpansion


echo Select target
echo.
echo [W] Windows
echo [M] MacOS
echo [L] Linux
echo [A] Android
echo [I] iOS
echo.

choice /c WMLAI /m "Choose a platform"

if errorlevel 5 goto ios
if errorlevel 4 goto android
if errorlevel 3 goto linux
if errorlevel 2 goto mac
if errorlevel 1 goto windows

:windows
echo Compiling for Windows...
lime test windows || goto fail
goto end

:mac
echo Compiling for MacOS...
lime test mac || goto fail
goto end

:linux
echo Compiling for Linux...
lime test linux || goto fail
goto end

:android
echo Compiling for Android...
lime test android || goto fail
goto end

:ios
echo Compiling for iOS...
lime test ios || goto fail
goto end

:end
echo.
echo Build completed successfully.
pause
exit /b 0

:fail
echo.
echo Build failed. Check the output above for the first error and fix incrementally.
pause
exit /b 1