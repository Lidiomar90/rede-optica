param(
    [switch]$AbrirPasta,
    [switch]$SemGit,
    [string]$SaidaDir
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$CONTEXTO = Join-Path $PASTA "CONTEXTO_PROJETO.md"
$LOG_DIR = Join-Path $PASTA "logs"
$HANDOFF_DIR = if ($SaidaDir) { $SaidaDir } else { Join-Path $PASTA "handoffs" }

if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

if (-not (Test-Path $HANDOFF_DIR)) {
    New-Item -ItemType Directory -Path $HANDOFF_DIR -Force | Out-Null
}

$RunId = Get-Date -Format "yyyyMMdd_HHmmss"
$LogPath = Join-Path $LOG_DIR "revisao_multiagente_$RunId.log"
$ClaudePath = Join-Path $HANDOFF_DIR "handoff_claude_$RunId.md"
$GeminiPath = Join-Path $HANDOFF_DIR "handoff_gemini_$RunId.md"
$GeminiGeoSitePath = Join-Path $HANDOFF_DIR "handoff_gemini_geosite_gap_$RunId.md"
$ResumoPath = Join-Path $HANDOFF_DIR "resumo_multiagente_$RunId.md"

function Write-Log {
    param(
        [string]$Mensagem,
        [string]$Nivel = "INFO"
    )

    $linha = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Nivel, $Mensagem
    $linha | Tee-Object -FilePath $LogPath -Append
}

function Get-FileText {
    param(
        [string]$Path,
        [int]$Tail = 220
    )

    if (-not (Test-Path $Path)) {
        return ""
    }

    return (Get-Content -Path $Path -Tail $Tail -ErrorAction SilentlyContinue) -join "`r`n"
}

function Get-GitInfo {
    param([switch]$Skip)

    if ($Skip) {
        return @{
            Branch = "ignorado"
            Status = "Git ignorado por parametro."
            Log = "Git ignorado por parametro."
        }
    }

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        return @{
            Branch = "git indisponivel"
            Status = "Git nao encontrado no PATH."
            Log = "Git nao encontrado no PATH."
        }
    }

    Push-Location $PASTA
    try {
        $branch = (git branch --show-current 2>$null) -join "`n"
        if (-not $branch) { $branch = "desconhecida" }
        $status = (git status --short 2>$null) -join "`r`n"
        if (-not $status) { $status = "Sem alteracoes locais pendentes." }
        $log = (git log --oneline -n 5 2>$null) -join "`r`n"
        if (-not $log) { $log = "Sem historico recente disponivel." }
        return @{
            Branch = $branch.Trim()
            Status = $status.Trim()
            Log = $log.Trim()
        }
    }
    finally {
        Pop-Location
    }
}

function Get-KeyFilesSummary {
    $targets = @(
        "mapa-rede-optica.html",
        "CONTEXTO_PROJETO.md",
        "CHECKLIST_QUALIDADE_E_PUBLICACAO.md",
        "PILOTOS_E2E_OPERACIONAIS.md",
        "EXECUCAO_TESTES_E2E.md",
        "AUTOMACAO-REDE-OPTICA.ps1",
        "PUBLICAR-GIT.ps1",
        "importar_science.py"
    )

    $linhas = foreach ($name in $targets) {
        $path = Join-Path $PASTA $name
        if (Test-Path $path) {
            $f = Get-Item $path
            "- $name | atualizado em $($f.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')) | $([math]::Round($f.Length / 1kb, 1)) KB"
        } else {
            "- $name | ausente"
        }
    }

    return ($linhas -join "`r`n")
}

if (-not (Test-Path $CONTEXTO)) {
    throw "Arquivo CONTEXTO_PROJETO.md nao encontrado em $CONTEXTO"
}

Write-Log "Gerando handoffs multiagente."

$contextoTail = Get-FileText -Path $CONTEXTO -Tail 260
$checklistTail = Get-FileText -Path (Join-Path $PASTA "CHECKLIST_QUALIDADE_E_PUBLICACAO.md") -Tail 160
$geoSiteGapTail = Get-FileText -Path (Join-Path $PASTA "CHECKLIST_GEOSITE_GAP.md") -Tail 220
$pilotosTail = Get-FileText -Path (Join-Path $PASTA "PILOTOS_E2E_OPERACIONAIS.md") -Tail 160
$execucaoTail = Get-FileText -Path (Join-Path $PASTA "EXECUCAO_TESTES_E2E.md") -Tail 160
$gitInfo = Get-GitInfo -Skip:$SemGit
$keyFiles = Get-KeyFilesSummary
$agora = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

$resumo = @"
# Resumo Multiagente

Gerado em: $agora
Workspace: C:\FIBRA CADASTRO
Branch atual: $($gitInfo.Branch)

## Arquivos-chave
$keyFiles

## Git status
$($gitInfo.Status)

## Git log recente
$($gitInfo.Log)

## Contexto recente
$contextoTail
"@

$claude = @"
# Handoff Claude

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md

## Papel
Voce e o agente de arquitetura e estrutura.
Nao reescreva o front local.
Foque em banco, SQL, modelo operacional e decisoes estruturais.

## Estado atual sintetico
- O front local em `mapa-rede-optica.html` ja possui:
  - Science no mapa sem duplicidade
  - agrupamento de Sites por CN / DDD e localidade
  - presets e overlays operacionais
  - cache offline e modo campo
  - DGO local em rascunho
  - caixa/segmento/ruptura em rascunho
  - painel de auditoria local
