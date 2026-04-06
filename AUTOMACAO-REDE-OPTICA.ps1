param(
    [switch]$Etl,
    [switch]$Science,
    [switch]$Publish,
    [switch]$Tudo,
    [switch]$CommitEtl,
    [string]$JsonPath,
    [string]$SbKey
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$LOG_DIR = Join-Path $PASTA "logs"
$ETL_SCRIPT = Join-Path $PASTA "etl_telegram_rede_optica.py"
$SCIENCE_SCRIPT = Join-Path $PASTA "importar_science.py"
$PUBLICAR_SCRIPT = Join-Path $PASTA "PUBLICAR-GIT.ps1"
$PYTHON = "python"

if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

$RunId = Get-Date -Format "yyyyMMdd_HHmmss"
$LogPath = Join-Path $LOG_DIR "automacao_rede_optica_$RunId.log"

function Write-Log {
    param(
        [string]$Mensagem,
        [string]$Nivel = "INFO"
    )

    $linha = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Nivel, $Mensagem
    $linha | Tee-Object -FilePath $LogPath -Append
}

function Test-Command {
    param([string]$Nome)
    return [bool](Get-Command $Nome -ErrorAction SilentlyContinue)
}

function Invoke-Step {
    param(
        [string]$Nome,
        [scriptblock]$Acao
    )

    Write-Log "Iniciando: $Nome"
    & $Acao
    Write-Log "Concluido: $Nome"
}

function Ensure-SbKey {
    if ($SbKey) {
        $env:SB_KEY = $SbKey
    }
    if (-not $env:SB_KEY) {
        throw "SB_KEY nao definida. Use -SbKey ou configure `$env:SB_KEY antes de executar."
    }
}

function Resolve-JsonPath {
    if ($JsonPath -and (Test-Path $JsonPath)) {
        return $JsonPath
    }

    $json = Get-ChildItem -Path $PASTA -Filter "result.json" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $json) {
        throw "Nenhum result.json encontrado em $PASTA"
    }

    return $json.FullName
}

function Run-Etl {
    Ensure-SbKey
    $jsonFinal = Resolve-JsonPath
    $args = @($ETL_SCRIPT, "--input", $jsonFinal)
    if ($CommitEtl) {
        $args += "--commit"
    } else {
        $args += "--dry-run"
    }

    Write-Log "Executando ETL com arquivo: $jsonFinal"
    & $PYTHON @args 2>&1 | Tee-Object -FilePath $LogPath -Append
    if ($LASTEXITCODE -ne 0) {
        throw "ETL retornou codigo $LASTEXITCODE"
    }
}

function Run-Science {
    Ensure-SbKey
    Write-Log "Executando importacao Science"
    & $PYTHON $SCIENCE_SCRIPT 2>&1 | Tee-Object -FilePath $LogPath -Append
    if ($LASTEXITCODE -ne 0) {
        throw "Importacao Science retornou codigo $LASTEXITCODE"
    }
}

function Run-Publish {
    Write-Log "Executando publicacao GitHub Pages"
    powershell -ExecutionPolicy Bypass -File $PUBLICAR_SCRIPT 2>&1 | Tee-Object -FilePath $LogPath -Append
    if ($LASTEXITCODE -ne 0) {
        throw "Publicacao retornou codigo $LASTEXITCODE"
    }
}

Set-Location $PASTA

if (-not (Test-Command $PYTHON)) {
    throw "Python nao encontrado no PATH."
}

if ($Tudo) {
    $Etl = $true
    $Science = $true
    $Publish = $true
}

if (-not ($Etl -or $Science -or $Publish)) {
    Write-Log "Nenhuma acao escolhida. Use -Etl, -Science, -Publish ou -Tudo." "WARN"
    exit 1
}

try {
    Write-Log "Automacao iniciada. Log: $LogPath"

    if ($Etl) {
        Invoke-Step "ETL Telegram" { Run-Etl }
    }
    if ($Science) {
        Invoke-Step "Importacao Science" { Run-Science }
    }
    if ($Publish) {
        Invoke-Step "Publicacao GitHub Pages" { Run-Publish }
    }

    Write-Log "Automacao finalizada com sucesso."
}
catch {
    Write-Log $_.Exception.Message "ERROR"
    throw
}
