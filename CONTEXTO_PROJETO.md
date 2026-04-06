# CONTEXTO COMPLETO — Rede Optica MG
**Atualizado em:** 2026-04-05 (sessao 4 — mobile feedback, cache e fila de sync)
**Pasta local:** `C:\FIBRA CADASTRO`
**Repositorio:** `https://github.com/Lidiomar90/rede-optica`
**Site publicado:** `https://lidiomar90.github.io/rede-optica`
**Supabase projeto:** `xmqxhzmjxprhvyqwlqvz` (regiao sa-east-1, PostgreSQL 17)
**Supabase URL:** `https://xmqxhzmjxprhvyqwlqvz.supabase.co`

---

## ULTIMA ATUALIZACAO

**Data:** 2026-04-05 — sessao 4
**O que foi feito:**
0. Iniciada sprint mobile-first do mapa: topo compactado, legenda recolhivel no celular, barra de campo horizontal compacta, ferramentas secundarias escondidas atras de "mais" e Auditoria IA convertida para cards mais compactos
1. Criada `caixa_emenda` (CEO/CTO/DIO): vinculo com cabo + site/dgo + posicao_m + geo + fibras_livres calculado
2. Criada `segmento_cabo`: trecho logico entre pontas (site|dgo|caixa_emenda) com constraints de exclusividade
3. Criada `evento_ruptura`: registro de falha com codigo auto (RUP-AAAA-NNNN), geom_falha calculado, tempo_resolucao_min calculado
4. Criadas views: `vw_continuidade_completa`, `vw_rupturas_abertas`, `vw_caixas_emenda_mapa`
5. Expandida `vw_pendencias_qualidade`: agora cobre dgo, caixa_emenda, segmento_cabo, evento_ruptura
6. Todos triggers de atualizado_em e sync de network_nodes aplicados
7. Front do mapa ganhou `flags operacionais` em `site`, `cabo`, `caixa` e `DGO`, com marcador estilo placemark, edição por modal, ação no painel, menu rápido e indicador na lista lateral
8. Sidebar do mapa ganhou aba operacional `Ativos`, com navegação direta para `Caixas / emendas` e `DGOs`, status operacional e flag visível
9. Sidebar do mapa ganhou aba `Continu.`, com navegação direta para `Segmentos físicos` e `Rupturas / reparos`, incluindo salto para o mapa e abertura do painel técnico
10. Abas `Ativos` e `Continu.` ganharam filtros rápidos por status (`Todos`, `Quebrados`, `Pendentes`, `Confirmados`) para inspeção operacional mais rápida
11. Mapa ganhou `edição rápida` por duplo clique no desktop para `site`, `cabo`, `caixa`, `DGO`, `segmento` e `ruptura`, reduzindo cliques no fluxo operacional
12. Fluxo de autenticação/usuários no front foi preparado para `RPC segura + fallback REST`, com mensagens mais claras quando `usuarios` estiver bloqueado por RLS
13. Criado orquestrador local `ORQUESTRAR-IAS-PROJETO.ps1` + `.bat` + task do VS Code para gerar pacotes de sessao separados para Claude, Gemini, Codex, DeepSeek e Manus, com foco, contexto, checklist e estado consolidado
14. Criado consolidado local `CONSOLIDAR-RETORNOS-IAS.ps1` + `.bat` para reunir respostas de Claude, Gemini, DeepSeek e Manus em um unico relatorio por sessao, com pasta `respostas` dedicada
15. Ajustado mobile do mapa: toque longo reduzido de 650ms para 320ms em mapa e ativos, com vibracao curta quando suportada
16. Ligados indicadores ja previstos no front: badge de fila de sincronizacao pendente, timestamp do cache offline no mobile e aviso de rede lenta/online/offline
17. Drawer mobile passou a usar a classe `show` no overlay, evitando inconsistencias de display inline ao abrir/fechar a sidebar
18. Botao mobile de `Modo campo` agora reflete o estado ativo com destaque visual persistente

**Proximo agente deve fazer:**
- Codex: CRUD DGO no HTML + campo DGO em formulario de enlace
- Codex: plotar caixa_emenda no mapa via `vw_caixas_emenda_mapa`
- Codex: painel de rupturas via `vw_rupturas_abertas`
- Codex: conectar `execRast()` ao RPC `fn_tracer_bfs` (BUG 2 — ainda pendente)
- Codex: evoluir `flag` para suportar cabos por vértice/trecho e, no futuro, persistência compartilhada no banco
- Codex: testar drawer mobile com swipe/gesto; ainda nao implementado
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

