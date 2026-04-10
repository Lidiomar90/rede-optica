param(
  [string]$Url = 'https://lidiomar90.github.io/rede-optica/mapa-rede-optica.html'
)

$ErrorActionPreference = 'Stop'

$outDir = 'C:\FIBRA CADASTRO\OUTPUT'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$html = Invoke-WebRequest -Uri $Url -UseBasicParsing
$favicon = Invoke-WebRequest -Uri 'https://lidiomar90.github.io/rede-optica/favicon.svg' -UseBasicParsing
$content = $html.Content

$checks = [ordered]@{
  html_status_ok          = ($html.StatusCode -eq 200)
  favicon_status_ok       = ($favicon.StatusCode -eq 200)
  html_has_favicon        = ($content -match 'favicon\.svg')
  html_has_mobile_search  = ($content -match 'openMobileSearch\(\)')
  html_has_caixa_fallback = ($content -match 'fetchCaixasMapaSafe')
  html_has_span_cache     = ($content -match 'SPAN_COUNT_KEY')
}

$result = [ordered]@{
  checked_at = (Get-Date).ToString('o')
  url        = $Url
  checks     = $checks
  ok         = -not ($checks.Values -contains $false)
}

$json = $result | ConvertTo-Json -Depth 5
$json | Set-Content -LiteralPath (Join-Path $outDir 'teste_site_publicado.json') -Encoding UTF8
$json
