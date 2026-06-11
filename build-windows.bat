@echo off
setlocal

set "LAZBUILD="

if exist "%ProgramFiles%\Lazarus\lazbuild.exe" (
  set "LAZBUILD=%ProgramFiles%\Lazarus\lazbuild.exe"
)

if not defined LAZBUILD if exist "%ProgramFiles(x86)%\Lazarus\lazbuild.exe" (
  set "LAZBUILD=%ProgramFiles(x86)%\Lazarus\lazbuild.exe"
)

if not defined LAZBUILD (
  set "LAZBUILD=lazbuild.exe"
)

echo Building em-marine for Windows using Win32 widgetset...
"%LAZBUILD%" --ws=win32 em_marine.lpi

if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

echo Build completed successfully.
endlocal
