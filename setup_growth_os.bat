@echo off
title GROWTH OS - Android Build & Setup Assistant
color 0B

echo ========================================================
echo        GROWTH OS - Production Android Setup
echo ========================================================
echo.

where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Flutter SDK is not detected in your system PATH.
    echo.
    echo Please ensure Flutter SDK 3.x is installed:
    echo 1. Download Flutter from https://docs.flutter.dev/get-started/install/windows
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to your System Environment PATH
    echo.
    echo Once added, re-run this script to build your APK and App Bundle.
    echo ========================================================
    pause
    exit /b 1
)

echo [*] Flutter detected! Fetching dependencies...
cd /d "%~dp0"
call flutter pub get

echo.
echo [*] Analyzing codebase...
call flutter analyze

echo.
echo ========================================================
echo What would you like to build?
echo 1. Debug APK (for immediate local device testing)
echo 2. Release APK (for sideloading / testing release performance)
echo 3. Android App Bundle (.aab) (For Google Play Store publication)
echo 4. Exit
echo ========================================================
set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo [*] Building Debug APK...
    call flutter build apk --debug
    echo.
    echo [OK] APK generated at: build\app\outputs\flutter-apk\app-debug.apk
) else if "%choice%"=="2" (
    echo [*] Building Release APK...
    call flutter build apk --release
    echo.
    echo [OK] Release APK generated at: build\app\outputs\flutter-apk\app-release.apk
) else if "%choice%"=="3" (
    echo [*] Building Google Play Android App Bundle (.aab)...
    call flutter build appbundle --release
    echo.
    echo [OK] Play Store Bundle generated at: build\app\outputs\bundle\release\app-release.aab
) else (
    echo Exiting.
)

pause

