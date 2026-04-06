# Resumo Multiagente

Gerado em: 05/04/2026 19:18:05
Workspace: C:\FIBRA CADASTRO
Branch atual: main

## Arquivos-chave
- mapa-rede-optica.html | atualizado em 05/04/2026 19:12:24 | 199.6 KB
- CONTEXTO_PROJETO.md | atualizado em 05/04/2026 19:17:19 | 16.5 KB
- CHECKLIST_QUALIDADE_E_PUBLICACAO.md | atualizado em 05/04/2026 17:08:03 | 7.3 KB
- PILOTOS_E2E_OPERACIONAIS.md | atualizado em 05/04/2026 17:08:47 | 5.8 KB
- EXECUCAO_TESTES_E2E.md | atualizado em 05/04/2026 17:13:44 | 1.2 KB
- AUTOMACAO-REDE-OPTICA.ps1 | atualizado em 05/04/2026 14:51:32 | 3.4 KB
- PUBLICAR-GIT.ps1 | atualizado em 05/04/2026 16:58:22 | 6.1 KB
- importar_science.py | atualizado em 05/04/2026 16:26:09 | 9.2 KB

## Git status
M CONTEXTO_PROJETO.md
 M mapa-rede-optica.html
?? .gitignore.bkp_20260405_133452
?? AUTOMACAO-REDE-OPTICA.bat
?? AUTOMACAO-REDE-OPTICA.ps1
?? CHECKLIST_QUALIDADE_E_PUBLICACAO.md
?? Consulta_Science_-_Site_01_10_25_V1.xls
?? EXECUCAO_TESTES_E2E.md
?? INVENTARIO_OPERACIONAL_MODULO1.md
?? PILOTOS_E2E_OPERACIONAIS.md
?? PUBLICAR-GIT.ps1.bkp_20260405_133452
?? PUBLICAR-GIT.ps1.bkp_20260405_134817
?? RODAR-REVISAO-MULTIAGENTE.bat
?? RODAR-REVISAO-MULTIAGENTE.ps1
?? __pycache__/
?? agente_config.json
?? agente_rede_optica_guardiao.py
?? handoffs/
?? importar_science.py
?? logs_agente/

## Git log recente
764f05a Rede Optica MG - 05/04/2026 19:09
ef1c188 Rede Optica MG - 05/04/2026 19:08
adfd964 Rede Optica MG - 05/04/2026 19:04
9afda97 Rede Optica MG - 05/04/2026 19:03
dd6edca Rede Optica MG - 05/04/2026 17:52

## Contexto recente
- `id`, `node_a_id`, `node_b_id`, `tipo_edge`, `ativo_id`, `ativo_tabela`, `peso_distancia_m`, `peso_atenuacao`, `status`, `bidirecional`, `camada`, `geom`
- UNIQUE em `(ativo_tabela, ativo_id)` â€” constraint `network_edges_ativo_unico` JA EXISTE (BUG 1 resolvido)
- `tipo_edge` aceita: 'cabo', 'trechos_dwdm', **'cabo_dgo'** (novo)

---

## VIEWS E RPCS DO BANCO

### Views
| View | Descricao |
|------|-----------|
| `vw_sites_lookup` | DISTINCT ON (codigo), prioridade backbone>metro_alta>metro_dist>acesso. Usada pelo ETL REST. 16.962 registros. |
| `vw_dgo_incompleto` | DGOs com rack, bastidor, modelo, fabricante ou nome faltando. Para auditoria. |
| `vw_dgo_sem_conexao` | DGOs ativos sem nenhum enlace nem cabo conectado. Para ativos orfaos. |
| `vw_continuidade_caixa_dgo_site` | Cadeia: caixa_rede â†” DGO â†” site. Segmentos: cabo_dgo_a_site_b, cabo_site_a_dgo_b, cabo_dgo_a_dgo_b, caixa_mesmo_site_dgo. |
| `vw_continuidade_completa` | Segmentos resolvidos: ponta A/B = site\|dgo\|caixa_emenda. lat/lng do centroide. REST: /rest/v1/vw_continuidade_completa |
| `vw_rupturas_abertas` | Eventos ativos (aberto/investigando/em_reparo) com lat/lng e minutos_aberto. REST: ?order=abertura_em.desc |
| `vw_caixas_emenda_mapa` | Caixas de emenda com lat/lng para mapa. REST: /rest/v1/vw_caixas_emenda_mapa |

