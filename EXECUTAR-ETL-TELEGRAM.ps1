param(
    [string]$JsonPath
)

# =====================================================
# FUNÇÃO: LOCALIZAR JSON AUTOMATICAMENTE
# =====================================================
function Get-TelegramJson {

    $base = "C:\FIBRA CADASTRO"

    Write-Host "[INFO] Procurando result.json em:" $base

    $json = Get-ChildItem -Path $base -Filter "result.json" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $json) {
        Write-Host "[ERRO] Nenhum result.json encontrado dentro de C:\FIBRA CADASTRO" -ForegroundColor Red
        Write-Host "👉 Certifique-se de exportar o chat do Telegram (Desktop → Exportar dados)" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "[OK] JSON encontrado:" $json.FullName -ForegroundColor Green

    return $json.FullName
}

# =====================================================
# RESOLVER CAMINHO DO JSON
# =====================================================
if (-not $JsonPath -or -not (Test-Path $JsonPath)) {
    $JsonPath = Get-TelegramJson
}
else {
    Write-Host "[OK] Usando JSON informado:" $JsonPath -ForegroundColor Cyan
}

# =====================================================
# VALIDAÇÃO FINAL
# =====================================================
if (-not (Test-Path $JsonPath)) {
    Write-Host "[ERRO] Caminho final inválido:" $JsonPath -ForegroundColor Red
    exit 1
}