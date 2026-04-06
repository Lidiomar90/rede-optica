# CONTEXTO COMPLETO — Rede Optica MG
**Atualizado em:** 2026-04-06 (sessao 10.4 — busca operacional unificada)
**Pasta local:** `C:\FIBRA CADASTRO`
**Repositorio:** `https://github.com/Lidiomar90/rede-optica`
**Site publicado:** `https://lidiomar90.github.io/rede-optica`
**Supabase projeto:** `xmqxhzmjxprhvyqwlqvz` (regiao sa-east-1, PostgreSQL 17)
**Supabase URL:** `https://xmqxhzmjxprhvyqwlqvz.supabase.co`

---

## ULTIMA ATUALIZACAO

**Data:** 2026-04-06 — sessoes 9, 10, 10.1, 10.2, 10.3 e 10.4 (front/mobile/tracer/auditoria/telegram/busca) + sessoes 7 e 8 (banco/tracer)
**O que foi feito:**

### Sessao 10.4 — Busca operacional mais direta
0. `execBuscaGlobal()` deixou de ficar restrita a `site`, `cabo` e `caixa` em rascunho: agora a busca principal tambem encontra `caixa`, `DGO`, `segmento` e `ruptura`, cobrindo tanto rascunho local quanto dados oficiais ja carregados no mapa.
1. Cada resultado da busca agora abre o painel tecnico correto, em vez de depender so de `fmap` por prefixo ou apenas centralizar o mapa, reduzindo friccao operacional principalmente no mobile e no fluxo de auditoria.
2. Validacao executada por parse JS via `node`; ainda falta validacao manual no browser para confirmar relevancia/ordem dos resultados com massa real.

### Sessao 10.3 — Esteira Telegram mais operacional
0. A fila Telegram no front agora usa cache local curto de `telegram_pendentes.json`, reduzindo recargas redundantes ao revisar, complementar e aprovar itens na mesma sessao.
1. A esteira passou a mostrar um resumo operacional da fila (`pendentes`, `complemento pendente`, `aprovados`, `mesclar`, `snapshots`, `alertas`) para o supervisor priorizar o que destrava a operacao.
2. Itens `alerta_anel_comutado` ainda pendentes e sem complemento minimo agora sobem primeiro na grade e recebem badge explicita de `Complemento pendente`.
3. Validacao executada apenas por parse JS via `node`; ainda falta validacao manual em browser da esteira Telegram e do fluxo de aprovacao/publicacao.

### Sessao 10.2 — Auditoria e navegação contextual com base oficial
0. `abrirAuditoriaRef()` passou a considerar `segmento_cabo` e `dgo` oficiais já carregados no mapa, evitando falso negativo de continuidade quando a auditoria era aberta a partir de `Caixa` ou `DGO` do banco.
1. `abrirAuditoriaRuptura()` agora soma rupturas e segmentos do rascunho local com `vw_rupturas_abertas` e `segmento_cabo`, preservando a leitura operacional do cabo mesmo quando o dado oficial já existe.
2. Resumo operacional, atalhos de `Ativos relacionados` e `Rupturas ligadas` passaram a navegar também para segmentos/rupturas oficiais, com rótulo explícito quando a origem vem do banco.

### Sessao 10.1 — Tracer mais resiliente no front
0. `findNodeId()` passou a tentar primeiro um casamento exato usando os sites ja carregados no mapa, reduzindo falso positivo quando a busca parcial em `network_nodes` encontra siglas parecidas.
1. `execRast()` agora aceita `edge_geom` como GeoJSON objeto, `Feature`, `LineString`, `MultiLineString` ou string JSON serializada, evitando rota vazia quando o RPC retorna geometria serializada.
2. O filtro de camada do tracer passou a afetar a renderizacao dos saltos visiveis, preservando a leitura operacional quando o usuario quer inspecionar apenas backbone, metro ou acesso.
3. O retorno do tracer agora diferencia claramente `sem caminho`, `caminho sem geometria desenhavel` e `caminho filtrado sem trechos visiveis`.

