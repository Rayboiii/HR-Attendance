@echo off
REM Run the KaizenHR app on a USB-connected Android device.
REM Re-creates the adb reverse tunnel (port 5294 -> PC backend), then launches the app.

set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe

echo Setting up adb reverse tunnel (phone localhost:5294 -> PC localhost:5294)...
"%ADB%" reverse tcp:5294 tcp:5294
if errorlevel 1 (
  echo.
  echo [!] adb reverse failed. Is the phone plugged in with USB debugging on?
  echo     Check with: "%ADB%" devices
  pause
  exit /b 1
)

echo Tunnel ready. Launching app...
flutter run
