# CONTEXTO COMPLETO — Rede Optica MG
**Atualizado em:** 2026-04-05 (sessao 3 — caixa_emenda, segmento_cabo, evento_ruptura)
**Pasta local:** `C:\FIBRA CADASTRO`
**Repositorio:** `https://github.com/Lidiomar90/rede-optica`
**Site publicado:** `https://lidiomar90.github.io/rede-optica`
**Supabase projeto:** `xmqxhzmjxprhvyqwlqvz` (regiao sa-east-1, PostgreSQL 17)
**Supabase URL:** `https://xmqxhzmjxprhvyqwlqvz.supabase.co`

---

## ULTIMA ATUALIZACAO

**Data:** 2026-04-05 — sessao 3
**O que foi feito:**
1. Criada `caixa_emenda` (CEO/CTO/DIO): vinculo com cabo + site/dgo + posicao_m + geo + fibras_livres calculado
2. Criada `segmento_cabo`: trecho logico entre pontas (site|dgo|caixa_emenda) com constraints de exclusividade
3. Criada `evento_ruptura`: registro de falha com codigo auto (RUP-AAAA-NNNN), geom_falha calculado, tempo_resolucao_min calculado
4. Criadas views: `vw_continuidade_completa`, `vw_rupturas_abertas`, `vw_caixas_emenda_mapa`
5. Expandida `vw_pendencias_qualidade`: agora cobre dgo, caixa_emenda, segmento_cabo, evento_ruptura
6. Todos triggers de atualizado_em e sync de network_nodes aplicados
7. Front do mapa ganhou `flags operacionais` em `site` e `cabo`, com marcador estilo placemark, edição por modal, ação no painel, menu rápido e indicador na lista lateral

**Proximo agente deve fazer:**
- Codex: CRUD DGO no HTML + campo DGO em formulario de enlace
- Codex: plotar caixa_emenda no mapa via `vw_caixas_emenda_mapa`
- Codex: painel de rupturas via `vw_rupturas_abertas`
- Codex: conectar `execRast()` ao RPC `fn_tracer_bfs` (BUG 2 — ainda pendente)
- Codex: evoluir `flag` para suportar também caixas, DGO e eventualmente cabos por vértice/trecho
- Lidiomar: rodar `PUBLICAR.bat` e testar ETL `--dry-run`

---

## DIVISAO DE RESPONSABILIDADES

| Agente | Escopo | NAO toca em |
|--------|--------|-------------|
| **Claude (Cowork)** | Banco Supabase: SQL, views, RPCs, policies, network_nodes/edges, tracer BFS, tabela dgo | Codigo JS/HTML/Python local sem listar erros antes |
| **Codex (GPT)** | HTML, JS, Python local, PowerShell, deploy GitHub Pages | Banco Supabase diretamente |

**Regra de ouro:** Codex detecta erro no front → relata para Claude → Claude corrige no banco e devolve SQL/schema → Codex ajusta o front.

---

## ESTADO DO BANCO SUPABASE (2026-04-05 — sessao 2)

### Contagens oficiais
| Tabela | Linhas | Observacao |
|--------|--------|------------|
| `sites` | 56.848 | Todos ativos (inativo_em = NULL em todos) |
| `enlaces` | 2.276 | — |
| `cabos` | 7.913 | — |
| `trechos_dwdm` | 12.366 | — |
| `network_nodes` | 44.286 | Sites + caixas sincronizados |
| `network_edges` | **5.649** | 4.317 trechos_dwdm + 1.332 enlaces. SEM duplicatas. |
| `usuarios` | 3 | — |
| `dgo` | 0 | Tabela criada, dados a popular |
| `caixa_emenda` | 0 | Tabela criada, dados a popular |
| `segmento_cabo` | 0 | Tabela criada, dados a popular |
| `evento_ruptura` | 0 | Tabela criada, dados a popular |
| `stg_enlaces_importacao` | 633 | Pendentes de promocao para enlaces |
| `vw_sites_lookup` | 16.962 | Codigos unicos com geo — usada pelo ETL |

> **NUMERO OFICIAL network_edges = 5.649** (o numero 5.960 citado antes incluia 311 duplicatas ja removidas)

---

