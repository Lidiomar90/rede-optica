# ================================================
# PUBLICAR-GIT.ps1
# Publica os arquivos no GitHub Pages
# Pasta: C:\FIBRA CADASTRO\
# ================================================

$PASTA   = "C:\FIBRA CADASTRO"
$REPO    = "https://github.com/Lidiomar90/rede-optica.git"
$TOKEN_F = "$PASTA\.github_token"
$TOKEN_ALT = "$PASTA\privado\.github_token"
$GITIGNORE = "$PASTA\.gitignore"

# Arquivos que serao publicados (precisam estar na pasta)
$ARQUIVOS = @(
    "index.html",
    "mapa-rede-optica.html",
    "dashboard.html",
    "ia-assistente.html",
    "auditoria-revisao.html",
    "science_sites_mg.json"
)

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  REDE OPTICA MG - Publicar no GitHub" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# --- Ler token ---
if (Test-Path $TOKEN_F) {
    $TOKEN = (Get-Content $TOKEN_F -Raw).Trim()
    Write-Host "Token encontrado." -ForegroundColor Green
} elseif (Test-Path $TOKEN_ALT) {
    $TOKEN = (Get-Content $TOKEN_ALT -Raw).Trim()
    Write-Host "Token encontrado." -ForegroundColor Green
} else {
    Write-Host "ERRO: arquivo .github_token nao encontrado em $PASTA ou $PASTA\privado" -ForegroundColor Red
    Write-Host "Crie o arquivo .github_token com seu token do GitHub dentro." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# --- Ir para a pasta ---
Set-Location $PASTA

# --- Garantir .gitignore essencial ---
$ignorePatterns = @(
    "telegram/",
    "*.dwg",
    "*.apk",
    "privado/"
)
if (-not (Test-Path $GITIGNORE)) {
    New-Item -ItemType File -Path $GITIGNORE -Force | Out-Null
}
$gitignoreAtual = Get-Content $GITIGNORE -ErrorAction SilentlyContinue
foreach ($pattern in $ignorePatterns) {
    if ($gitignoreAtual -notcontains $pattern) {
        Add-Content -Path $GITIGNORE -Value $pattern
        Write-Host "Adicionado ao .gitignore: $pattern" -ForegroundColor Yellow
    }
}

# --- Verificar se .git existe ---
if (-not (Test-Path "$PASTA\.git")) {
    Write-Host "Repositorio nao existe. Inicializando..." -ForegroundColor Yellow
    git init
    git branch -M main
    git remote add origin $REPO
} else {
    Write-Host "Repositorio Git encontrado." -ForegroundColor Green
    # Garantir que o remote esta correto
    git remote remove origin 2>$null
    git remote add origin $REPO
}

# --- Configurar usuario git ---
git config user.email "lidiomar@redeop.com.br"
git config user.name "Lidiomar90"
git config --global --add safe.directory $PASTA 2>$null

# --- Verificar arquivos ---
Write-Host ""
Write-Host "Verificando arquivos..." -ForegroundColor Cyan
$faltando = @()
foreach ($f in $ARQUIVOS) {
    if (Test-Path "$PASTA\$f") {
        Write-Host "  [OK] $f" -ForegroundColor Green
    } else {
        Write-Host "  [FALTA] $f" -ForegroundColor Red
        $faltando += $f
    }
}

if ($faltando.Count -gt 0) {
    Write-Host ""
    Write-Host "Atencao: $($faltando.Count) arquivo(s) nao encontrado(s)." -ForegroundColor Yellow
    Write-Host "Continuando com os arquivos existentes..." -ForegroundColor Yellow
}

# --- Criar .nojekyll (necessario para GitHub Pages) ---
"" | Out-File "$PASTA\.nojekyll" -Encoding UTF8

# --- Adicionar e commitar ---
Write-Host ""
Write-Host "Adicionando arquivos..." -ForegroundColor Cyan
git add .gitignore index.html mapa-rede-optica.html dashboard.html ia-assistente.html auditoria-revisao.html science_sites_mg.json .nojekyll 2>$null
git add -u 2>$null

$DATA = Get-Date -Format "dd/MM/yyyy HH:mm"
git commit -m "Rede Optica MG - $DATA" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Nenhuma alteracao nova detectada, forcando push..." -ForegroundColor Yellow
}

# --- Push com token ---
Write-Host "Publicando no GitHub..." -ForegroundColor Cyan
$URL_TOKEN = "https://Lidiomar90:$TOKEN@github.com/Lidiomar90/rede-optica.git"
$pushStdOut = Join-Path $env:TEMP "rede-optica-push.out"
$pushStdErr = Join-Path $env:TEMP "rede-optica-push.err"
if (Test-Path $pushStdOut) { Remove-Item -LiteralPath $pushStdOut -Force }
if (Test-Path $pushStdErr) { Remove-Item -LiteralPath $pushStdErr -Force }
$pushProc = Start-Process -FilePath "git" -ArgumentList @("push", $URL_TOKEN, "main", "--force") -NoNewWindow -Wait -PassThru -RedirectStandardOutput $pushStdOut -RedirectStandardError $pushStdErr
$pushOutput = @()
if (Test-Path $pushStdOut) { $pushOutput += Get-Content -LiteralPath $pushStdOut }
if (Test-Path $pushStdErr) { $pushOutput += Get-Content -LiteralPath $pushStdErr }
if ($pushProc.ExitCode -ne 0) { throw ($pushOutput | Out-String) }
if ($pushOutput.Count -gt 0) { $pushOutput | Out-Host }

if ($pushProc.ExitCode -eq 0) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  PUBLICADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Portal:      https://lidiomar90.github.io/rede-optica/" -ForegroundColor White
    Write-Host "  Mapa:        https://lidiomar90.github.io/rede-optica/mapa-rede-optica.html" -ForegroundColor White
    Write-Host "  Dashboard:   https://lidiomar90.github.io/rede-optica/dashboard.html" -ForegroundColor White
    Write-Host "  IA:          https://lidiomar90.github.io/rede-optica/ia-assistente.html" -ForegroundColor White
    Write-Host "  Auditoria:   https://lidiomar90.github.io/rede-optica/auditoria-revisao.html" -ForegroundColor White
    Write-Host ""
    Write-Host "  Aguarde ~60 segundos para o GitHub Pages atualizar." -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERRO ao publicar!" -ForegroundColor Red
    Write-Host "Possiveis causas:" -ForegroundColor Yellow
    Write-Host "  1. Token expirado - gere novo em github.com > Settings > Developer settings" -ForegroundColor Yellow
    Write-Host "  2. Token sem permissao 'repo' - verifique as permissoes" -ForegroundColor Yellow
    Write-Host "  3. Sem internet" -ForegroundColor Yellow
    Write-Host ""
}

pause
