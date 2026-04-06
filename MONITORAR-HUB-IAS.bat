@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\MONITORAR-HUB-IAS.ps1" %*
endlocal
