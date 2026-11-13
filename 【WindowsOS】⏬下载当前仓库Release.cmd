@echo off
setlocal DisableDelayedExpansion
rem Resolve the companion launcher from this file, independent of the current directory.
set "jobs_target=%~dp0WindowsOS\%~nx0\%~nx0"
if not exist "%jobs_target%" (
    echo Launcher missing: "%jobs_target%"
    if "%~1"=="" pause
    exit /b 1
)
rem Tail-call the implementation so percent signs in moved paths are not expanded twice.
"%jobs_target%" %*
