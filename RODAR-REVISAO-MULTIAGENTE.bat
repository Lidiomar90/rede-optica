@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"

echo.
echo ======================================
echo   REVISAO MULTIAGENTE
echo ======================================
echo.
echo 1. Gerar handoffs Claude + Gemini
echo 2. Gerar com foco GeoSite e abrir pasta
echo 3. Gerar sem consultar Git
echo 4. Sair
echo.
set /p OP=Escolha uma opcao: 

if "%OP%"=="1" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\RODAR-REVISAO-MULTIAGENTE.ps1"
if "%OP%"=="2" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\RODAR-REVISAO-MULTIAGENTE.ps1" -AbrirPasta
if "%OP%"=="3" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\RODAR-REVISAO-MULTIAGENTE.ps1" -SemGit

echo.
pause