## SCHEMA COMPLETO DAS TABELAS RELEVANTES

### `dgo` (NOVA — criada 2026-04-05)
| Campo | Tipo | Obrigatorio | Descricao |
|-------|------|-------------|-----------|
| `id` | uuid PK | sim | gen_random_uuid() |
| `codigo` | text | sim | Unico dentro do site (UNIQUE com site_id) |
| `nome` | text | nao | Nome descritivo |
| `site_id` | uuid FK→sites | **sim** | Vinculo obrigatorio com o site hospedeiro |
| `rack` | text | nao | Rack de instalacao |
| `fila` | text | nao | Fila/corredor |
| `bastidor` | text | nao | Bastidor especifico |
| `modelo` | text | nao | Modelo do equipamento |
| `fabricante` | text | nao | Fabricante |
| `status` | text | sim | 'ativo' \| 'inativo' \| 'manutencao' (default: ativo) |
| `observacao` | text | nao | — |
| `criado_em` | timestamptz | sim | default now() |
| `atualizado_em` | timestamptz | sim | atualizado por trigger |
| `inativo_em` | timestamptz | nao | NULL = ativo |

**RLS:** leitura publica (anon), escrita via `check_app_token()`
**UNIQUE:** `(site_id, codigo)`
**Trigger:** `trg_dgo_sync_node` → sincroniza `network_nodes` automaticamente ao INSERT/UPDATE

### `cabos` — campos DGO adicionados
- `dgo_a_id` uuid FK→dgo (NULL = usa site_a_id)
- `dgo_b_id` uuid FK→dgo (NULL = usa site_b_id)
- Permite cabo de DGO para site, site para DGO, DGO para DGO

### `enlaces` — campos DGO adicionados
- `ponta_a_dgo_id` uuid FK→dgo (complementa `ponta_a_dgo` texto existente)
- `ponta_b_dgo_id` uuid FK→dgo (complementa `ponta_b_dgo` texto existente)

### `posicoes_fisicas` — campo DGO adicionado
- `dgo_id` uuid FK→dgo (complementa campo `dgo` texto existente)

### `network_nodes`
- `id`, `tipo_ativo`, `ativo_id`, `ativo_tabela`, `sigla`, `nome`, `geom`, `status`
- UNIQUE em `(ativo_tabela, ativo_id)` — correto
- `tipo_ativo` aceita: 'site', 'pop', 'olt', 'caixa', **'dgo'** (novo)

### `network_edges`
- `id`, `node_a_id`, `node_b_id`, `tipo_edge`, `ativo_id`, `ativo_tabela`, `peso_distancia_m`, `peso_atenuacao`, `status`, `bidirecional`, `camada`, `geom`
- UNIQUE em `(ativo_tabela, ativo_id)` — constraint `network_edges_ativo_unico` JA EXISTE (BUG 1 resolvido)
- `tipo_edge` aceita: 'cabo', 'trechos_dwdm', **'cabo_dgo'** (novo)

---

## VIEWS E RPCS DO BANCO

### Views
| View | Descricao |
|------|-----------|
| `vw_sites_lookup` | DISTINCT ON (codigo), prioridade backbone>metro_alta>metro_dist>acesso. Usada pelo ETL REST. 16.962 registros. |
| `vw_dgo_incompleto` | DGOs com rack, bastidor, modelo, fabricante ou nome faltando. Para auditoria. |
| `vw_dgo_sem_conexao` | DGOs ativos sem nenhum enlace nem cabo conectado. Para ativos orfaos. |
| `vw_continuidade_caixa_dgo_site` | Cadeia: caixa_rede ↔ DGO ↔ site. Segmentos: cabo_dgo_a_site_b, cabo_site_a_dgo_b, cabo_dgo_a_dgo_b, caixa_mesmo_site_dgo. |
| `vw_continuidade_completa` | Segmentos resolvidos: ponta A/B = site\|dgo\|caixa_emenda. lat/lng do centroide. REST: /rest/v1/vw_continuidade_completa |
| `vw_rupturas_abertas` | Eventos ativos (aberto/investigando/em_reparo) com lat/lng e minutos_aberto. REST: ?order=abertura_em.desc |
| `vw_caixas_emenda_mapa` | Caixas de emenda com lat/lng para mapa. REST: /rest/v1/vw_caixas_emenda_mapa |

