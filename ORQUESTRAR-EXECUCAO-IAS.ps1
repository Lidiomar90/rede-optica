param(
    [string]$Foco = "aprimoramento continuo do site, mobile, mapa, inventario operacional",
    [switch]$AbrirPasta,
    [switch]$SemGit
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$HUB = Join-Path $PASTA "ia_hub"
$INBOX = Join-Path $HUB "inbox"
$QUEUE = Join-Path $HUB "fila"
$SESSIONS = Join-Path $HUB "sessoes"
$STATE_DIR = Join-Path $HUB "estado"
$LOGS = Join-Path $HUB "logs"
$RUN_STAMP = Get-Date
$RAND = -join ((48..57) + (97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
$RUN_ID = "{0}_{1}" -f $RUN_STAMP.ToString("yyyyMMdd_HHmmss_fff"), $RAND
$TASK_ID = "tarefa_$RUN_ID"
$TASK_DIR = Join-Path $QUEUE $TASK_ID
$LOG_PATH = Join-Path $LOGS "hub_$RUN_ID.log"

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Log {
    param([string]$Mensagem, [string]$Nivel = "INFO")
    $linha = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Nivel, $Mensagem
    $linha | Tee-Object -FilePath $LOG_PATH -Append
}

function Save-Utf8 {
    param([string]$Path, [string]$Text)
    Set-Content -Path $Path -Value $Text -Encoding UTF8
}

Ensure-Dir $HUB
Ensure-Dir $INBOX
Ensure-Dir $QUEUE
Ensure-Dir $SESSIONS
Ensure-Dir $STATE_DIR
Ensure-Dir $LOGS
Ensure-Dir $TASK_DIR

Write-Log "Iniciando orquestracao do hub multi-IA."

$orqScript = Join-Path $PASTA "ORQUESTRAR-IAS-PROJETO.ps1"
if (-not (Test-Path $orqScript)) {
    throw "Script base nao encontrado: $orqScript"
}

$orqParams = @{
    Foco = $Foco
    SaidaDir = $SESSIONS
}
if ($AbrirPasta) { $orqParams.AbrirPasta = $true }
if ($SemGit) { $orqParams.SemGit = $true }

& $orqScript @orqParams

$sessao = Get-ChildItem -Path $SESSIONS -Directory |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $sessao) {
    throw "Nenhuma sessao gerada em $SESSIONS"
}

$resumo = Join-Path $sessao.FullName "00_RESUMO_SESSAO.md"
$claude = Join-Path $sessao.FullName "01_CLAUDE_ARQUITETURA.md"
$gemini = Join-Path $sessao.FullName "02_GEMINI_VALIDACAO.md"
$codex = Join-Path $sessao.FullName "03_CODEX_IMPLEMENTACAO.md"
$deepseek = Join-Path $sessao.FullName "04_DEEPSEEK_REVISAO.md"
$manus = Join-Path $sessao.FullName "05_MANUS_PRODUTO_UX.md"
$kiro = Join-Path $sessao.FullName "06_KIRO_COORDENACAO.md"
$checklist = Join-Path $sessao.FullName "07_CHECKLIST_COORDENACAO.md"
$claudeCowork = Join-Path $sessao.FullName "09_CLAUDE_COWORK_EXECUCAO.md"
$codexCowork = Join-Path $sessao.FullName "10_CODEX_COWORK_EXECUCAO.md"
$qwen = Join-Path $sessao.FullName "11_QWEN_REVISAO.md"
$respDir = Join-Path $sessao.FullName "respostas"
$consolidar = Join-Path $PASTA "CONSOLIDAR-RETORNOS-IAS.ps1"

$manifest = [ordered]@{
    task_id = $TASK_ID
    criado_em = (Get-Date).ToString("o")
    foco = $Foco
    workspace = $PASTA
    sessao = $sessao.FullName
    status = "aguardando_execucao_externa"
    arquivos = [ordered]@{
        resumo = $resumo
        claude = $claude
        gemini = $gemini
        codex = $codex
        deepseek = $deepseek
        manus = $manus
        kiro = $kiro
        claude_cowork = $claudeCowork
        codex_cowork = $codexCowork
        qwen = $qwen
        checklist = $checklist
        respostas = $respDir
        consolidar = $consolidar
    }
    agentes = @(
        @{nome="Claude"; papel="arquitetura, banco e SQL"; entrada=$claude; saida=(Join-Path $respDir "claude_resposta.md")}
        @{nome="Gemini"; papel="validacao, testes e hardening"; entrada=$gemini; saida=(Join-Path $respDir "gemini_resposta.md")}
        @{nome="Codex"; papel="implementacao e integracao"; entrada=$codex; saida="n/a"}
        @{nome="DeepSeek"; papel="revisao logica e fragilidades"; entrada=$deepseek; saida=(Join-Path $respDir "deepseek_resposta.md")}
        @{nome="Manus"; papel="produto, UX e benchmark"; entrada=$manus; saida=(Join-Path $respDir "manus_resposta.md")}
        @{nome="Kiro"; papel="coordenacao de backlog e sprints"; entrada=$kiro; saida=(Join-Path $respDir "kiro_resposta.md")}
        @{nome="Claude Cowork"; papel="execucao paralela e refinamento de entrega"; entrada=$claudeCowork; saida=(Join-Path $respDir "claude_cowork_resposta.md")}
        @{nome="Codex Cowork"; papel="implementacao paralela e hardening"; entrada=$codexCowork; saida=(Join-Path $respDir "codex_cowork_resposta.md")}
        @{nome="Qwen"; papel="contraponto rapido e simplificacao"; entrada=$qwen; saida=(Join-Path $respDir "qwen_resposta.md")}
    )
}

$manifestJson = $manifest | ConvertTo-Json -Depth 8
Save-Utf8 -Path (Join-Path $TASK_DIR "manifest.json") -Text $manifestJson

$readme = @"
# Hub Multi-IA

Tarefa: $TASK_ID
Criada em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Foco: $Foco

## Sessao gerada
- $($sessao.FullName)

## Como usar
1. Envie os arquivos de entrada para cada IA:
   - Claude: $claude
   - Gemini: $gemini
   - DeepSeek: $deepseek
   - Manus: $manus
   - Kiro: $kiro
   - Claude Cowork: $claudeCowork
   - Codex Cowork: $codexCowork
   - Qwen: $qwen
2. Cole as respostas em:
   - $respDir
3. Consolide tudo:
   - powershell -ExecutionPolicy Bypass -File "$consolidar" -Sessao "$($sessao.FullName)"

## Estado atual
- aguardando respostas externas

## Proximo passo do hub
- consolidar respostas
- transformar retorno em backlog
- apontar a proxima acao para Codex
"@
Save-Utf8 -Path (Join-Path $TASK_DIR "README.md") -Text $readme

$inboxMsg = @"
# Inbox Multi-IA

Nova tarefa criada para o projeto Rede Optica MG.

- Task id: $TASK_ID
- Foco: $Foco
- Sessao: $($sessao.FullName)
- Pasta de respostas: $respDir

Quando as IAs terminarem:
- rodar $consolidar -Sessao "$($sessao.FullName)"
"@
Save-Utf8 -Path (Join-Path $INBOX "inbox_$TASK_ID.md") -Text $inboxMsg

$hubState = [ordered]@{
    ultima_tarefa = $TASK_ID
    ultima_sessao = $sessao.FullName
    atualizado_em = (Get-Date).ToString("o")
    foco = $Foco
}
($hubState | ConvertTo-Json -Depth 5) | Set-Content -Path (Join-Path $STATE_DIR "hub_state.json") -Encoding UTF8

Write-Log "Sessao vinculada ao hub: $($sessao.FullName)"
Write-Log "Manifest criado em $TASK_DIR"

Write-Host ""
Write-Host "======================================"
Write-Host "  HUB MULTI-IA PREPARADO"
Write-Host "======================================"
Write-Host ""
Write-Host "Task id:" $TASK_ID
Write-Host "Sessao:" $sessao.FullName
Write-Host "Pasta respostas:" $respDir
Write-Host "Manifest:" (Join-Path $TASK_DIR "manifest.json")
Write-Host ""

if ($AbrirPasta) {
    Start-Process explorer.exe $TASK_DIR | Out-Null
}
