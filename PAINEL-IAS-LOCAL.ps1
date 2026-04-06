param(
    [switch]$AbrirNavegador,
    [switch]$DispararFrentes,
    [switch]$SemGit
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$HUB = Join-Path $PASTA "ia_hub"
$SESSOES = Join-Path $HUB "sessoes"
$FILA = Join-Path $HUB "fila"
$HTML_PATH = Join-Path $HUB "PAINEL_IA_LOCAL.html"
$DISPARAR = Join-Path $PASTA "DISPARAR-FRENTES-PROJETO.ps1"

function Save-Utf8 {
    param([string]$Path, [string]$Text)
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function To-FileUrl {
    param([string]$Path)
    return ("file:///" + ($Path -replace '\\','/'))
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

function Has-RealResponse {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $text = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if (-not $text) { return $false }
    if ($text -match 'Cole aqui a resposta') { return $false }
    return ($text.Trim().Length -gt 40)
}

function Get-Badge {
    param(
        [string]$Label,
        [string]$Kind
    )
    return "<span class='badge $Kind'>$Label</span>"
}

function Get-SessionMeta {
    param([string]$SessionDir)

    $summaryPath = Join-Path $SessionDir "00_RESUMO_SESSAO.md"
    $text = if (Test-Path $summaryPath) { Get-Content -Path $summaryPath -Raw -ErrorAction SilentlyContinue } else { "" }
    $focus = ""
    if ($text -match 'Foco da rodada:\s*(.+)') {
        $focus = $matches[1].Trim()
    }

    $focusLc = $focus.ToLowerInvariant()
    $front = "geral"
    $priority = "media"

    if ($focusLc -match 'login|rls|usuarios|autentic') {
        $front = "login e permissoes"
        $priority = "critica"
    } elseif ($focusLc -match 'banco|persistencia|continuidade|caixa_emenda|segmento_cabo|evento_ruptura|dgo') {
        $front = "banco e persistencia"
        $priority = "alta"
    } elseif ($focusLc -match 'mobile|campo|sobreposicao|ozmap|geosite|experiencia de rua|performance') {
        $front = "mobile e campo"
        $priority = "alta"
    } elseif ($focusLc -match 'historico|workflow|auditoria de manutencao|trilha') {
        $front = "historico e workflow"
        $priority = "alta"
    } elseif ($focusLc -match 'ocupacao|capacidade|fibras livres|portas|disponibilidade') {
        $front = "ocupacao e capacidade"
        $priority = "media"
    } elseif ($focusLc -match 'relatorios|dashboards|exportacoes|gerencial|produtividade') {
        $front = "relatorios e paineis"
        $priority = "media"
    }

    return @{
        Focus = $focus
        Front = $front
        Priority = $priority
    }
}

if ($DispararFrentes) {
    $params = @{}
    if ($SemGit) { $params.SemGit = $true }
    & $DISPARAR @params
}

$generatedAt = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$frontSummary = Get-LatestFrontSummary
$frontSummaryPath = if ($frontSummary) { $frontSummary.FullName } else { "" }
$frontSummaryLink = if ($frontSummaryPath) { To-FileUrl $frontSummaryPath } else { "#" }
$sessions = @(Get-LatestSessions)

$sessionCards = foreach ($sessao in $sessions) {
    $claude = Join-Path $sessao.FullName "01_CLAUDE_ARQUITETURA.md"
    $gemini = Join-Path $sessao.FullName "02_GEMINI_VALIDACAO.md"
    $codex = Join-Path $sessao.FullName "03_CODEX_IMPLEMENTACAO.md"
    $deepseek = Join-Path $sessao.FullName "04_DEEPSEEK_REVISAO.md"
    $manus = Join-Path $sessao.FullName "05_MANUS_PRODUTO_UX.md"
    $kiro = Join-Path $sessao.FullName "06_KIRO_COORDENACAO.md"
    $respostas = Join-Path $sessao.FullName "respostas"
    $claudeResp = Join-Path $respostas "claude_resposta.md"
    $geminiResp = Join-Path $respostas "gemini_resposta.md"
    $deepseekResp = Join-Path $respostas "deepseek_resposta.md"
    $manusResp = Join-Path $respostas "manus_resposta.md"
    $kiroResp = Join-Path $respostas "kiro_resposta.md"
    $consolidado = Join-Path $sessao.FullName "07_RELATORIO_CONSOLIDADO.md"
    $monitor = Join-Path $sessao.FullName "08_RESUMO_AUTOMATICO.md"
    $meta = Get-SessionMeta -SessionDir $sessao.FullName

    $readyCount = @(
        (Has-RealResponse $claudeResp),
        (Has-RealResponse $geminiResp),
        (Has-RealResponse $deepseekResp),
        (Has-RealResponse $manusResp),
        (Has-RealResponse $kiroResp)
    ) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count

    $badges = @()
    $badges += Get-Badge -Label $meta.Front -Kind "front"
    $badges += Get-Badge -Label $meta.Priority -Kind "priority-$($meta.Priority)"
    if (Test-Path $monitor) { $badges += Get-Badge -Label "monitorado" -Kind "ok" }
    if (Test-Path $consolidado) { $badges += Get-Badge -Label "consolidado" -Kind "info" }
    if ($readyCount -eq 5) { $badges += Get-Badge -Label "5/5 respostas" -Kind "ok" }
    elseif ($readyCount -gt 0) { $badges += Get-Badge -Label "$readyCount/5 respostas" -Kind "warn" }
    else { $badges += Get-Badge -Label "aguardando respostas" -Kind "muted" }

@"
      <article class="session-card">
        <div class="session-head">
          <h3>$($sessao.Name)</h3>
          <a class="pill" href="$(To-FileUrl $sessao.FullName)">abrir sessao</a>
        </div>
        <p class="session-path">$($sessao.FullName)</p>
        <p class="session-path">foco: $($meta.Focus)</p>
        <div class="badge-row">$($badges -join '')</div>
        <div class="agent-grid">
          <a class="agent-link claude" href="$(To-FileUrl $claude)">Claude</a>
          <a class="agent-link gemini" href="$(To-FileUrl $gemini)">Gemini</a>
          <a class="agent-link codex" href="$(To-FileUrl $codex)">Codex</a>
          <a class="agent-link deepseek" href="$(To-FileUrl $deepseek)">DeepSeek</a>
          <a class="agent-link manus" href="$(To-FileUrl $manus)">Manus</a>
          <a class="agent-link kiro" href="$(To-FileUrl $kiro)">Kiro</a>
        </div>
        <div class="session-actions">
          <a class="subtle-link" href="$(To-FileUrl $respostas)">pasta respostas</a>
          <a class="subtle-link" href="$(To-FileUrl $monitor)">resumo auto</a>
          <a class="subtle-link" href="$(To-FileUrl $consolidado)">consolidado</a>
        </div>
      </article>
"@
}

$sessionCardsText = if ($sessionCards.Count -gt 0) {
    $sessionCards -join "`r`n"
} else {
@"
      <article class="empty-state">
        <h3>Nenhuma sessao encontrada</h3>
        <p>Dispare as frentes primeiro e volte para este painel.</p>
      </article>
"@
}

$html = @"
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Painel Local das IAs</title>
  <style>
    :root{
      --bg:#071019;
      --panel:#0d1826;
      --panel-2:#122134;
      --line:#1f3550;
      --text:#e8f0ff;
      --muted:#8ea3c2;
      --accent:#38d8d2;
      --accent-2:#68f08e;
      --warn:#ffbf47;
      --claude:#ff8e5e;
      --gemini:#5ec8ff;
      --codex:#4de1a8;
      --deepseek:#b487ff;
      --manus:#ffd166;
      --kiro:#ff7ac6;
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      font-family:"Segoe UI",system-ui,sans-serif;
      background:radial-gradient(circle at top,#102238 0,#071019 56%);
      color:var(--text);
      min-height:100vh;
    }
    .shell{
      max-width:1380px;
      margin:0 auto;
      padding:24px;
      display:grid;
      gap:18px;
    }
    .hero,.sessions,.tools{
      background:rgba(13,24,38,.88);
      border:1px solid var(--line);
      border-radius:22px;
      box-shadow:0 24px 60px rgba(0,0,0,.24);
      backdrop-filter:blur(10px);
    }
    .hero{
      padding:24px;
      display:grid;
      gap:16px;
    }
    .hero-top{
      display:flex;
      justify-content:space-between;
      gap:16px;
      align-items:flex-start;
      flex-wrap:wrap;
    }
    h1,h2,h3,p{margin:0}
    h1{font-size:32px; line-height:1.05}
    .muted{color:var(--muted)}
    .stamp{
      color:var(--accent);
      font-weight:700;
      font-size:13px;
      letter-spacing:.14em;
      text-transform:uppercase;
    }
    .cta-row,.tool-grid,.agent-grid,.session-actions{
      display:flex;
      gap:12px;
      flex-wrap:wrap;
    }
    .btn,.pill,.agent-link,.subtle-link{
      text-decoration:none;
      border-radius:14px;
      border:1px solid var(--line);
      display:inline-flex;
      align-items:center;
      justify-content:center;
      gap:8px;
      min-height:44px;
      padding:0 14px;
      color:var(--text);
      background:var(--panel-2);
      transition:.18s ease;
    }
    .btn:hover,.pill:hover,.agent-link:hover,.subtle-link:hover{
      border-color:var(--accent);
      transform:translateY(-1px);
    }
    .btn.primary{
      background:linear-gradient(135deg,#18314d,#15394c);
      border-color:#245479;
    }
    .btn.accent{
      background:linear-gradient(135deg,#123d3f,#194e4a);
      border-color:#2f9f97;
    }
    .sessions{
      padding:22px;
      display:grid;
      gap:16px;
    }
    .sessions-head{
      display:flex;
      justify-content:space-between;
      gap:16px;
      align-items:center;
      flex-wrap:wrap;
    }
    .session-list{
      display:grid;
      gap:14px;
    }
    .session-card,.empty-state{
      background:rgba(18,33,52,.9);
      border:1px solid var(--line);
      border-radius:18px;
      padding:16px;
      display:grid;
      gap:12px;
    }
    .session-head{
      display:flex;
      justify-content:space-between;
      gap:12px;
      align-items:center;
      flex-wrap:wrap;
    }
    .session-path{
      color:var(--muted);
      font-size:13px;
      word-break:break-word;
    }
    .badge-row{
      display:flex;
      gap:8px;
      flex-wrap:wrap;
    }
    .badge{
      display:inline-flex;
      align-items:center;
      min-height:28px;
      padding:0 10px;
      border-radius:999px;
      border:1px solid var(--line);
      font-size:12px;
      font-weight:700;
      letter-spacing:.03em;
      text-transform:uppercase;
    }
    .badge.ok{background:rgba(104,240,142,.12); border-color:rgba(104,240,142,.35); color:#9cf7b8}
    .badge.warn{background:rgba(255,191,71,.12); border-color:rgba(255,191,71,.35); color:#ffd27f}
    .badge.info{background:rgba(94,200,255,.12); border-color:rgba(94,200,255,.35); color:#9fdcff}
    .badge.muted{background:rgba(142,163,194,.12); border-color:rgba(142,163,194,.25); color:#a9b8d0}
    .badge.front{background:rgba(56,216,210,.12); border-color:rgba(56,216,210,.28); color:#8ef3ef}
    .badge.priority-critica{background:rgba(255,92,92,.12); border-color:rgba(255,92,92,.35); color:#ff9d9d}
    .badge.priority-alta{background:rgba(255,191,71,.12); border-color:rgba(255,191,71,.35); color:#ffd27f}
    .badge.priority-media{background:rgba(142,163,194,.12); border-color:rgba(142,163,194,.25); color:#b8c5d8}
    .tools{
      padding:22px;
      display:grid;
      gap:16px;
    }
    .tool-grid{
      display:grid;
      grid-template-columns:repeat(auto-fit,minmax(210px,1fr));
    }
    .tool-card{
      background:rgba(18,33,52,.9);
      border:1px solid var(--line);
      border-radius:18px;
      padding:16px;
      display:grid;
      gap:12px;
    }
    .agent-link{font-weight:700}
    .claude{border-color:rgba(255,142,94,.4)}
    .gemini{border-color:rgba(94,200,255,.4)}
    .codex{border-color:rgba(77,225,168,.4)}
    .deepseek{border-color:rgba(180,135,255,.4)}
    .manus{border-color:rgba(255,209,102,.45)}
    .kiro{border-color:rgba(255,122,198,.45)}
    @media (max-width: 820px){
      .shell{padding:14px}
      .hero,.sessions,.tools{border-radius:18px}
      h1{font-size:26px}
    }
  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <div class="hero-top">
        <div>
          <div class="stamp">Centro local das IAs</div>
          <h1>Trabalhar com todas as IAs direto no PC</h1>
          <p class="muted">Painel local para disparar frentes, abrir prompts certos e acompanhar as sessoes mais recentes do hub.</p>
        </div>
        <div class="muted">Gerado em $generatedAt</div>
      </div>
      <div class="cta-row">
        <a class="btn primary" href="$(To-FileUrl "C:\FIBRA CADASTRO\DISPARAR-FRENTES-PROJETO.bat")">disparar frentes</a>
        <a class="btn accent" href="$(To-FileUrl "C:\FIBRA CADASTRO\MONITORAR-HUB-IAS.bat")">monitorar e publicar</a>
        <a class="btn" href="$(To-FileUrl "C:\FIBRA CADASTRO\ORQUESTRAR-EXECUCAO-IAS.bat")">tarefa unica</a>
        <a class="btn" href="$(To-FileUrl "C:\FIBRA CADASTRO\CONSOLIDAR-RETORNOS-IAS.bat")">consolidar retornos</a>
      </div>
    </section>

    <section class="tools">
      <div class="sessions-head">
        <div>
          <div class="stamp">Acesso rapido</div>
          <h2>Arquivos e pontos de entrada</h2>
        </div>
      </div>
      <div class="tool-grid">
        <article class="tool-card">
          <h3>Ultimo resumo de frentes</h3>
          <p class="muted">Visao geral da ultima rodada paralela aberta no hub.</p>
          <a class="btn" href="$frontSummaryLink">abrir resumo</a>
        </article>
        <article class="tool-card">
          <h3>Hub local</h3>
          <p class="muted">Pasta central com sessoes, fila, inbox e respostas.</p>
          <a class="btn" href="$(To-FileUrl $HUB)">abrir ia_hub</a>
        </article>
        <article class="tool-card">
          <h3>Workspace</h3>
          <p class="muted">Abrir a pasta principal do projeto.</p>
          <a class="btn" href="$(To-FileUrl $PASTA)">abrir projeto</a>
        </article>
      </div>
    </section>

    <section class="sessions">
      <div class="sessions-head">
        <div>
          <div class="stamp">Sessoes recentes</div>
          <h2>Prompts prontos por IA</h2>
        </div>
        <div class="muted">Claude, Gemini, DeepSeek, Manus, Kiro e Codex</div>
      </div>
      <div class="session-list">
$sessionCardsText
      </div>
    </section>
  </main>
</body>
</html>
"@

Save-Utf8 -Path $HTML_PATH -Text $html

Write-Host ""
Write-Host "======================================"
Write-Host " PAINEL HTML LOCAL DAS IAS PRONTO"
Write-Host "======================================"
Write-Host ""
Write-Host "Painel HTML:" $HTML_PATH
Write-Host ""

if ($AbrirNavegador) {
    Start-Process $HTML_PATH | Out-Null
}