### Funcoes / RPCs
| Funcao | Assinatura | Descricao |
|--------|-----------|-----------|
| `fn_tracer_bfs` | `(p_node_inicio uuid, p_node_fim uuid, p_max_hops int)` | BFS em network_nodes/edges. NAO chamado pelo HTML ainda (BUG 2). |
| `fn_sync_nodes_from_sites` | `()` | Sincroniza sites → network_nodes. Idempotente. |
| `fn_sync_nodes_from_dgo` | `()` | Sincroniza DGOs → network_nodes. DGO herda geom do site. Idempotente. |
| `fn_sync_edges_from_cabos` | `()` | Sincroniza cabos (site_a→site_b) → network_edges. |
| `fn_sync_edges_from_cabos_dgo` | `()` | Sincroniza cabos com DGO como ponta → network_edges. Tipos: DGO→Site, Site→DGO, DGO→DGO. |
| `fn_sync_nodes_from_caixa_emenda` | `()` | Sincroniza caixas_emenda com geo → network_nodes. |
| `ponto_no_cabo` | `(cabo_id uuid, distancia_m numeric)` | Calcula lat/lng no cabo para OTDR. Chamado pelo HTML. |
| `fn_impacto_cabo` | — | Analise de impacto por cabo. |
| `fn_impacto_enlace` | — | Analise de impacto por enlace. |

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
| `sites` | `leitura_publica_sites` | SELECT para public — anon le tudo |
| `sites` | `escrita_autenticada_sites` | ALL exige `check_app_token()` |
| `dgo` | `dgo_leitura_publica` | SELECT para public |
| `dgo` | `dgo_escrita_autenticada` | ALL exige `check_app_token()` |

---

## ARQUIVOS LOCAIS EM C:\FIBRA CADASTRO

| Arquivo | Estado | Observacao |
|---------|--------|------------|
| `mapa-rede-optica.html` | Ativo | Mapa principal. Tracer A→B usa bbox (BUG 2 pendente). |
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

### RESOLVIDO — BUG 1: network_edges sem UNIQUE constraint
- **Era:** 311 duplicatas em network_edges (1.643 rows, 1.332 unicos para enlaces)
- **Status:** RESOLVIDO — constraint `network_edges_ativo_unico UNIQUE(ativo_tabela, ativo_id)` existe
- **network_edges agora:** 5.649 rows, 0 duplicatas

### PENDENTE — BUG 2: execRast() nao usa fn_tracer_bfs
**Problema:** Botao "Rastrear rota A→B" faz bbox geografico dos cabos. Nao chama o RPC `fn_tracer_bfs`.

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

### PENDENTE — BUG 3: fn_tracer_bfs assimetrico no bidirecional (baixa urgencia)
```sql
-- Atual (primeiro ramo nao checa bidirecional):
JOIN network_edges e ON (
  e.node_a_id = b.b_node_id
  OR (e.bidirecional AND e.node_b_id = b.b_node_id)
)
-- Nao afeta hoje (todos cabos sao bidirecional=true)
```

### PENDENTE — BUG 4: network_edges sem arestas de cabos
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
2. Carrega `vw_sites_lookup` via REST (16.962 codigos, determinıstico, order=codigo.asc)
3. Parseia mensagens → extrai pontas (SAG, VNZ, MGSAG, MGVNZ, BAM, ESL...)
4. Resolve pontas contra cache → lookup por codigo exato, +MG, MG+
5. Grava em `stg_enlaces_importacao` (staging)
6. `--promote BATCH_ID` move staging → `enlaces` (producao)

---

## COMO O MAPA FUNCIONA (para Codex)

| Funcionalidade | Endpoint atual | Status |
|----------------|---------------|--------|
| Login | `/rest/v1/usuarios?email=eq.X&ativo=eq.true` | OK |
| Carregar sites | `/rest/v1/sites?select=...&localizacao=not.is.null&limit=60000` | OK |
| Carregar cabos | `/rest/v1/cabos?select=...&trajeto=not.is.null&limit=10000` | OK |
| OTDR | `POST /rest/v1/rpc/ponto_no_cabo` | OK |
| Tracer A→B | Filtro bbox nos cabos | **INCORRETO** — deve usar `fn_tracer_bfs` |
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

