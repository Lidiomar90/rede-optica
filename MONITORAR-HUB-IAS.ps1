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

function Get-ManifestTaskBySession {
    param([string]$SessionPath)

    $filaDir = Join-Path $HUB "fila"
    $taskDirs = Get-ChildItem -Path $filaDir -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    foreach ($taskDir in $taskDirs) {
        $manifestPath = Join-Path $taskDir.FullName "manifest.json"
        if (-not (Test-Path $manifestPath)) { continue }

        try {
            $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
            if ($manifest.sessao -eq $SessionPath) {
                return $taskDir
            }
        } catch {
            continue
        }
    }

    return $null
}

function Has-RealResponse {
    param([string]$Text)
    if (-not $Text) { return $false }
    if ($Text -match 'Cole aqui a resposta') { return $false }
    return ($Text.Trim().Length -gt 40)
}

function Get-ResponseState {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{
            estado = "sem_arquivo"
            real = $false
            placeholder = $false
            tamanho = 0
            atualizado_em = $null
        }
    }
    $item = Get-Item $Path
    $text = Read-All $Path
    $placeholder = ($text -match 'Cole aqui a resposta')
    $real = Has-RealResponse $text
    $estado = if ($real) { "resposta_real" } elseif ($placeholder) { "placeholder" } else { "arquivo_sem_resposta" }
    return [pscustomobject]@{
        estado = $estado
        real = $real
        placeholder = $placeholder
        tamanho = $item.Length
        atualizado_em = $item.LastWriteTime
    }
}

function Get-SessionAgeMinutes {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    $session = Get-Item $Path
    return [int]([DateTime]::Now - $session.LastWriteTime).TotalMinutes
}

function Get-SessionExecutionState {
    param(
        [array]$ResponseStates,
        [int]$SessionAgeMinutes
    )
    $realCount = @($ResponseStates | Where-Object { $_.real }).Count
    $placeholderCount = @($ResponseStates | Where-Object { $_.estado -eq 'placeholder' }).Count
    if ($realCount -gt 0 -and $realCount -lt $ResponseStates.Count) { return "respostas_parciais" }
    if ($realCount -eq $ResponseStates.Count) { return "respostas_recebidas" }
    if ($placeholderCount -gt 0 -and $SessionAgeMinutes -ge 15) { return "placeholders_sem_execucao_real" }
    if ($placeholderCount -gt 0) { return "aguardando_execucao_externa" }
    return "sem_resposta_detectada"
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
$ManifestTask = Get-ManifestTaskBySession -SessionPath $SessaoPath

$respClaude = Get-ResponseState (Join-Path $RespDir "claude_resposta.md")
$respGemini = Get-ResponseState (Join-Path $RespDir "gemini_resposta.md")
$respDeepSeek = Get-ResponseState (Join-Path $RespDir "deepseek_resposta.md")
$respManus = Get-ResponseState (Join-Path $RespDir "manus_resposta.md")
$respKiro = Get-ResponseState (Join-Path $RespDir "kiro_resposta.md")

$responseStates = @($respClaude, $respGemini, $respDeepSeek, $respManus, $respKiro)
$estado = [ordered]@{
    Claude = $respClaude.real
    Gemini = $respGemini.real
    DeepSeek = $respDeepSeek.real
    Manus = $respManus.real
    Kiro = $respKiro.real
}
$sessionAgeMinutes = Get-SessionAgeMinutes $SessaoPath
$sessionExecutionState = Get-SessionExecutionState -ResponseStates $responseStates -SessionAgeMinutes $sessionAgeMinutes

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
- Claude: $($respClaude.estado)
- Gemini: $($respGemini.estado)
- DeepSeek: $($respDeepSeek.estado)
- Manus: $($respManus.estado)
- Kiro: $($respKiro.estado)

## Leitura de execucao
- Idade da sessao em minutos: $sessionAgeMinutes
- Estado geral da sessao: $sessionExecutionState
- Placeholder sem resposta real detectado: $(if(@($responseStates | Where-Object { $_.estado -eq 'placeholder' }).Count -gt 0){'sim'}else{'nao'})

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
- Acao sugerida: $(switch ($sessionExecutionState) { 'placeholders_sem_execucao_real' {'disparar IAs externas ou integrar APIs'} 'respostas_parciais' {'completar respostas faltantes e consolidar'} 'respostas_recebidas' {'consolidar e publicar se validacao passar'} default {'verificar disparo externo e monitorar novamente'} })
"@

Write-Utf8 -Path $ResumoExec -Text $texto

if ($ManifestTask) {
    $manifestPath = Join-Path $ManifestTask.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        $manifest.status = $sessionExecutionState
        $manifest | Add-Member -NotePropertyName monitoramento -NotePropertyValue ([ordered]@{
            atualizado_em = (Get-Date).ToString("o")
            sessao_idade_min = $sessionAgeMinutes
            respostas_reais = $prontas.Count
            respostas_faltando = $faltando.Count
            placeholders = @($responseStates | Where-Object { $_.estado -eq 'placeholder' }).Count
        }) -Force
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
Write-Host "Estado geral:" $sessionExecutionState
Write-Host "Consolidado:" $(if($consolidadoGerado){"sim"}else{"nao"})
Write-Host "Publicado:" $(if($publicou){"sim"}else{"nao"})
Write-Host ""

if ($AbrirPasta) {
    Start-Process explorer.exe $SessaoPath | Out-Null
}