- O que ainda esta pendente de estrutura real:
  - persistencia Supabase de `caixa_emenda`
  - persistencia Supabase de `dgo`
  - persistencia Supabase de `segmento_cabo`
  - persistencia Supabase de `evento_ruptura`
  - views de pendencias e continuidade
  - revisao estrutural do tracer/BFS onde necessario

## O que preciso de voce
1. Revisar a arquitetura do inventario operacional.
2. Entregar SQL executavel e shape REST final para:
   - dgo
   - caixa_emenda
   - segmento_cabo
   - evento_ruptura
   - views de pendencias
   - views de continuidade
3. Apontar o que ainda esta provisório, arriscado ou incompleto no modelo.
4. Indicar o que o Codex deve plugar no front em seguida.

## Restricoes
- Nao reescrever HTML/JS local.
- Nao repetir exploracao ampla sem necessidade.
- Responder de forma objetiva com:
  - SQL executavel
  - checklist critico do banco
  - riscos
  - ordem de implantacao

## Git status
$($gitInfo.Status)

## Git log recente
$($gitInfo.Log)

## Contexto recente
$contextoTail
"@

$gemini = @"
# Handoff Gemini

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md

## Papel
Voce e o agente de cross-validation, hardening, consistencia, testes e documentacao tecnica.

## Foco desta rodada
Validar o que foi implementado recentemente no front local, sem refatoracao ampla:
- `mapa-rede-optica.html`
- modo campo
- mobile/uso em rua
- cache offline
- overlays e presets
- Science + agrupamento CN / DDD
- auditoria local
- edicao de linhas
- navegação entre ativos

## O que preciso de voce
1. Encontrar inconsistencias funcionais.
2. Listar riscos de regressao.
3. Sugerir testes manuais/e2e faltantes.
4. Apontar endurecimentos tecnicos de baixo risco.
5. Gerar documentacao tecnica curta de validacao/handoff.

## Restricoes
- Nao pedir refatoracao arquitetural ampla.
- Nao assumir que algo funciona sem apontar criterio de validacao.
- Responder com:
  - achados
  - riscos
  - testes faltantes
  - melhorias de robustez
  - handoff curto

## Checklist recente
$checklistTail

## Pilotos recentes
$pilotosTail

## Execucao recente
$execucaoTail

## Contexto recente
$contextoTail
"@

$geminiGeoSite = @"
# Handoff Gemini — Gap Operacional vs GeoSite

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md

## Papel

Voce e o agente de validacao.
Quero uma analise pratica, nao conceitual.
Valide o uso real do mapa e compare com o que o usuario espera de um GeoSite operacional.

## Foco desta rodada

Analisar com prioridade:

1. mapa e leitura de linhas
2. DGO
3. caixa de emenda
4. usabilidade geral
5. uso em campo/mobile
6. se a auditoria realmente ajuda ou so parece ajudar

## Regra importante

Nao assuma que porque existe no HTML, funciona bem.
Valide em experiencia de uso:

- o que o GeoSite normalmente entrega e aqui ainda nao entrega
- o que aqui existe mas esta fraco
- o que aqui ja esta melhor

## Quadro de comparacao esperado

Quero que voce devolva em 3 blocos:

### 1. Falta aqui e faz falta

Liste o que ainda esta abaixo do que se espera de um GeoSite em:
- linhas
- navegacao
- DGO
- caixa
- operacao em campo

### 2. Existe, mas esta meia-boca

Liste o que existe no mapa atual, mas nao esta suficientemente robusto ou fluido.

### 3. Ja esta melhor

Liste o que o projeto atual ja faz melhor que um mapa operacional comum.

## Validacoes especificas

Use como criterio:
- clique em site
- clique em cabo
- clique em segmento
- clique em caixa
- clique em DGO
- clique/toque longo
- menu contextual
- edicao de linhas
- uso como Ponto A/B
- ruptura contextual
- auditoria com acao executavel

## Entrega desejada

Responda com:

1. Achados criticos
2. Achados altos
3. Achados medios
4. O que esta melhor que GeoSite
5. Proxima sprint recomendada

## Checklist GeoSite gap
$geoSiteGapTail

## Execucao recente
$execucaoTail

## Contexto recente
$contextoTail
"@

Set-Content -Path $ResumoPath -Value $resumo -Encoding UTF8
Set-Content -Path $ClaudePath -Value $claude -Encoding UTF8
Set-Content -Path $GeminiPath -Value $gemini -Encoding UTF8
Set-Content -Path $GeminiGeoSitePath -Value $geminiGeoSite -Encoding UTF8

Write-Log "Resumo gerado em: $ResumoPath"
Write-Log "Handoff Claude gerado em: $ClaudePath"
Write-Log "Handoff Gemini gerado em: $GeminiPath"
Write-Log "Handoff Gemini GeoSite gerado em: $GeminiGeoSitePath"

if ($AbrirPasta) {
    Invoke-Item $HANDOFF_DIR
}

Write-Host ""
Write-Host "======================================"
Write-Host "  HANDOFFS MULTIAGENTE GERADOS"
Write-Host "======================================"
Write-Host ""
Write-Host "  Resumo:   $ResumoPath"
Write-Host "  Claude:   $ClaudePath"
Write-Host "  Gemini:   $GeminiPath"
Write-Host "  Gemini+:  $GeminiGeoSitePath"
Write-Host "  Log:      $LogPath"
Write-Host ""