### Funcoes / RPCs
| Funcao | Assinatura | Descricao |
|--------|-----------|-----------|
| `fn_tracer_bfs` | `(p_node_inicio uuid, p_node_fim uuid, p_max_hops int)` | BFS em network_nodes/edges. NAO chamado pelo HTML ainda (BUG 2). |
| `fn_sync_nodes_from_sites` | `()` | Sincroniza sites â†’ network_nodes. Idempotente. |
| `fn_sync_nodes_from_dgo` | `()` | Sincroniza DGOs â†’ network_nodes. DGO herda geom do site. Idempotente. |
| `fn_sync_edges_from_cabos` | `()` | Sincroniza cabos (site_aâ†’site_b) â†’ network_edges. |
| `fn_sync_edges_from_cabos_dgo` | `()` | Sincroniza cabos com DGO como ponta â†’ network_edges. Tipos: DGOâ†’Site, Siteâ†’DGO, DGOâ†’DGO. |
| `fn_sync_nodes_from_caixa_emenda` | `()` | Sincroniza caixas_emenda com geo â†’ network_nodes. |
| `ponto_no_cabo` | `(cabo_id uuid, distancia_m numeric)` | Calcula lat/lng no cabo para OTDR. Chamado pelo HTML. |
| `fn_impacto_cabo` | â€” | Analise de impacto por cabo. |
| `fn_impacto_enlace` | â€” | Analise de impacto por enlace. |

### Triggers ativos
| Trigger | Tabela | Acao |
|---------|--------|------|
| `trg_dgo_atualizado_em` | `dgo` | Atualiza `atualizado_em` antes de UPDATE |
| `trg_dgo_sync_node` | `dgo` | Sincroniza `network_nodes` apos INSERT/UPDATE |
| `trg_ce_sync_node` | `caixa_emenda` | Sincroniza `network_nodes` se tiver geo |
| `trg_er_codigo` | `evento_ruptura` | Gera codigo RUP-AAAA-NNNN automaticamente |

### RLS Policies relevantes
| Tabela | Policy | Regra |
|--------|--------|-------|
| `sites` | `leitura_publica_sites` | SELECT para public â€” anon le tudo |
| `sites` | `escrita_autenticada_sites` | ALL exige `check_app_token()` |
| `dgo` | `dgo_leitura_publica` | SELECT para public |
| `dgo` | `dgo_escrita_autenticada` | ALL exige `check_app_token()` |

---

## ARQUIVOS LOCAIS EM C:\FIBRA CADASTRO

| Arquivo | Estado | Observacao |
|---------|--------|------------|
| `mapa-rede-optica.html` | Ativo | Mapa principal. Tracer Aâ†’B usa bbox (BUG 2 pendente). |
| `dashboard.html` | Ativo | Dashboard de metricas. |
| `ia-assistente.html` | Ativo | Interface IA. |
| `auditoria-revisao.html` | Ativo | Auditoria de cadastro. |
| `index.html` | Ativo | Portal de entrada. |
| `etl_telegram_rede_optica.py` | **MODIFICADO** | Agora usa `vw_sites_lookup` (resolve MGSAG/VNZ/SAG). |
| `PUBLICAR-GIT.ps1` | **CORRIGIDO** | *.apk adicionado ao $ignorePatterns. |
| `PUBLICAR.bat` | Ativo | Chama PUBLICAR-GIT.ps1. Executar localmente para publicar. |
| `privado/.github_token` | Seguro | Nunca vai para git. |
| `.gitignore` | OK | telegram/, *.dwg, *.apk, *.zip, privado/, .env, *.key |

---

## HISTORICO DE BUGS

### RESOLVIDO â€” BUG 1: network_edges sem UNIQUE constraint
- **Era:** 311 duplicatas em network_edges (1.643 rows, 1.332 unicos para enlaces)
- **Status:** RESOLVIDO â€” constraint `network_edges_ativo_unico UNIQUE(ativo_tabela, ativo_id)` existe
- **network_edges agora:** 5.649 rows, 0 duplicatas

### PENDENTE â€” BUG 2: execRast() nao usa fn_tracer_bfs
**Problema:** Botao "Rastrear rota Aâ†’B" faz bbox geografico dos cabos. Nao chama o RPC `fn_tracer_bfs`.

