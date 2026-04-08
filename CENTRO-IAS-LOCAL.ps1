param(
    [switch]$DispararFrentes,
    [switch]$AbrirPastas,
    [switch]$SemGit
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$HUB = Join-Path $PASTA "ia_hub"
$SESSOES = Join-Path $HUB "sessoes"
$FILA = Join-Path $HUB "fila"
$PAINEL = Join-Path $HUB "PAINEL_IA_LOCAL.md"
$DISPARAR = Join-Path $PASTA "DISPARAR-FRENTES-PROJETO.ps1"

function Save-Utf8 {
    param([string]$Path, [string]$Text)
    Set-Content -Path $Path -Value $Text -Encoding UTF8
}

function Get-LatestFrontSummary {
    Get-ChildItem -Path $FILA -Filter "frentes_*.md" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-LatestSessions {
    Get-ChildItem -Path $SESSOES -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 6
}

if ($DispararFrentes) {
    $params = @{}
    if ($AbrirPastas) { $params.AbrirPastas = $true }
    if ($SemGit) { $params.SemGit = $true }
    & $DISPARAR @params
}

$frontSummary = Get-LatestFrontSummary
$sessions = @(Get-LatestSessions)
$generatedAt = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$frontSummaryLine = if ($frontSummary) { "- $($frontSummary.FullName)" } else { "- nenhuma frente disparada ainda" }

$sessionBlocks = foreach ($sessao in $sessions) {
    $claude = Join-Path $sessao.FullName "01_CLAUDE_ARQUITETURA.md"
    $gemini = Join-Path $sessao.FullName "02_GEMINI_VALIDACAO.md"
    $codex = Join-Path $sessao.FullName "03_CODEX_IMPLEMENTACAO.md"
    $deepseek = Join-Path $sessao.FullName "04_DEEPSEEK_REVISAO.md"
    $manus = Join-Path $sessao.FullName "05_MANUS_PRODUTO_UX.md"
    $kiro = Join-Path $sessao.FullName "06_KIRO_COORDENACAO.md"
    $claudeCowork = Join-Path $sessao.FullName "09_CLAUDE_COWORK_EXECUCAO.md"
    $codexCowork = Join-Path $sessao.FullName "10_CODEX_COWORK_EXECUCAO.md"
    $qwen = Join-Path $sessao.FullName "11_QWEN_REVISAO.md"
    $respostas = Join-Path $sessao.FullName "respostas"

    @(
        "## $($sessao.Name)",
        "",
        "- Sessao: $($sessao.FullName)",
        "- Claude: $claude",
        "- Gemini: $gemini",
        "- Codex: $codex",
        "- DeepSeek: $deepseek",
        "- Manus: $manus",
        "- Kiro: $kiro",
        "- Claude Cowork: $claudeCowork",
        "- Codex Cowork: $codexCowork",
        "- Qwen: $qwen",
        "- Respostas: $respostas",
        ""
    ) -join "`r`n"
}

$texto = @(
    "# Centro Local das IAs",
    "",
    "Gerado em: $generatedAt",
    "Workspace: C:\FIBRA CADASTRO",
    "",
    "## Como trabalhar direto no PC",
    "",
    "1. Disparar as frentes paralelas:",
    "   - C:\FIBRA CADASTRO\DISPARAR-FRENTES-PROJETO.bat",
    "2. Abrir este painel:",
    "   - C:\FIBRA CADASTRO\ia_hub\PAINEL_IA_LOCAL.md",
    "3. Mandar cada arquivo para a IA correspondente:",
    "   - Claude",
    "   - Gemini",
    "   - DeepSeek",
    "   - Manus",
    "   - Kiro",
    "   - Claude Cowork",
    "   - Codex Cowork",
    "   - Qwen",
    "4. Colar as respostas nas pastas respostas",
    "5. Rodar o monitor:",
    "   - C:\FIBRA CADASTRO\MONITORAR-HUB-IAS.bat",
    "",
    "## Ultimo resumo de frentes",
    $frontSummaryLine,
    "",
    "## Sessoes mais recentes",
    "",
    ($sessionBlocks -join "`r`n"),
    "",
    "## Atalhos uteis",
    "",
    "- Disparar frentes: C:\FIBRA CADASTRO\DISPARAR-FRENTES-PROJETO.bat",
    "- Monitorar hub: C:\FIBRA CADASTRO\MONITORAR-HUB-IAS.bat",
    "- Criar tarefa unica: C:\FIBRA CADASTRO\ORQUESTRAR-EXECUCAO-IAS.bat",
    "- Consolidar retornos: C:\FIBRA CADASTRO\CONSOLIDAR-RETORNOS-IAS.bat"
) -join "`r`n"

Save-Utf8 -Path $PAINEL -Text $texto

Write-Host ""
Write-Host "======================================"
Write-Host " CENTRO LOCAL DAS IAS PRONTO"
Write-Host "======================================"
Write-Host ""
Write-Host "Painel:" $PAINEL
if ($frontSummary) {
    Write-Host "Ultimo resumo de frentes:" $frontSummary.FullName
}
Write-Host ""

if ($AbrirPastas) {
    Start-Process explorer.exe $HUB | Out-Null
}