### Sessao 10 — Modal e formularios mobile
0. Modal generico ganhou `safe area` para iOS/Android, `max-height` com `100dvh`, `overscroll-behavior: contain` e `-webkit-overflow-scrolling: touch`, reduzindo corte na base da tela e conflito com scroll interno.
1. Grades de formulario (`.fgr` e `.mfgr`) agora colapsam para 1 coluna no mobile, melhorando leitura e toque em telas estreitas.
2. Header/corpo do modal ficaram mais compactos no mobile, preservando o comportamento do desktop.

### Sessao 9 — Overlay operacional de rupturas
0. Corrigido desenho de `rupturas oficiais` no front: itens vindos de `vw_rupturas_abertas` estavam sendo enviados para `draftInvLayer` (rascunhos), o que quebrava o preset `Incidentes` e misturava banco oficial com rascunho local.
1. `rupturas oficiais` e o marcador auxiliar de `nova caixa / cabo lancado` agora entram em `rompLayer`, preservando semantica correta de overlays (`Incidentes` vs `Rascunhos`) no mapa mobile/desktop.

### Sessao 7 — Autenticacao e senha mestre
0. Corrigido RLS de `usuarios`: INSERT bloqueado por ausencia de policy → criado `fn_criar_usuario` SECURITY DEFINER
1. Login restaurado apos REVOKE UPDATE quebrar PATCH de `ultimo_acesso` → criados `fn_login` e `fn_registrar_acesso` SECURITY DEFINER + GRANT UPDATE restaurado
2. Parametros de `fn_criar_usuario` alinhados com o front (sem prefixo `p_`): `nome, email, senha_hash, perfil`
3. Perfil `supervisor` adicionado a lista valida
4. Bug `</script>` no HTML deployado corrigido → `<\/script>` (parser HTML terminava o bloco prematuramente)
5. Senha mestre de emergencia criada: SHA-256 bypass no `login()` + usuario `master@redeop.com.br` no banco
6. `fn_vincular_cabos_lote` reescrita com `ORDER BY random()` para paralelismo
7. Corrigido erro `unknown GeoJSON type`: `s.localizacao` e uma coluna geometry PostGIS, nao JSONB — substituido `ST_GeomFromGeoJSON(s.localizacao::text)` por `s.localizacao::geography`

### Sessao 8 — Vinculacao de cabos e tracer BFS
8. Rodados ~160 lotes de 50 cabos: **7.214 de 7.913 vinculados** (91,2%). 698 sem site em 300m (limite geografico).
9. Executado `fn_sync_edges_from_cabos()`: **10.368 arestas em network_edges** (4.719 novas de cabos + preexistentes)
10. Corrigidos 4 bugs no tracer BFS:
    - `fn_tracer_bfs` nao retornava `edge_geom` → mapa nunca desenhava rota (CRITICO)
    - Nao retornava `camada`, `ativo_nome`, `peso_distancia_m` por salto
    - `fn_sync_network_edges` inexistente no banco (front chamava na linha 2326) → criado como alias
    - `c.sigla` inexistente em `cabos` → trocado por `c.codigo`
11. BFS testado: 1 hop e 2 hops, geometrias presentes, distancias corretas

### Sessao 6 — Sprint mobile-first (registro anterior)
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
19. Drawer mobile agora fecha por gesto horizontal (swipe para a esquerda), com arraste visual durante o toque, fade proporcional do overlay e fallback preservado por overlay/botao
20. Drawer mobile agora tambem abre por gesto de borda (edge swipe da esquerda para a direita), com arraste visual e reaproveitando o overlay existente

