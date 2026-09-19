@echo off
setlocal

set BIN=%~dp0balanca_service.exe
set CONFIG=%PROGRAMDATA%\Balanca

if not exist "%CONFIG%" mkdir "%CONFIG%"

"%BIN%" --config-dir="%CONFIG%"
