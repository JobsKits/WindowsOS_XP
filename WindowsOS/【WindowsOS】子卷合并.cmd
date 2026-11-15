@echo off
setlocal DisableDelayedExpansion
rem Resolve the packaged launcher beside this shortcut, independent of the current directory.
set "jobs_target=%~dp0%~n0\%~nx0"
if not exist "%jobs_target%" (
    echo Launcher missing: "%jobs_target%"
    if "%~1"=="" pause
    exit /b 1
)
rem Tail-call the implementation; it owns pause and the final exit code.
"%jobs_target%" %*