**Proximo agente deve fazer:**
- Testar tracer no browser: buscar dois sites por sigla e verificar se a rota e desenhada no mapa, inclusive quando o retorno do RPC vier serializado e quando houver filtro de camada ativo
- Backbone edges sem geom (4.908): popular `network_edges.geom` a partir de cabos backbone para que rotas backbone sejam visiveis no mapa
- Migrar login do front para usar `fn_login` RPC em vez de PATCH direto (elimina GRANT UPDATE na tabela `usuarios`)
- Codex: CRUD DGO no HTML + campo DGO em formulario de enlace
- Codex: plotar caixa_emenda no mapa via `vw_caixas_emenda_mapa`
- Codex: painel de rupturas via `vw_rupturas_abertas`
- Codex: evoluir `flag` para suportar cabos por vértice/trecho e, no futuro, persistência compartilhada no banco
- Codex: validar drawer mobile com swipe de abrir/fechar em Android real/iOS Safari, incluindo fade do overlay e conflito com scroll vertical da lista lateral
- Codex: validar modal generico e formularios em Android real/iOS Safari, especialmente auditoria, conexao DGO e edicao de ativos
- Codex: validar busca global no browser com massa real para `DGO`, `caixa`, `segmento` e `ruptura`, ajustando ranking se o operador ainda precisar "caçar" item na lista
- Codex: unificar futuro da aba `Incidentes` com `evento_ruptura`/`vw_rupturas_abertas` para evitar dupla origem (`incidentes` legado + rupturas oficiais)
- Codex: validar esteira Telegram em browser real, incluindo ordenacao de `complemento pendente`, resumo da fila e reaproveitamento de sugestoes no fluxo aprovar/complementar
- Gemini/Claude: revisar se a auditoria agora mistura corretamente rascunho + banco sem inflar contagens quando houver cabo/segmento duplicado nas duas origens
- Lidiomar: rodar `PUBLICAR.bat` e testar ETL `--dry-run`

---

## DIVISAO DE RESPONSABILIDADES

| Agente | Escopo | NAO toca em |
|--------|--------|-------------|
| **Claude (Cowork)** | Banco Supabase: SQL, views, RPCs, policies, network_nodes/edges, tracer BFS, tabela dgo | Codigo JS/HTML/Python local sem listar erros antes |
| **Codex (GPT)** | HTML, JS, Python local, PowerShell, deploy GitHub Pages | Banco Supabase diretamente |

**Regra de ouro:** Codex detecta erro no front → relata para Claude → Claude corrige no banco e devolve SQL/schema → Codex ajusta o front.

---

## ESTADO DO BANCO SUPABASE (2026-04-06 — sessao 8)

### Contagens oficiais
| Tabela | Linhas | Observacao |
|--------|--------|------------|
| `sites` | 56.848 | Todos ativos (inativo_em = NULL em todos) |
| `enlaces` | 2.276 | — |
| `cabos` | 7.913 | 7.214 vinculados a sites (91,2%). 698 sem site em raio 300m. |
| `trechos_dwdm` | 12.366 | — |
| `network_nodes` | 49.905 | Sites + caixas sincronizados |
| `network_edges` | **10.368** | backbone+metro+acesso+dwdm+b2b. 4.719 de cabos adicionadas na sessao 8. |
| `usuarios` | 4 | Inclui master@redeop.com.br (admin emergencia) |
| `dgo` | 0 | Tabela criada, dados a popular |
| `caixa_emenda` | 0 | Tabela criada, dados a popular |
| `segmento_cabo` | 0 | Tabela criada, dados a popular |
| `evento_ruptura` | 0 | Tabela criada, dados a popular |
| `stg_enlaces_importacao` | 633 | Pendentes de promocao para enlaces |
| `vw_sites_lookup` | 16.962 | Codigos unicos com geo — usada pelo ETL |

