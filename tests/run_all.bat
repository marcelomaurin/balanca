@echo off
setlocal

set ROOT=%~dp0..
set OUT=%ROOT%\tests\bin

if not exist "%OUT%" mkdir "%OUT%"

call :run toledo_protocol_test || exit /b 1
call :run commands_test || exit /b 1
call :run config_test || exit /b 1
call :run api_json_test || exit /b 1
call :run protocol_factory_test || exit /b 1

echo OK - toda a suite passou
exit /b 0

:run
echo ==^> %1
fpc -Fu"%ROOT%\src\core" -Fu"%ROOT%\src\api" -Fu"%ROOT%\src" -Fu"%ROOT%\tests" -FE"%OUT%" "%ROOT%\tests\%1.pas"
if errorlevel 1 exit /b 1
"%OUT%\%1.exe"
if errorlevel 1 exit /b 1
exit /b 0
