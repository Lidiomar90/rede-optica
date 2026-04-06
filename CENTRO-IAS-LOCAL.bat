@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\CENTRO-IAS-LOCAL.ps1" -AbrirPastas
endlocal
