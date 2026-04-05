# ================================================
# PUBLICAR-GIT.ps1
# Publica os arquivos no GitHub Pages
# Pasta: C:\FIBRA CADASTRO\
# ================================================

$PASTA   = "C:\FIBRA CADASTRO"
$REPO    = "https://github.com/Lidiomar90/rede-optica.git"
$TOKEN_F = "$PASTA\.github_token"

# Arquivos que serao publicados (precisam estar na pasta)
$ARQUIVOS = @(
    "index.html",
    "mapa-rede-optica.html",
    "dashboard.html",
    "ia-assistente.html",
    "auditoria-revisao.html"
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
} else {
    Write-Host "ERRO: arquivo .github_token nao encontrado em $PASTA" -ForegroundColor Red
    Write-Host "Crie o arquivo .github_token com seu token do GitHub dentro." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# --- Ir para a pasta ---
Set-Location $PASTA

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
git add index.html mapa-rede-optica.html dashboard.html ia-assistente.html auditoria-revisao.html .nojekyll 2>$null
git add -u 2>$null

$DATA = Get-Date -Format "dd/MM/yyyy HH:mm"
git commit -m "Rede Optica MG - $DATA" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Nenhuma alteracao nova detectada, forcando push..." -ForegroundColor Yellow
}

# --- Push com token ---
Write-Host "Publicando no GitHub..." -ForegroundColor Cyan
$URL_TOKEN = "https://Lidiomar90:$TOKEN@github.com/Lidiomar90/rede-optica.git"
$pushOutput = $pushOutput = git push $URL_TOKEN main --force 2>&1
if ($LASTEXITCODE -ne 0) { throw ($pushOutput | Out-String) }
$pushOutput | Out-Host
if ($LASTEXITCODE -ne 0) { throw ($pushOutput | Out-String) }
$pushOutput | Out-Host

if ($LASTEXITCODE -eq 0) {
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
