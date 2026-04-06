@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"

echo.
echo ======================================
echo   CONSOLIDAR RETORNOS DAS IAS
echo ======================================
echo.
set /p SESSAO=Cole o caminho da pasta da sessao: 

if "%SESSAO%"=="" goto :fim

powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\CONSOLIDAR-RETORNOS-IAS.ps1" -Sessao "%SESSAO%" -AbrirPasta

:fim
echo.
pause
