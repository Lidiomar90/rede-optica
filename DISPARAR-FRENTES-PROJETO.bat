@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\DISPARAR-FRENTES-PROJETO.ps1" %*
endlocal