**O que Codex precisa implementar em `execRast()` no HTML:**
```javascript
// 1. Resolver node_id para site A e B
const resA = await fetch(`${SU}/rest/v1/network_nodes?ativo_tabela=eq.sites&ativo_id=eq.${sA.id}&select=id`, {headers:RH}).then(r=>r.json());
const nodeA = resA[0]?.id;
const resB = await fetch(`${SU}/rest/v1/network_nodes?ativo_tabela=eq.sites&ativo_id=eq.${sB.id}&select=id`, {headers:RH}).then(r=>r.json());
const nodeB = resB[0]?.id;
if(!nodeA || !nodeB){ toast('Site nao encontrado no grafo','er'); return; }

// 2. Chamar BFS
const caminho = await fetch(`${SU}/rest/v1/rpc/fn_tracer_bfs`, {
  method:'POST',
  headers:{...RH,'Content-Type':'application/json'},
  body: JSON.stringify({p_node_inicio: nodeA, p_node_fim: nodeB, p_max_hops: 30})
}).then(r=>r.json());

// 3. Para cada step com ativo_tabela='cabos', buscar em allC e desenhar trajeto
```

### PENDENTE â€” BUG 3: fn_tracer_bfs assimetrico no bidirecional (baixa urgencia)
```sql
-- Atual (primeiro ramo nao checa bidirecional):
JOIN network_edges e ON (
  e.node_a_id = b.b_node_id
  OR (e.bidirecional AND e.node_b_id = b.b_node_id)
)
-- Nao afeta hoje (todos cabos sao bidirecional=true)
```

### PENDENTE â€” BUG 4: network_edges sem arestas de cabos
- `fn_sync_edges_from_cabos()` insere com `ativo_tabela='cabos'` mas ha 0 edges de cabos
- Diagnosticar: `SELECT COUNT(*) FROM cabos WHERE site_a_id IS NOT NULL AND site_b_id IS NOT NULL AND trajeto IS NOT NULL AND inativo_em IS NULL;`
- Se > 0, executar: `SELECT fn_sync_edges_from_cabos();`

---

## FLUXO DO ETL

**Variaveis de ambiente:**
```powershell
$env:SB_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtcXhoem1qeHByaHZ5cXdscXZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MzYxMzcsImV4cCI6MjA5MDMxMjEzN30.ohD97pPgtpxyHmCjWYKz-OWpcqVtDBXuQZSc1BJQngo"
```

**Comandos:**
```powershell
python etl_telegram_rede_optica.py --input result.json --dry-run
python etl_telegram_rede_optica.py --input result.json --commit
python etl_telegram_rede_optica.py --rollback BATCH_ID
```

**Fluxo:**
1. Le result.json (export Telegram)
2. Carrega `vw_sites_lookup` via REST (16.962 codigos, determinÄ±stico, order=codigo.asc)
3. Parseia mensagens â†’ extrai pontas (SAG, VNZ, MGSAG, MGVNZ, BAM, ESL...)
4. Resolve pontas contra cache â†’ lookup por codigo exato, +MG, MG+
5. Grava em `stg_enlaces_importacao` (staging)
6. `--promote BATCH_ID` move staging â†’ `enlaces` (producao)

---

## COMO O MAPA FUNCIONA (para Codex)

| Funcionalidade | Endpoint atual | Status |
|----------------|---------------|--------|
| Login | `/rest/v1/usuarios?email=eq.X&ativo=eq.true` | OK |
| Carregar sites | `/rest/v1/sites?select=...&localizacao=not.is.null&limit=60000` | OK |
| Carregar cabos | `/rest/v1/cabos?select=...&trajeto=not.is.null&limit=10000` | OK |
| OTDR | `POST /rest/v1/rpc/ponto_no_cabo` | OK |
| Tracer Aâ†’B | Filtro bbox nos cabos | **INCORRETO** â€” deve usar `fn_tracer_bfs` |
| DGO | Nao implementado no front | **PENDENTE** |

**Escrita de localizacao:** `SRID=4326;POINT(lng lat)` via PATCH no campo `localizacao`

---

## PROXIMAS ACOES PRIORITARIAS

| # | Acao | Responsavel | Urgencia |
|---|------|-------------|----------|
| 1 | CRUD DGO no HTML + campo DGO nos formularios de enlace e cabo | Codex | Alta |
| 2 | Plotar caixa_emenda no mapa via vw_caixas_emenda_mapa (lat/lng prontos) | Codex | Alta |
| 3 | Painel de rupturas via vw_rupturas_abertas + formulario evento_ruptura | Codex | Alta |
| 4 | Conectar execRast() ao RPC fn_tracer_bfs (BUG 2) | Codex | Alta |
| 5 | Rodar PUBLICAR.bat e testar ETL --dry-run | Lidiomar | Alta |
| 6 | Rodar fn_sync_edges_from_cabos() para popular arestas de cabos no grafo | Claude | Media |
| 7 | Corrigir assimetria bidirecional em fn_tracer_bfs (BUG 3) | Claude | Baixa |

---