- Token GitHub: `privado/.github_token` — nunca vai para git
- Chave anon Supabase: publica por design (pode estar no JS)
- DB_PASS: nunca hardcoded — somente variavel de ambiente
- Site GitHub Pages: apenas HTMLs — Python e PS1 ficam so local

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

## ATUALIZACAO LOCAL — 05/04/2026 18:xx

### Melhorias recentes no front local (`mapa-rede-optica.html`)

- mapa agora abre mais leve:
  - camadas principais desligadas por padrao
  - operador decide o que ativar
  - preferencia continua salva em `localStorage`
  - perfis rapidos: `limpo`, `campo`, `transporte`, `incidentes`
  - overlays operacionais agora tem flag propria: `incidentes`, `rascunhos`, `sugestoes`, `pendencias`
- leitura operacional priorizada:
  - sigla/codigo do site vem antes do nome
  - listas e painéis usam `codigo — nome`
- paineis agora mostram resumo operacional rapido de segmentos/conexoes/pendencias
- paineis agora tambem classificam melhor o estado operacional:
  - confirmado
  - pendente
  - quebrado
  - em montagem / pronto para campo
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
  - desenho de linha agora fica viável no mobile sem depender de duplo clique
  - barra de campo mobile com atalhos para `camadas`, `GPS`, `nova caixa`, `nova ruptura` e `auditoria`
  - `Modo Campo` persistente, que aplica preset enxuto e reduz friccao no uso em rua

### Auditoria IA local agora verifica tambem

- excesso de camadas ligadas ao mesmo tempo
- ausencia de cache offline
- DGO sem site resolvido
- segmentos quebrados
- estados operacionais dos ativos locais:
  - confirmados
  - pendentes
  - quebrados / sem continuidade
  - segmentos prontos para campo
  - cabos sem inventario local
- achados da auditoria agora podem abrir correcoes diretamente:
  - primeiro segmento quebrado
  - primeiro ativo quebrado
  - primeiro ativo pendente
  - primeiro segmento sem geometria
  - primeira ruptura ligada
  - primeiro DGO pendente
  - ativar preset de campo
- auditoria agora prioriza e ordena os achados por impacto operacional:
  - campo
  - continuidade
  - ruptura
  - dados
  - performance/offline

### O que ainda falta no front local

- persistir caixa/DGO/segmento/ruptura no Supabase real
- editar cabos oficiais existentes com geometria real, nao so rascunho local
- mais acoes mobile de campo por elemento ainda podem crescer, mas toque longo por ativo ja foi iniciado
- diagrama completo de continuidade/fusao/tubo loose

### Melhoria recente adicional — toque longo por ativo

- menu contextual agora tambem pode abrir por ativo, nao so no mapa vazio
- site no mapa:
  - ver detalhes
  - usar como Ponto A/B
  - abrir ruptura contextual
  - copiar coordenadas
- caixa em rascunho:
  - ver detalhes
  - editar
  - usar como Ponto A/B
  - abrir assistente de conexao
- DGO em rascunho:
  - ver detalhes
  - editar
  - usar como Ponto A/B
  - abrir assistente de conexao
- ruptura local:
  - ver detalhes
  - ajustar
  - copiar coordenadas
- cabo oficial e segmento em rascunho:
  - clique direito abre acoes rapidas
  - editar / redesenhar / abrir ruptura contextual
- mobile:
  - toque longo em marcador abre acoes rapidas do ativo

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
  - arquivo `handoff_gemini_geosite_gap_YYYYMMDD_HHMMSS.md`
  - arquivo `resumo_multiagente_YYYYMMDD_HHMMSS.md`

### Validacao focada vs GeoSite

- checklist criado: `CHECKLIST_GEOSITE_GAP.md`
- handoff especifico para Gemini:
  - `handoffs\handoff_gemini_geosite_gap_YYYYMMDD_HHMMSS.md`
- foco dessa rodada:
  - mapa
  - linhas
  - DGO
  - caixa de emenda
  - usabilidade
  - uso em campo