### RESOLVIDO LOCALMENTE — BUG 2: execRast() agora usa fn_tracer_bfs
- `mapa-rede-optica.html` ja resolve `network_nodes`, chama `POST /rest/v1/rpc/fn_tracer_bfs` e desenha a rota a partir dos steps retornados
- contexto anterior estava desatualizado; manter validacao focada em consistencia do grafo e UX da rota, nao mais no fallback bbox antigo

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
- cache offline expandido para incluir tambem `vw_caixas_emenda_mapa`, `dgo`, `segmento_cabo` e `vw_rupturas_abertas`
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

### Integracao oficial de caixas e rupturas no mapa

- `mapa-rede-optica.html` agora consome tambem:
  - `vw_caixas_emenda_mapa`
  - `vw_rupturas_abertas`
- dados oficiais sao normalizados no front em:
  - `officialCaixas`
  - `officialRupturas`
- as caixas oficiais agora:
  - aparecem no mapa
  - abrem painel proprio de banco oficial
  - entram na aba lateral `Ativos`
  - entram na resolucao de referencia de pontos (`findDraftPoint`)
- as rupturas oficiais agora:
  - aparecem no mapa
  - abrem painel proprio de banco oficial
  - entram na aba lateral `Continu.`
- menus contextuais foram ajustados para nao tratar caixa oficial como rascunho local:
  - `mkCaixaMenu` abre painel oficial quando `_kind === caixa_oficial`
  - `mkRupturaMenu` abre painel oficial quando `_kind === ruptura_oficial`
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### Acoes operacionais de 1 clique

- `site` agora abre fluxo mais direto para operacao:
  - `Novo DGO`
  - `Nova caixa`
- `DGO` ganhou acao direta de:
  - `Auditoria`
- `caixa` local e oficial ganharam acao direta de:
  - `Auditoria`
- `ruptura` local e oficial ganharam acoes diretas de:
  - `Ir para cabo`
  - `Auditoria`
- `jumpToRef` agora respeita caixa oficial:
  - se o ponto resolvido vier de `officialCaixas`, o painel aberto eh o oficial
- objetivo dessa rodada:
  - reduzir ida e volta entre mapa, cadastro e auditoria
  - aproximar a operacao do fluxo detalhado pela Manus
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### DGO oficial no mapa

- `mapa-rede-optica.html` agora tambem consome a tabela `dgo`
- dados oficiais sao normalizados no front em:
  - `officialDgos`
- os DGOs oficiais agora:
  - aparecem no mapa
  - entram na aba lateral `Ativos`
  - entram na resolucao de referencias (`findDraftPoint`)
  - abrem painel proprio de banco oficial
  - podem receber `flag`
- o menu contextual de DGO agora diferencia:
  - rascunho local
  - banco oficial
- `jumpToRef` agora respeita DGO oficial:
  - se a referencia apontar para `officialDgos`, o painel aberto eh `showPanDgoOficial`
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### DGO oficial no mapa

- `mapa-rede-optica.html` agora tambem consome a tabela `dgo` do banco
- dados oficiais sao normalizados no front em:
  - `officialDgos`
- os DGOs oficiais agora:
  - aparecem no mapa com marcador proprio
  - abrem painel proprio de banco oficial
  - entram na aba lateral `Ativos`
  - entram na resolucao de referencias (`findDraftPoint`)
  - podem receber `flag`
- a navegacao agora respeita DGO oficial:
  - `jumpToRef` abre `showPanDgoOficial` quando o ponto vier de `officialDgos`
- o menu contextual de DGO foi ajustado:
  - se `_kind === dgo_oficial`, ele nao cai no fluxo de edicao/assistente de rascunho
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### Segmento oficial no mapa e na continuidade

- `mapa-rede-optica.html` agora tambem consome a tabela `segmento_cabo`
- dados oficiais sao normalizados no front em:
  - `officialSegmentos`
- os segmentos oficiais agora:
  - aparecem no mapa com traçado proprio
  - entram na aba lateral `Continu.`
  - abrem painel proprio de banco oficial
  - podem entrar em edicao direta pelo mesmo formulario de segmento
- o menu contextual de segmento agora diferencia:
  - rascunho local
  - banco oficial
- o fluxo de edicao oficial foi fechado:
  - `editarSegmentoOficial`
  - `redesenharSegmentoOficial`
  - `salvarSegmento` com `PATCH` em `segmento_cabo`
