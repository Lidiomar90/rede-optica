@echo off
setlocal
cd /d "C:\FIBRA CADASTRO"

:MENU
cls
echo ======================================
echo   AUTOMACAO REDE OPTICA MG
echo ======================================
echo.
echo 1. Rodar ETL Telegram ^(dry-run^)
echo 2. Rodar ETL Telegram ^(commit^)
echo 3. Importar Science
echo 4. Publicar GitHub Pages
echo 5. Rodar tudo
echo 6. Sair
echo.
set /p OPCAO=Escolha uma opcao: 

if "%OPCAO%"=="1" goto ETL_DRY
if "%OPCAO%"=="2" goto ETL_COMMIT
if "%OPCAO%"=="3" goto SCIENCE
if "%OPCAO%"=="4" goto PUBLISH
if "%OPCAO%"=="5" goto TUDO
if "%OPCAO%"=="6" goto FIM

echo.
echo Opcao invalida.
pause
goto MENU

:ASKKEY
if defined SB_KEY goto EOFKEY
set /p SB_KEY=Informe a SB_KEY do Supabase: 
:EOFKEY
exit /b 0

:ETL_DRY
call :ASKKEY
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\AUTOMACAO-REDE-OPTICA.ps1" -Etl -SbKey "%SB_KEY%"
pause
goto MENU

:ETL_COMMIT
call :ASKKEY
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\AUTOMACAO-REDE-OPTICA.ps1" -Etl -CommitEtl -SbKey "%SB_KEY%"
pause
goto MENU

:SCIENCE
call :ASKKEY
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\AUTOMACAO-REDE-OPTICA.ps1" -Science -SbKey "%SB_KEY%"
pause
goto MENU

:PUBLISH
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\AUTOMACAO-REDE-OPTICA.ps1" -Publish
pause
goto MENU

:TUDO
call :ASKKEY
powershell -ExecutionPolicy Bypass -File "C:\FIBRA CADASTRO\AUTOMACAO-REDE-OPTICA.ps1" -Tudo -SbKey "%SB_KEY%"
pause
goto MENU

:FIM
endlocal
