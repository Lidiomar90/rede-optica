@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-EXECUCAO-IAS.ps1" %*
endlocal