- objetivo dessa rodada:
  - parar de deixar `segmento_cabo` oficial invisivel para a operacao de campo
  - aproximar continuidade real do banco com o mapa operacional
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### Controle individual de sites na aba `Sites`

- a aba `Sites` agora ganhou marcacao individual por item, no mesmo espirito de ligar/desligar camadas
- cada site listado passa a exibir um checkbox proprio:
  - marcado = site visivel no mapa
  - desmarcado = site oculto no mapa
- o topo da aba `Sites` agora mostra:
  - contador `Sites no mapa`
  - botoes `Todos` e `Nenhum`
- a preferencia fica salva no navegador em `localStorage`
- o cluster de sites agora respeita ao mesmo tempo:
  - camadas ativas
  - marcacao individual dos sites
- objetivo dessa rodada:
  - dar controle operacional fino sobre quais sites ficam visiveis
  - reduzir poluicao visual sem precisar desligar uma camada inteira
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### Hub local para execucao multi-IA

- foi criado um hub local em `C:\FIBRA CADASTRO\ia_hub`
- objetivo:
  - centralizar fila, sessoes, inbox, estado e respostas das IAs
  - permitir rodadas continuas com Claude, Gemini, DeepSeek, Manus e Codex
- script principal:
  - `ORQUESTRAR-EXECUCAO-IAS.ps1`
- atalho:
  - `ORQUESTRAR-EXECUCAO-IAS.bat`
- o hub cria automaticamente:
  - pasta de tarefa em `ia_hub\fila`
  - sessao em `ia_hub\sessoes`
  - inbox de chamada
  - manifesto da tarefa
  - estado resumido do hub
- o hub reaproveita:
  - `ORQUESTRAR-IAS-PROJETO.ps1`
  - `CONSOLIDAR-RETORNOS-IAS.ps1`
- VS Code agora tem tasks para:
  - criar tarefa
  - foco mobile
  - foco banco e persistencia

### Monitor automatico do hub

- foi criado o monitor do hub:
  - `MONITORAR-HUB-IAS.ps1`
- atalho:
  - `MONITORAR-HUB-IAS.bat`
- o monitor faz:
  - verifica respostas de Claude, Gemini, DeepSeek e Manus
  - consolida automaticamente quando todas chegaram
  - gera `08_RESUMO_AUTOMATICO.md` na sessao
  - atualiza o status do manifesto da tarefa
  - opcionalmente tenta publicar via `PUBLICAR-GIT.ps1` quando a rodada estiver apta
- VS Code agora tambem tem tasks para:
  - monitorar
  - monitorar e publicar se seguro

### Enxugamento da sidebar e recolhimento em `Sites`

- a aba `Sites` agora permite recolher e expandir:
  - por `CN / DDD`
  - por cidade / localidade dentro do grupo
- o estado dos grupos fica salvo no navegador
- a listagem dos sites ficou menos repetitiva:
  - removeu repeticao de `CN` e cidade no subtitulo de cada item
  - manteve so origem e responsavel quando houver
- o texto institucional do site foi encurtado para ficar mais objetivo:
  - sidebar: `Mapa e inventário da rede`
  - cabeçalho do mapa: `Rede, falhas e cadastro`
- objetivo dessa rodada:
  - reduzir ruido visual
  - deixar a leitura mais proxima de operacao real
  - aproximar o produto de ferramentas como GeoSite/Ozmap, que tendem a ser mais objetivas na tela principal
- validacao:
  - JavaScript inline continua integro: `CHECK_OK`

### Disparo de frentes paralelas no hub

- foi criado o disparador:
  - `DISPARAR-FRENTES-PROJETO.ps1`
- atalho:
  - `DISPARAR-FRENTES-PROJETO.bat`
- ele abre varias frentes em paralelo dentro do `ia_hub`, uma para cada tema critico:
  - banco e persistencia oficial
  - login / usuarios / RLS
  - historico e workflow
  - ocupacao e capacidade
  - mobile / UX / campo
  - relatorios e paineis
- objetivo:
  - acelerar a execucao
  - evitar uma fila unica gigante
  - separar melhor o trabalho das IAs por area
- VS Code agora tambem tem task para:
  - disparar frentes paralelas
- IDs de tarefa e sessao do hub foram endurecidos:
  - agora usam timestamp com milissegundos + sufixo aleatorio curto
  - evita colisao quando varias frentes sao abertas no mesmo segundo
