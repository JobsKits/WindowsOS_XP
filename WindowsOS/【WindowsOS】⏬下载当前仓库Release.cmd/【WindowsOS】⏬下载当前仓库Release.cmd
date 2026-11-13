@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1" %*
set "jobs_exit=%errorlevel%"
if not "%jobs_exit%"=="0" echo Failed. Exit code: %jobs_exit%
if "%~1"=="" pause
exit /b %jobs_exit%
