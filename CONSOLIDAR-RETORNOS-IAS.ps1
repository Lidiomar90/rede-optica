param(
    [Parameter(Mandatory = $true)]
    [string]$Sessao,
    [switch]$AbrirPasta
)

$ErrorActionPreference = "Stop"

function Ensure-File {
    param(
        [string]$Path,
        [string]$Seed
    )
    if (-not (Test-Path $Path)) {
        Set-Content -Path $Path -Value $Seed -Encoding UTF8
    }
}

function Read-All {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    return Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
}

function Count-ChecklistItems {
    param([string]$Text)
    if (-not $Text) { return 0 }
    return ([regex]::Matches($Text, '(^|\n)\s*(\d+\.|-)\s+')).Count
}

$SessaoPath = (Resolve-Path $Sessao).Path
$ResumoPath = Join-Path $SessaoPath "00_RESUMO_SESSAO.md"
$RespDir = Join-Path $SessaoPath "respostas"
$SaidaPath = Join-Path $SessaoPath "07_RELATORIO_CONSOLIDADO.md"

if (-not (Test-Path $SessaoPath)) {
    throw "Sessao nao encontrada: $Sessao"
}

if (-not (Test-Path $RespDir)) {
    New-Item -ItemType Directory -Path $RespDir -Force | Out-Null
}

$ClaudeResp = Join-Path $RespDir "claude_resposta.md"
$GeminiResp = Join-Path $RespDir "gemini_resposta.md"
$DeepSeekResp = Join-Path $RespDir "deepseek_resposta.md"
$ManusResp = Join-Path $RespDir "manus_resposta.md"

Ensure-File $ClaudeResp "# Resposta Claude`r`n`r`nCole aqui a resposta do Claude.`r`n"
Ensure-File $GeminiResp "# Resposta Gemini`r`n`r`nCole aqui a resposta do Gemini.`r`n"
Ensure-File $DeepSeekResp "# Resposta DeepSeek`r`n`r`nCole aqui a resposta do DeepSeek.`r`n"
Ensure-File $ManusResp "# Resposta Manus`r`n`r`nCole aqui a resposta do Manus.`r`n"

$resumo = Read-All $ResumoPath
$claude = Read-All $ClaudeResp
$gemini = Read-All $GeminiResp
$deepseek = Read-All $DeepSeekResp
$manus = Read-All $ManusResp

$fontes = @(
    @{Nome="Claude"; Caminho=$ClaudeResp; Texto=$claude; Itens=(Count-ChecklistItems $claude)},
    @{Nome="Gemini"; Caminho=$GeminiResp; Texto=$gemini; Itens=(Count-ChecklistItems $gemini)},
    @{Nome="DeepSeek"; Caminho=$DeepSeekResp; Texto=$deepseek; Itens=(Count-ChecklistItems $deepseek)},
    @{Nome="Manus"; Caminho=$ManusResp; Texto=$manus; Itens=(Count-ChecklistItems $manus)}
)

$preenchidas = $fontes | Where-Object { $_.Texto -and $_.Texto -notmatch 'Cole aqui a resposta' }
$faltantes = $fontes | Where-Object { -not $_.Texto -or $_.Texto -match 'Cole aqui a resposta' }

$linhasFonte = $fontes | ForEach-Object {
    "- $($_.Nome): $(if($_.Texto -and $_.Texto -notmatch 'Cole aqui a resposta'){'preenchido'}else{'pendente'}) | itens detectados: $($_.Itens) | arquivo: $($_.Caminho)"
}

$consolidado = @"
# Relatorio Consolidado Multi-IA

Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Sessao: $SessaoPath

## Resumo da sessao
$resumo

## Estado das respostas
$($linhasFonte -join "`r`n")

## Leituras obrigatorias para decisao
- Revisar os achados de Claude para arquitetura e banco.
- Revisar os achados de Gemini para validacao e regressao.
- Revisar os achados de DeepSeek para bugs e fragilidades ocultas.
- Revisar os achados de Manus para UX, produto e benchmark.

## Faltando resposta de
$(if($faltantes.Count){ ($faltantes | ForEach-Object { "- $($_.Nome)" }) -join "`r`n" } else { "- Nenhuma" })

## Proximo uso recomendado
1. Cole as respostas faltantes na pasta `respostas`.
2. Rode este consolidador novamente.
3. Use as secoes abaixo para comparar consenso, conflito e prioridade.

## Claude
$claude

## Gemini
$gemini

## DeepSeek
$deepseek

## Manus
$manus

## Sintese manual guiada
Preencha ou refine esta secao apos ler as respostas:

### Consensos
- 

### Conflitos entre IAs
- 

### Prioridades imediatas
1. 
2. 
3. 

### O que Codex deve implementar a seguir
- 

### O que Claude deve revisar
- 

### O que Gemini deve validar depois
- 
"@

Set-Content -Path $SaidaPath -Value $consolidado -Encoding UTF8

Write-Host ""
Write-Host "======================================"
Write-Host "  RELATORIO CONSOLIDADO GERADO"
Write-Host "======================================"
Write-Host ""
Write-Host "Sessao:" $SessaoPath
Write-Host "Pasta respostas:" $RespDir
Write-Host "Saida:" $SaidaPath
Write-Host ""

if ($AbrirPasta) {
    Start-Process explorer.exe $SessaoPath | Out-Null
}
