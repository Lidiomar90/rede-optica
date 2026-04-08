param(
  [string]$Workspace = "C:\FIBRA CADASTRO"
)

$ErrorActionPreference = "Stop"

$htmlPath = Join-Path $Workspace "mapa-rede-optica.html"
$sqlPath = Join-Path $Workspace "CORRECAO_USUARIOS_RLS_RPC.sql"
$tmpJs = Join-Path $Workspace "tmp_smoke_front_check.js"

if (-not (Test-Path $htmlPath)) {
  throw "Arquivo principal nao encontrado: $htmlPath"
}

$html = Get-Content -Path $htmlPath -Raw
$start = $html.IndexOf('<script>')
$end = $html.LastIndexOf('</script>')
if ($start -lt 0 -or $end -lt 0) {
  throw "Bloco <script> principal nao encontrado no HTML."
}

$js = $html.Substring($start + 8, $end - ($start + 8))
Set-Content -Path $tmpJs -Value $js -Encoding UTF8

$checks = @(
  @{name='probeUserBackend'; pattern='function probeUserBackend\('},
  @{name='focusIncidentMap'; pattern='function focusIncidentMap\('},
  @{name='renderIncidentImpact'; pattern='function renderIncidentImpact\('},
  @{name='presetCriticos'; pattern="\['criticos','Críticos'\]"},
  @{name='authFetchUsuario'; pattern='async function authFetchUsuario\('},
  @{name='loadMap'; pattern='async function loadMap\('},
  @{name='loadUsuarios'; pattern='async function loadUsuarios\('}
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($check in $checks) {
  $ok = [regex]::IsMatch($html, $check.pattern)
  $results.Add([pscustomobject]@{
    check = $check.name
    ok = $ok
  })
}

$syntaxOk = $true
$syntaxMsg = "OK"
try {
  node --check $tmpJs | Out-Null
} catch {
  $syntaxOk = $false
  $syntaxMsg = $_.Exception.Message
}

Remove-Item -LiteralPath $tmpJs -ErrorAction SilentlyContinue

$summary = [ordered]@{
  generated_at = (Get-Date).ToString("o")
  html = $htmlPath
  sql_exists = (Test-Path $sqlPath)
  syntax_ok = $syntaxOk
  syntax_message = $syntaxMsg
  checks = $results
  failed_checks = @($results | Where-Object { -not $_.ok } | ForEach-Object { $_.check })
}

$json = $summary | ConvertTo-Json -Depth 6
$out = Join-Path $Workspace "OUTPUT\smoke_front_latest.json"
$outDir = Split-Path $out -Parent
if (-not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
Set-Content -Path $out -Value $json -Encoding UTF8

if (-not $syntaxOk -or $summary.failed_checks.Count -gt 0) {
  Write-Host "SMOKE_FRONT: FALHA"
  Write-Host $json
  exit 1
}

Write-Host "SMOKE_FRONT: OK"
Write-Host $json