## NOTAS DE SEGURANCA

- Token GitHub: `privado/.github_token` â€” nunca vai para git
- Chave anon Supabase: publica por design (pode estar no JS)
- DB_PASS: nunca hardcoded â€” somente variavel de ambiente
- Site GitHub Pages: apenas HTMLs â€” Python e PS1 ficam so local

---

## QA E VALIDACAO

- Checklist mestre criado em `CHECKLIST_QUALIDADE_E_PUBLICACAO.md`
- Pilotos E2E criados em `PILOTOS_E2E_OPERACIONAIS.md`
- Esses dois arquivos agora sao a referencia para validar:
  - publicacao
  - qualidade funcional
  - lacunas do projeto
  - o que ainda esta incompleto ou meia-boca

---

## ATUALIZACAO LOCAL â€” 05/04/2026 18:xx

### Melhorias recentes no front local (`mapa-rede-optica.html`)

- mapa agora abre mais leve:
  - camadas principais desligadas por padrao
  - operador decide o que ativar
  - preferencia continua salva em `localStorage`
  - perfis rapidos: `limpo`, `campo`, `transporte`, `incidentes`
  - overlays operacionais agora tem flag propria: `incidentes`, `rascunhos`, `sugestoes`, `pendencias`
- leitura operacional priorizada:
  - sigla/codigo do site vem antes do nome
  - listas e painÃ©is usam `codigo â€” nome`
- paineis agora mostram resumo operacional rapido de segmentos/conexoes/pendencias
- paineis agora permitem navegar rapidamente para ativos relacionados (site/caixa/DGO/segmento)
- pendencias e rupturas locais agora tambem viram pontos navegaveis no fluxo de tratamento
- pendencias e rupturas agora podem pre-preencher formularios de correcao no cadastro
  - site, caixa, DGO e segmento agora possuem acoes rapidas para virar `Ponto A/B` ou abrir ruptura contextual
- rascunhos locais agora editam melhor:
  - `caixa_emenda` pode ser editada
  - `DGO` pode ser editado
  - `segmento_cabo` pode ser editado, reatribuir Ponto A/B e redesenhar geometria
- cabos oficiais existentes:
  - modal de edicao agora permite redesenhar o `trajeto`
  - novo desenho atualiza `trajeto` e `comprimento` no PATCH do cabo
  - usa o mesmo fluxo de desenho do mapa para manter consistencia
- geometria de segmento em rascunho:
  - `segmento` agora pode guardar `geometria_pts`
  - renderizacao usa a geometria desenhada quando existir
  - se nao existir, cai na reta simples entre A/B
- clique direito / toque longo no mapa:
  - criar caixa aqui
  - registrar ruptura aqui
  - criar DGO com site proximo
  - copiar coordenadas
- uso em campo:
  - cache local do mapa (`sites`, `cabos`, `science`)
  - fallback offline quando a rede falhar
  - indicador de `modo offline`
  - controles mobile ficaram maiores
  - barra de desenho no mapa com `desfazer`, `finalizar` e `cancelar`
  - desenho de linha agora fica viÃ¡vel no mobile sem depender de duplo clique
  - barra de campo mobile com atalhos para `camadas`, `GPS`, `nova caixa`, `nova ruptura` e `auditoria`
  - `Modo Campo` persistente, que aplica preset enxuto e reduz friccao no uso em rua

### Auditoria IA local agora verifica tambem

- excesso de camadas ligadas ao mesmo tempo
- ausencia de cache offline
- DGO sem site resolvido
- segmentos quebrados

### O que ainda falta no front local

- persistir caixa/DGO/segmento/ruptura no Supabase real
- editar cabos oficiais existentes com geometria real, nao so rascunho local
- mais acoes mobile de campo (ex.: fluxo de toque longo por elemento e nao so no mapa)
- diagrama completo de continuidade/fusao/tubo loose

### Automacao multiagente local

- novo script local: `RODAR-REVISAO-MULTIAGENTE.ps1`
- novo atalho: `RODAR-REVISAO-MULTIAGENTE.bat`
- finalidade:
  - gerar handoff padronizado para Claude
  - gerar handoff padronizado para Gemini
  - consolidar contexto, checklist, pilotos e estado git local
  - reduzir perda de contexto entre sessoes/agentes
- saida padrao:
  - pasta `handoffs\`
  - arquivo `handoff_claude_YYYYMMDD_HHMMSS.md`
  - arquivo `handoff_gemini_YYYYMMDD_HHMMSS.md`
  - arquivo `resumo_multiagente_YYYYMMDD_HHMMSS.md`