> **NUMERO OFICIAL network_edges = 10.368** (atualizado sessao 8 — inclui cabos vinculados)
> **ATENCAO:** 4.908 arestas backbone sem `geom` — BFS as usa para calculo de rota mas nao sao desenhadas no mapa.

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
| `fn_tracer_bfs` | `(p_node_inicio uuid, p_node_fim uuid, p_max_hops int)` | BFS em network_nodes/edges. Retorna: hop, node_nome, edge_id, ativo_nome, peso_distancia_m, camada, **edge_geom** (GeoJSON), distancia_acumulada_m, atenuacao_acumulada_db. |
| `fn_sync_network_edges` | `()` | Alias de fn_sync_edges_from_cabos. Chamado pelo HTML na linha 2326. |
| `fn_sync_nodes_from_sites` | `()` | Sincroniza sites → network_nodes. Idempotente. |
| `fn_sync_nodes_from_dgo` | `()` | Sincroniza DGOs → network_nodes. DGO herda geom do site. Idempotente. |
| `fn_sync_edges_from_cabos` | `()` | Sincroniza cabos (site_a→site_b) → network_edges. Requer cabos com site_a_id, site_b_id e trajeto preenchidos. |
| `fn_vincular_cabos_lote` | `(p_threshold_m numeric, p_batch int)` | Vincula cabos a sites por proximidade geografica (ST_DWithin). Usar batch=50 para evitar timeout. Rodado ate esgotar matches em 300m. |
| `fn_sync_edges_from_cabos_dgo` | `()` | Sincroniza cabos com DGO como ponta → network_edges. Tipos: DGO→Site, Site→DGO, DGO→DGO. |
| `fn_sync_nodes_from_caixa_emenda` | `()` | Sincroniza caixas_emenda com geo → network_nodes. |
| `fn_login` | `(p_email text, p_senha_hash text)` | Login SECURITY DEFINER. Valida email+senha_hash, atualiza ultimo_acesso, retorna {ok, id, nome, email, perfil}. |
| `fn_registrar_acesso` | `(p_id uuid)` | Atualiza ultimo_acesso. SECURITY DEFINER. |
| `fn_criar_usuario` | `(nome, email, senha_hash, perfil)` | Cria usuario. SECURITY DEFINER. Perfis validos: admin, supervisor, operador, colaborador, leitura. |
| `fn_atualizar_usuario` | `(id, nome, perfil, ativo)` | Atualiza usuario. SECURITY DEFINER. |
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
| `mapa-rede-optica.html` | Ativo | Mapa principal. Tracer A→B usa `fn_tracer_bfs`; drawer mobile abre/fecha por gesto; modal e formularios mobile ajustados para safe area e 1 coluna; esteira Telegram prioriza itens com complemento pendente. |
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

### RESOLVIDO — BUG 3: fn_tracer_bfs assimetrico no bidirecional
- Todos cabos sao bidirecional=true → nao ha impacto pratico. Mantido como documentacao.

### RESOLVIDO — BUG 4: network_edges sem arestas de cabos
- Causa: cabos nao tinham site_a_id/site_b_id preenchidos
- Correcao: rodado fn_vincular_cabos_lote em ~160 lotes → 7.214 cabos vinculados
- Resultado: fn_sync_edges_from_cabos() gerou 4.719 novas arestas → total 10.368

### RESOLVIDO — BUG 5: fn_tracer_bfs nao desenhava rota no mapa
- Causa: funcao nao retornava edge_geom, camada, ativo_nome, peso_distancia_m
- Correcao: reescrita com RETURNS TABLE expandido + ST_AsGeoJSON(e.geom) + JOIN em cabos

### PENDENTE — BUG 6: backbone edges sem geometria (4.908 arestas)
- network_edges backbone com geom=NULL → BFS calcula a rota mas nao desenha no mapa
- Para corrigir: popular geom a partir de cabos backbone via UPDATE network_edges SET geom = (SELECT trajeto FROM cabos WHERE id = ativo_id AND ativo_tabela = 'cabos')
- Impacto: rotas que passam por backbone aparecem com lacunas visuais no mapa

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
1. Le result
