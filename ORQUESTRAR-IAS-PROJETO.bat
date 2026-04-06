@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"

echo.
echo ======================================
echo   ORQUESTRAR VARIAS IAS
echo ======================================
echo.
echo 1. Gerar pacote multi-IA
echo 2. Gerar e abrir pasta da sessao
echo 3. Gerar sem consultar Git
echo 4. Foco: mobile / campo
echo 5. Foco: inventario operacional
echo 6. Foco: GeoSite / benchmark / UX
echo 7. Sair
echo.
set /p OP=Escolha uma opcao: 

if "%OP%"=="1" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-IAS-PROJETO.ps1"
if "%OP%"=="2" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-IAS-PROJETO.ps1" -AbrirPasta
if "%OP%"=="3" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-IAS-PROJETO.ps1" -SemGit
if "%OP%"=="4" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-IAS-PROJETO.ps1" -Foco "mobile, campo, sobreposicao, performance"
if "%OP%"=="5" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-IAS-PROJETO.ps1" -Foco "inventario operacional, DGO, caixa_emenda, segmento_cabo, evento_ruptura"
if "%OP%"=="6" powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\ORQUESTRAR-IAS-PROJETO.ps1" -Foco "benchmark geosite, UX operacional, gaps de produto, fluxo de campo"

echo.
pause
