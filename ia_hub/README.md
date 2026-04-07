# IA Hub — Rede Óptica MG

Centro operacional para múltiplas IAs no projeto Rede Óptica MG.

---

## Modo Autônomo (NOVO — recomendado)

O `worker_autonomo.py` processa tarefas da fila **automaticamente**, sem copiar/colar em interfaces web.

### Iniciar

```
C:\FIBRA CADASTRO\INICIAR-WORKER-AUTONOMO.bat
```

Escolha o modo:
- `1` — processa uma vez e sai
- `2` — loop a cada 60 segundos (recomendado)
- `5` — agenda no Windows para iniciar com o computador

### Pré-requisito: chaves de API

Crie o arquivo `C:\FIBRA CADASTRO\privado\chaves_ia.env` com pelo menos uma chave:

```
DEEPSEEK_KEY=sk-...              # pago, mais rápido
OPENROUTER_KEY=sk-or-v1-...     # gratuito (deepseek-r1:free)
OPENAI_KEY=sk-...               # pago, fallback
```

### Como adicionar uma tarefa

Crie um arquivo `.md` em `fila/` com o prompt desejado. Exemplo:

```
fila/minha_tarefa.md
```
Conteúdo: qualquer pergunta ou instrução técnica em português.

O worker vai processar e salvar a resposta em:
```
inbox/inbox_minha_tarefa.md
```

### Estado do worker

Acesse `hub_state.json` para ver estatísticas:
- `ultima_execucao` — quando rodou pela última vez
- `total_processado` — total de tarefas processadas
- `backend` / `modelo` — qual IA está sendo usada

---

## Estrutura de pastas

| Pasta | Conteúdo |
|-------|----------|
| `fila/` | Tarefas pendentes (`.md` simples ou pastas de sessão com `manifest.json`) |
| `inbox/` | Respostas geradas pela IA |
| `sessoes/` | Sessões completas criadas pelo orquestrador multi-IA |
| `estado/` | Estado resumido do hub |
| `logs/` | Logs de execução do worker |
| `alerts/` | Alertas gerados pelo monitoramento |

---

## Fluxo manual (alternativo)

1. Gerar pacotes de contexto:
   - `ORQUESTRAR-EXECUCAO-IAS.ps1`
2. Enviar arquivos para Claude, Gemini, DeepSeek, etc.
3. Colar respostas em `respostas/` da sessão
4. Consolidar:
   - `CONSOLIDAR-RETORNOS-IAS.ps1 -Sessao "<pasta>"`
5. Monitorar:
   - `MONITORAR-HUB-IAS.ps1`

---

## Objetivo

- Contexto único entre todos os agentes
- Papéis claros por IA (análise, validação, implementação, revisão)
- Rastreabilidade de decisões via manifest.json
- Operação autônoma sem intervenção manual
