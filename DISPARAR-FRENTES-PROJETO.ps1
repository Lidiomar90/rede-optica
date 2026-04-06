param(
    [switch]$AbrirPastas,
    [switch]$SemGit
)

$ErrorActionPreference = "Stop"

$PASTA = "C:\FIBRA CADASTRO"
$SCRIPT = Join-Path $PASTA "ORQUESTRAR-EXECUCAO-IAS.ps1"

if (-not (Test-Path $SCRIPT)) {
    throw "Script nao encontrado: $SCRIPT"
}

$frentes = @(
    @{
        Nome = "01_banco_persistencia"
        Foco = "banco oficial, persistencia operacional, dgo, caixa_emenda, segmento_cabo, evento_ruptura, flags, continuidade"
    },
    @{
        Nome = "02_login_permissoes"
        Foco = "login, usuarios, RLS, autenticacao, perfis, seguranca de acesso, fluxo administrativo"
    },
    @{
        Nome = "03_historico_workflow"
        Foco = "historico de alteracoes, auditoria de manutencao, workflow operacional, estados de tratamento, trilha de mudancas"
    },
    @{
        Nome = "04_ocupacao_capacidade"
        Foco = "ocupacao, capacidade, fibras livres, portas, disponibilidade, indicadores tecnicos, dgo e caixa"
    },
    @{
        Nome = "05_mobile_ux_campo"
        Foco = "mobile, campo, performance, sobreposicao, objetividade da tela, geosite, ozmap, experiencia de rua"
    },
    @{
        Nome = "06_relatorios_paineis"
        Foco = "relatorios operacionais, exportacoes, dashboards, pendencias por regiao, produtividade, acompanhamento gerencial"
    }
)

$criadas = @()
foreach ($frente in $frentes) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host " Disparando frente: $($frente.Nome)" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""

    $params = @{
        Foco = $frente.Foco
    }
    if ($AbrirPastas) { $params.AbrirPasta = $true }
    if ($SemGit) { $params.SemGit = $true }

    & $SCRIPT @params | Out-Host

    $sessao = Get-ChildItem -Path (Join-Path $PASTA "ia_hub\sessoes") -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    $criadas += [pscustomobject]@{
        frente = $frente.Nome
        foco = $frente.Foco
        sessao = $sessao.FullName
    }

    Start-Sleep -Milliseconds 200
}

$resumoPath = Join-Path $PASTA ("ia_hub\fila\frentes_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".md")
$texto = @"
# Frentes Paralelas Disparadas

Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")

As seguintes frentes foram abertas no hub:

$(
($criadas | ForEach-Object {
"- $($_.frente)
  - foco: $($_.foco)
  - sessao: $($_.sessao)"
}) -join "`r`n"
)

## Proximo passo
1. Enviar os prompts de cada sessao para as IAs correspondentes.
2. Colar as respostas em `respostas/`.
3. Rodar o monitor do hub para consolidar e publicar quando seguro.
"@

Set-Content -Path $resumoPath -Value $texto -Encoding UTF8

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host " FRENTES PARALELAS CRIADAS" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:" $resumoPath
Write-Host ""
