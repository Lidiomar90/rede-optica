param(
    [string]$Sessao,
    [switch]$PublicarSeSeguro,
    [switch]$AbrirPasta
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$HUB = Join-Path $PASTA "ia_hub"
$SESSOES = Join-Path $HUB "sessoes"
$CONSOLIDAR = Join-Path $PASTA "CONSOLIDAR-RETORNOS-IAS.ps1"
$PUBLICAR = Join-Path $PASTA "PUBLICAR-GIT.ps1"

function Read-All {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    return Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
}

function Write-Utf8 {
    param([string]$Path, [string]$Text)
    Set-Content -Path $Path -Value $Text -Encoding UTF8
}

function Get-LatestSession {
    Get-ChildItem -Path $SESSOES -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Has-RealResponse {
    param([string]$Text)
    if (-not $Text) { return $false }
    if ($Text -match 'Cole aqui a resposta') { return $false }
    return ($Text.Trim().Length -gt 40)
}

function Test-JsHtml {
    $script = @'
const fs=require("fs");
const html=fs.readFileSync("C:/FIBRA CADASTRO/mapa-rede-optica.html","utf8");
const scripts=[...html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi)].map(m=>m[1]).join("\n");
new Function(scripts);
console.log("CHECK_OK");
'@
    $result = $script | node -
    return ($result -match 'CHECK_OK')
}

function Get-GitStatusShort {
    Push-Location $PASTA
    try {
        return (git status --short 2>$null) -join "`r`n"
    } finally {
        Pop-Location
    }
}

if (-not $Sessao) {
    $latest = Get-LatestSession
    if (-not $latest) { throw "Nenhuma sessao encontrada em $SESSOES" }
    $Sessao = $latest.FullName
}

$SessaoPath = (Resolve-Path $Sessao).Path
$RespDir = Join-Path $SessaoPath "respostas"
$ResumoExec = Join-Path $SessaoPath "08_RESUMO_AUTOMATICO.md"
$ManifestTask = Get-ChildItem -Path (Join-Path $HUB "fila") -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

$claude = Read-All (Join-Path $RespDir "claude_resposta.md")
$gemini = Read-All (Join-Path $RespDir "gemini_resposta.md")
$deepseek = Read-All (Join-Path $RespDir "deepseek_resposta.md")
$manus = Read-All (Join-Path $RespDir "manus_resposta.md")

$estado = [ordered]@{
    Claude = Has-RealResponse $claude
    Gemini = Has-RealResponse $gemini
    DeepSeek = Has-RealResponse $deepseek
    Manus = Has-RealResponse $manus
}

$prontas = @($estado.GetEnumerator() | Where-Object { $_.Value } | ForEach-Object { $_.Key })
$faltando = @($estado.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })

$consolidadoGerado = $false
if ($faltando.Count -eq 0 -and (Test-Path $CONSOLIDAR)) {
    & $CONSOLIDAR -Sessao $SessaoPath | Out-Null
    $consolidadoGerado = $true
}

$jsOk = $false
try { $jsOk = Test-JsHtml } catch { $jsOk = $false }
$gitStatus = Get-GitStatusShort
$gitCleanEnough = [string]::IsNullOrWhiteSpace($gitStatus)
$publicou = $false
$publicacaoMsg = "Nao solicitada."

if ($PublicarSeSeguro) {
    if (-not $consolidadoGerado) {
        $publicacaoMsg = "Nao publicou: ainda faltam respostas de IAs."
    } elseif (-not $jsOk) {
        $publicacaoMsg = "Nao publicou: validacao JS falhou."
    } elseif (-not (Test-Path $PUBLICAR)) {
        $publicacaoMsg = "Nao publicou: script PUBLICAR-GIT.ps1 nao encontrado."
    } else {
        & $PUBLICAR | Out-Null
        $publicou = $true
        $publicacaoMsg = "Publicacao automatica executada via PUBLICAR-GIT.ps1."
    }
}

$texto = @"
# Resumo Automatico do Hub

Sessao: $SessaoPath
Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")

## Respostas detectadas
- Claude: $(if($estado.Claude){'ok'}else{'pendente'})
- Gemini: $(if($estado.Gemini){'ok'}else{'pendente'})
- DeepSeek: $(if($estado.DeepSeek){'ok'}else{'pendente'})
- Manus: $(if($estado.Manus){'ok'}else{'pendente'})

## Consolidacao
- Consolidado gerado: $(if($consolidadoGerado){'sim'}else{'nao'})

## Validacao tecnica
- JavaScript inline do mapa: $(if($jsOk){'CHECK_OK'}else{'falhou'})
- Git status limpo: $(if($gitCleanEnough){'sim'}else{'nao'})

## Publicacao
- Publicado automaticamente: $(if($publicou){'sim'}else{'nao'})
- Mensagem: $publicacaoMsg

## Proximos passos
- IAs prontas: $(if($prontas.Count){$prontas -join ', '}else{'nenhuma'})
- IAs faltando: $(if($faltando.Count){$faltando -join ', '}else{'nenhuma'})
"@

Write-Utf8 -Path $ResumoExec -Text $texto

if ($ManifestTask) {
    $manifestPath = Join-Path $ManifestTask.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        $manifest.status = if ($faltando.Count -eq 0) { "respostas_recebidas" } else { "aguardando_respostas" }
        $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8
    }
}

Write-Host ""
Write-Host "======================================"
Write-Host "  HUB MONITORADO"
Write-Host "======================================"
Write-Host ""
Write-Host "Sessao:" $SessaoPath
Write-Host "Resumo:" $ResumoExec
Write-Host "Consolidado:" $(if($consolidadoGerado){"sim"}else{"nao"})
Write-Host "Publicado:" $(if($publicou){"sim"}else{"nao"})
Write-Host ""

if ($AbrirPasta) {
    Start-Process explorer.exe $SessaoPath | Out-Null
}
