param(
    [string]$Foco = "mobile, mapa, inventario operacional",
    [switch]$AbrirPasta,
    [switch]$SemGit,
    [string]$SaidaDir
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$LOG_DIR = Join-Path $PASTA "logs"
$HANDOFF_BASE = if ($SaidaDir) { $SaidaDir } else { Join-Path $PASTA "handoffs" }
$RUN_STAMP = Get-Date
$RAND = -join ((48..57) + (97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
$RUN_ID = "{0}_{1}" -f $RUN_STAMP.ToString("yyyyMMdd_HHmmss_fff"), $RAND
$SESSION_DIR = Join-Path $HANDOFF_BASE "sessao_multi_ia_$RUN_ID"
$RESP_DIR = Join-Path $SESSION_DIR "respostas"
$LOG_PATH = Join-Path $LOG_DIR "orquestracao_ias_$RUN_ID.log"

$CONTEXTO = Join-Path $PASTA "CONTEXTO_PROJETO.md"
$CHECKLIST = Join-Path $PASTA "CHECKLIST_QUALIDADE_E_PUBLICACAO.md"
$GEOSITE = Join-Path $PASTA "CHECKLIST_GEOSITE_GAP.md"
$PILOTOS = Join-Path $PASTA "PILOTOS_E2E_OPERACIONAIS.md"
$EXECUCAO = Join-Path $PASTA "EXECUCAO_TESTES_E2E.md"
$GEMINI_MD = Join-Path $PASTA "GEMINI.md"

function Write-Log {
    param(
        [string]$Mensagem,
        [string]$Nivel = "INFO"
    )
    $linha = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Nivel, $Mensagem
    $linha | Tee-Object -FilePath $LOG_PATH -Append
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Read-Tail {
    param(
        [string]$Path,
        [int]$Tail = 180
    )
    if (-not (Test-Path $Path)) {
        return ""
    }
    return (Get-Content -Path $Path -Tail $Tail -ErrorAction SilentlyContinue) -join "`r`n"
}

function Get-GitState {
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
        $branch = ((git branch --show-current 2>$null) -join "`n").Trim()
        if (-not $branch) { $branch = "desconhecida" }

        $status = (git status --short 2>$null) -join "`r`n"
        if (-not $status) { $status = "Sem alteracoes locais pendentes." }

        $log = (git log --oneline -n 8 2>$null) -join "`r`n"
        if (-not $log) { $log = "Sem historico recente disponivel." }

        return @{
            Branch = $branch
            Status = $status.Trim()
            Log = $log.Trim()
        }
    }
    finally {
        Pop-Location
    }
}

function Get-KeyFilesSummary {
    $files = @(
        "mapa-rede-optica.html",
        "CONTEXTO_PROJETO.md",
        "CHECKLIST_QUALIDADE_E_PUBLICACAO.md",
        "CHECKLIST_GEOSITE_GAP.md",
        "PILOTOS_E2E_OPERACIONAIS.md",
        "EXECUCAO_TESTES_E2E.md",
        "RODAR-REVISAO-MULTIAGENTE.ps1",
        "ORQUESTRAR-IAS-PROJETO.ps1",
        "PUBLICAR-GIT.ps1",
        "importar_science.py",
        "etl_telegram_rede_optica.py"
    )

    $lines = foreach ($name in $files) {
        $path = Join-Path $PASTA $name
        if (Test-Path $path) {
            $f = Get-Item $path
            "- $name | atualizado em $($f.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')) | $([math]::Round($f.Length / 1kb, 1)) KB"
        } else {
            "- $name | ausente"
        }
    }

    return ($lines -join "`r`n")
}

function Save-Text {
    param(
        [string]$Path,
        [string]$Text
    )
    Set-Content -Path $Path -Value $Text -Encoding UTF8
}

Ensure-Dir $LOG_DIR
Ensure-Dir $HANDOFF_BASE
Ensure-Dir $SESSION_DIR
Ensure-Dir $RESP_DIR

if (-not (Test-Path $CONTEXTO)) {
    throw "Arquivo CONTEXTO_PROJETO.md nao encontrado em $CONTEXTO"
}

Write-Log "Gerando pacote de orquestracao multi-IA."

$git = Get-GitState -Skip:$SemGit
$keyFiles = Get-KeyFilesSummary
$contexto = Read-Tail -Path $CONTEXTO -Tail 260
$checklist = Read-Tail -Path $CHECKLIST -Tail 160
$geosite = Read-Tail -Path $GEOSITE -Tail 220
$pilotos = Read-Tail -Path $PILOTOS -Tail 180
$execucao = Read-Tail -Path $EXECUCAO -Tail 180
$geminiBase = Read-Tail -Path $GEMINI_MD -Tail 120
$agora = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

$ResumoPath = Join-Path $SESSION_DIR "00_RESUMO_SESSAO.md"
$ClaudePath = Join-Path $SESSION_DIR "01_CLAUDE_ARQUITETURA.md"
$GeminiPath = Join-Path $SESSION_DIR "02_GEMINI_VALIDACAO.md"
$CodexPath = Join-Path $SESSION_DIR "03_CODEX_IMPLEMENTACAO.md"
$DeepSeekPath = Join-Path $SESSION_DIR "04_DEEPSEEK_REVISAO.md"
$ManusPath = Join-Path $SESSION_DIR "05_MANUS_PRODUTO_UX.md"
$KiroPath = Join-Path $SESSION_DIR "06_KIRO_COORDENACAO.md"
$ChecklistPath = Join-Path $SESSION_DIR "07_CHECKLIST_COORDENACAO.md"
$ClaudeCoworkPath = Join-Path $SESSION_DIR "09_CLAUDE_COWORK_EXECUCAO.md"
$CodexCoworkPath = Join-Path $SESSION_DIR "10_CODEX_COWORK_EXECUCAO.md"
$QwenPath = Join-Path $SESSION_DIR "11_QWEN_REVISAO.md"
$StatePath = Join-Path $SESSION_DIR "estado_sessao.json"
$RespostaClaude = Join-Path $RESP_DIR "claude_resposta.md"
$RespostaGemini = Join-Path $RESP_DIR "gemini_resposta.md"
$RespostaDeepSeek = Join-Path $RESP_DIR "deepseek_resposta.md"
$RespostaManus = Join-Path $RESP_DIR "manus_resposta.md"
$RespostaKiro = Join-Path $RESP_DIR "kiro_resposta.md"
$RespostaClaudeCowork = Join-Path $RESP_DIR "claude_cowork_resposta.md"
$RespostaCodexCowork = Join-Path $RESP_DIR "codex_cowork_resposta.md"
$RespostaQwen = Join-Path $RESP_DIR "qwen_resposta.md"

$resumo = @"
# Sessao Multi-IA

Gerado em: $agora
Workspace: C:\FIBRA CADASTRO
Foco da rodada: $Foco
Branch atual: $($git.Branch)

## Objetivo
Este pacote serve para colocar varias IAs para trabalhar no mesmo projeto sem perder contexto, sem reanalise ampla e sem conflito de papel.

## Pasta de respostas
Cole os retornos das IAs em:
- $RespostaClaude
- $RespostaGemini
- $RespostaDeepSeek
- $RespostaManus
- $RespostaKiro
- $RespostaClaudeCowork
- $RespostaCodexCowork
- $RespostaQwen

Depois rode:
- C:\FIBRA CADASTRO\CONSOLIDAR-RETORNOS-IAS.ps1 -Sessao "$SESSION_DIR"

## Papéis
- Claude: arquitetura, banco, SQL, decisoes estruturais
- Codex: implementacao, integracao, correcoes incrementais
- Gemini: validacao, testes, endurecimento, consistencia
- DeepSeek: revisao logica, bugs ocultos, alternativas tecnicas, critique de baixo custo
- Manus: produto, UX operacional, benchmark, fluxo de campo, documentacao de operacao
- Kiro: coordenacao de backlog, sprint, priorizacao e encadeamento entre frentes
- Claude Cowork: execucao estruturada em paralelo, refinamento de entregas, apoio de arquitetura aplicada
- Codex Cowork: implementacao paralela, endurecimento, testes locais e acabamento
- Qwen: contraponto rapido, simplificacao e cobertura adicional de baixo custo

## Arquivos-chave
$keyFiles

## Git status
$($git.Status)

## Git log recente
$($git.Log)

## Contexto recente
$contexto
"@

$claude = @"
# Sessao Claude

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- $ResumoPath

## Papel
Voce e o agente de arquitetura.
Nao refatore o front local.
Nao repita exploracao ampla.
Entregue somente estrutura, SQL, riscos e ordem de implantacao.

## Foco desta rodada
$Foco

## O que revisar
1. Banco/Supabase e shape estrutural.
2. O que ainda falta para o sistema superar GeoSite com robustez.
3. O que esta provisório, arriscado ou arquiteturalmente fraco.
4. Fluxos de usuarios/login, inventario operacional, historico, ocupacao e persistencia multiusuario.

## Saida obrigatoria
1. Diagnostico estrutural
2. SQL executavel
3. Riscos
4. Ordem de implantacao
5. Handoff para Codex

## Contexto recente
$contexto
"@

$gemini = @"
# Sessao Gemini

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- $ResumoPath

## Papel
Voce e o agente de validacao, testes, hardening e consistencia.
Nao refatore arquitetura.
Nao assumir que algo funciona sem criterio pratico.

## Foco desta rodada
$Foco

## O que validar
1. Mapa, linhas, DGO, caixa de emenda e usabilidade.
2. Mobile/campo, sobreposicao, peso e regressao.
3. O que o GeoSite faz e ainda falta aqui.
4. O que existe aqui mas ainda esta meia-boca.
5. O que ja esta melhor que o GeoSite.

## Saida obrigatoria
1. Achados criticos
2. Achados altos
3. Achados medios
4. O que ja esta melhor
5. Proxima sprint recomendada
6. Handoff para Codex

## Regras base do Gemini
$geminiBase

## Checklist GeoSite gap
$geosite
"@

$codex = @"
# Sessao Codex

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- $ResumoPath

## Papel
Voce e o agente de implementacao.
Faca mudancas pequenas, seguras e incrementais.
Preserve comportamento que ja funciona.
Prepare o caminho para validacao do Gemini e revisao do Claude.

## Foco desta rodada
$Foco

## Regras
1. Inspecionar antes de alterar.
2. Evitar reescrita ampla.
3. Reduzir side effects.
4. Incluir validacao basica.
5. Atualizar contexto e handoff quando a mudanca for relevante.

## Saida obrigatoria apos codificar
- Plan
- Changes made
- Files changed
- Validation
- Risks
- Handoff
"@

$deepseek = @"
# Sessao DeepSeek

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- $ResumoPath

## Papel
Voce e o revisor tecnico-logico.
Seu trabalho e encontrar bugs, fragilidades, alternativas mais robustas e pontos ocultos de inconsistencia.
Nao refatore arquitetura inteira.
Nao substituir Claude ou Gemini.

## Foco desta rodada
$Foco

## O que revisar
1. Logica do front e fluxos principais.
2. Onde o sistema pode parecer funcionar, mas quebra em caso limite.
3. Pontos de performance, acoplamento fraco e regressao provavel.
4. O que esta "meia-boca" em implementacao e precisa endurecimento.

## Saida obrigatoria
1. Bugs provaveis
2. Fragilidades tecnicas
3. Melhorias de baixo risco
4. Casos limite que precisam teste
5. Handoff para Codex

## Contexto recente
$contexto
"@

$manus = @"
# Sessao Manus

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- $ResumoPath

## Papel
Voce e o agente de produto, UX operacional e benchmark.
Seu foco e a experiencia real de uso e comparacao com GeoSite e ferramentas similares.
Nao revisar SQL detalhado.
Nao refatorar codigo.

## Foco desta rodada
$Foco

## O que analisar
1. Uso real em campo e no celular.
2. Fluxo de operacao com mapa, linhas, caixa, DGO, rupturas e auditoria.
3. O que GeoSite/Google Earth/My Maps fazem melhor nesse fluxo.
4. O que nosso projeto ja faz melhor.
5. O que precisa virar prioridade de produto.

## Saida obrigatoria
1. Gaps funcionais
2. Gaps de usabilidade
3. O que ja esta melhor
4. Sprint de produto recomendada
5. Handoff para Codex

## Checklist GeoSite gap
$geosite
"@

$kiro = @"
# Sessao Kiro

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- $ResumoPath

## Papel
Voce e o coordenador operacional do projeto.
Nao reescreva arquitetura.
Nao implementar codigo.
Nao repetir benchmark amplo.

## Foco desta rodada
$Foco

## O que entregar
1. Backlog priorizado por impacto
2. Separacao por sprint
3. O que e critico
4. O que esta meia-boca
5. O que depende de banco
6. O que depende de front
7. O que ja esta bom
8. Riscos de seguir sem corrigir
9. Proxima acao objetiva para Codex
10. Proxima acao objetiva para Claude
11. Proxima acao objetiva para Gemini

## Regras
- Se algo existir no front, mas nao persistir oficialmente, classifique como incompleto.
- Se algo funcionar no desktop mas falhar no campo, classifique como problema real.
- Priorize velocidade de entrega com seguranca.
"@

$claudeCowork = @"
# Sessao Claude Cowork

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- $ResumoPath

## Papel
Voce e o agente de cowork de execucao.
Atue como apoio autonomo ao Claude principal e ao Codex.
Nao reanalise tudo do zero.
Nao devolver opiniao ampla.

## Foco desta rodada
$Foco

## O que fazer
1. Transformar lacunas em plano executavel de baixo atrito.
2. Refinar entregas por blocos pequenos e seguros.
3. Apontar dependencias entre banco, front e validacao.
4. Sugerir trilha de implementacao paralela.

## Saida obrigatoria
1. Entregas paralelizaveis
2. Riscos de conflito
3. Ordem de execucao
4. Handoff para Codex Cowork
5. Handoff para Codex principal
"@

$codexCowork = @"
# Sessao Codex Cowork

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- $ResumoPath

## Papel
Voce e o agente de implementacao paralelo.
Seu foco e acabamento, hardening, simplificacao e verificacao local.
Nao reescreva o produto.

## Foco desta rodada
$Foco

## O que fazer
1. Encontrar pequenas melhorias implementaveis em paralelo.
2. Endurecer UX, validacao e consistencia.
3. Preparar a base para validacao do Gemini.
4. Sugerir testes locais objetivos.

## Saida obrigatoria
1. Melhorias seguras
2. Ajustes pequenos de alto impacto
3. Testes a rodar
4. Handoff para Codex principal
"@

$qwen = @"
# Sessao Qwen

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- $ResumoPath

## Papel
Voce e o revisor de contraponto rapido.
Seu trabalho e achar pontos cegos, simplificacoes melhores e riscos de excesso de complexidade.
Nao repetir benchmark amplo.

## Foco desta rodada
$Foco

## O que revisar
1. O que esta complexo demais para o valor entregue.
2. O que falta para o sistema parecer superior ao GeoSite em uso real.
3. O que pode ser simplificado sem perder capacidade.
4. Onde a UX ou a logica ainda esta confusa.

## Saida obrigatoria
1. Pontos cegos
2. Simplificacoes recomendadas
3. Melhorias de produto de baixo custo
4. Handoff para Codex
"@

$checklistCoord = @"
# Checklist de Coordenacao

Gerado em: $agora
Foco: $Foco

## Antes de iniciar
- [ ] Ler CONTEXTO_PROJETO.md
- [ ] Ler o resumo da sessao
- [ ] Confirmar papel correto de cada IA

## Claude
- [ ] Entregou diagnostico estrutural
- [ ] Entregou SQL executavel
- [ ] Indicou riscos
- [ ] Indicou ordem de implantacao

## Gemini
- [ ] Validou mapa/linhas/DGO/caixa/usabilidade
- [ ] Validou mobile/campo
- [ ] Comparou com GeoSite
- [ ] Listou achados por severidade

## DeepSeek
- [ ] Revisou bugs provaveis e fragilidades
- [ ] Sugeriu melhorias de baixo risco
- [ ] Listou casos limite

## Manus
- [ ] Avaliou UX operacional
- [ ] Comparou com GeoSite/Google Earth
- [ ] Sugeriu sprint de produto

## Kiro
- [ ] Transformou o estado atual em backlog priorizado
- [ ] Separou banco, front e validacao
- [ ] Indicou proxima sprint e riscos

## Claude Cowork
- [ ] Refinou a trilha de execucao paralela
- [ ] Apontou dependencias entre frentes
- [ ] Entregou handoff de execucao

## Codex Cowork
- [ ] Listou melhorias seguras de implementacao paralela
- [ ] Listou testes e endurecimentos
- [ ] Entregou handoff para Codex principal

## Qwen
- [ ] Trouxe contrapontos e simplificacoes
- [ ] Apontou excesso de complexidade
- [ ] Indicou melhorias de baixo custo

## Codex
- [ ] Implementou sem reescrever tudo
- [ ] Rodou validacao basica
- [ ] Atualizou contexto quando necessario
- [ ] Preparou handoff curto para Gemini

## Git / publicacao
- [ ] Mudancas revisadas
- [ ] Commit intencional
- [ ] Publish so apos validacao minima
"@

$state = @{
    gerado_em = $agora
    foco = $Foco
    workspace = $PASTA
    branch = $git.Branch
    arquivos = @{
        resumo = $ResumoPath
        claude = $ClaudePath
        gemini = $GeminiPath
        codex = $CodexPath
        deepseek = $DeepSeekPath
        manus = $ManusPath
        kiro = $KiroPath
        checklist = $ChecklistPath
        claude_cowork = $ClaudeCoworkPath
        codex_cowork = $CodexCoworkPath
        qwen = $QwenPath
        respostas = @{
            pasta = $RESP_DIR
            claude = $RespostaClaude
            gemini = $RespostaGemini
            deepseek = $RespostaDeepSeek
            manus = $RespostaManus
            kiro = $RespostaKiro
            claude_cowork = $RespostaClaudeCowork
            codex_cowork = $RespostaCodexCowork
            qwen = $RespostaQwen
        }
    }
} | ConvertTo-Json -Depth 5

Save-Text -Path $ResumoPath -Text $resumo
Save-Text -Path $ClaudePath -Text $claude
Save-Text -Path $GeminiPath -Text $gemini
Save-Text -Path $CodexPath -Text $codex
Save-Text -Path $DeepSeekPath -Text $deepseek
Save-Text -Path $ManusPath -Text $manus
Save-Text -Path $KiroPath -Text $kiro
Save-Text -Path $ChecklistPath -Text $checklistCoord
Save-Text -Path $ClaudeCoworkPath -Text $claudeCowork
Save-Text -Path $CodexCoworkPath -Text $codexCowork
Save-Text -Path $QwenPath -Text $qwen
Save-Text -Path $StatePath -Text $state

Write-Log "Pacote criado em $SESSION_DIR"
Write-Log "Resumo: $ResumoPath"
Write-Log "Claude: $ClaudePath"
Write-Log "Gemini: $GeminiPath"
Write-Log "Codex: $CodexPath"
Write-Log "DeepSeek: $DeepSeekPath"
Write-Log "Manus: $ManusPath"
Write-Log "Kiro: $KiroPath"
Write-Log "Checklist: $ChecklistPath"
Write-Log "Claude Cowork: $ClaudeCoworkPath"
Write-Log "Codex Cowork: $CodexCoworkPath"
Write-Log "Qwen: $QwenPath"
Write-Log "Pasta de respostas: $RESP_DIR"

Write-Host ""
Write-Host "======================================"
Write-Host "  ORQUESTRACAO MULTI-IA GERADA"
Write-Host "======================================"
Write-Host ""
Write-Host "Sessao:" $SESSION_DIR
Write-Host "Resumo:" $ResumoPath
Write-Host "Claude:" $ClaudePath
Write-Host "Gemini:" $GeminiPath
Write-Host "Codex:" $CodexPath
Write-Host "DeepSeek:" $DeepSeekPath
Write-Host "Manus:" $ManusPath
Write-Host "Kiro:" $KiroPath
Write-Host "Checklist:" $ChecklistPath
Write-Host "Claude Cowork:" $ClaudeCoworkPath
Write-Host "Codex Cowork:" $CodexCoworkPath
Write-Host "Qwen:" $QwenPath
Write-Host "Respostas:" $RESP_DIR
Write-Host ""

if ($AbrirPasta) {
    Start-Process explorer.exe $SESSION_DIR | Out-Null
}
