# Backlog Coordenação Operacional — Rede Optica MG
**Gerado em:** 2026-04-05
**Papel:** Coordenador de backlog / sprint / entregas

---

## DIAGNÓSTICO GERAL

O projeto está em `bom protótipo operacional evoluído`, mas ainda não é `inventário operacional confiável`.
O principal risco é a **mistura de camadas**: front local com rascunho, banco oficial com tabelas vazias, e fluxos que parecem prontos mas não persistem nada.

---

## 1. BACKLOG PRIORIZADO POR IMPACTO

| # | Item | Impacto | Camada | Estado atual |
|---|------|---------|--------|--------------|
| 1 | Tracer A→B conectado ao `fn_tracer_bfs` (BUG 2) | Crítico | Front | Incorreto — usa bbox |
| 2 | Persistência oficial: caixa_emenda no Supabase | Crítico | Banco + Front | Tabela existe, 0 linhas, front só salva local |
| 3 | Persistência oficial: DGO no Supabase | Crítico | Banco + Front | Tabela existe, 0 linhas, CRUD no front pendente |
| 4 | Persistência oficial: segmento_cabo no Supabase | Crítico | Banco + Front | Tabela existe, 0 linhas, front só salva local |
| 5 | Persistência oficial: evento_ruptura no Supabase | Crítico | Banco + Front | Tabela existe, 0 linhas, front só salva local |
| 6 | BUG 4: network_edges sem arestas de cabos | Crítico | Banco | 0 edges de cabos — tracer não funciona sem isso |
| 7 | Login/RLS: fluxo de usuários estável | Alto | Front + Banco | Preparado com fallback, mas não validado |
| 8 | CRUD DGO no HTML + campo DGO em enlace/cabo | Alto | Front | Pendente |
| 9 | Painel de rupturas via `vw_rupturas_abertas` | Alto | Front | View existe, front não consome |
| 10 | Plotar caixa_emenda via `vw_caixas_emenda_mapa` | Alto | Front | View existe, front consome parcialmente |
| 11 | Science publicada + agrupamento CN/DDD | Alto | Deploy + Front | Falha silenciosa se JSON não estiver no Pages |
| 12 | ETL Telegram: rodar `--dry-run` e validar | Médio | Processo | Nunca rodado em produção confirmada |
| 13 | `fn_sync_edges_from_cabos()` popular grafo | Médio | Banco | 0 edges de cabos — bloqueia tracer |
| 14 | BUG 3: assimetria bidirecional no BFS | Baixo | Banco | Não afeta hoje (todos bidirecional=true) |
| 15 | Diagrama completo fusão/tubo loose | Baixo | Front | Não iniciado |

---

## 2. SEPARAÇÃO POR SPRINT

### Sprint 1 — Fundação (fazer agora, bloqueia tudo)
> Sem isso o sistema não pode ser chamado de operacional

- [ ] BUG 4: diagnosticar e rodar `fn_sync_edges_from_cabos()` → popular network_edges com cabos
- [ ] BUG 2: conectar `execRast()` ao RPC `fn_tracer_bfs` no HTML
- [ ] CRUD DGO no HTML (formulário + mapa + painel)
- [ ] Campo DGO nos formulários de enlace e cabo
- [ ] Rodar `PUBLICAR.bat` + validar Science no GitHub Pages

### Sprint 2 — Persistência oficial (sem isso é só rascunho)
> Tudo que existe no front mas não salva no banco

- [ ] Persistir `caixa_emenda` no Supabase (formulário → INSERT real)
- [ ] Persistir `DGO` no Supabase (formulário → INSERT real)
- [ ] Persistir `segmento_cabo` no Supabase (formulário → INSERT real)
- [ ] Persistir `evento_ruptura` no Supabase (formulário → INSERT real)
- [ ] Painel de rupturas consumindo `vw_rupturas_abertas`
- [ ] Validar RLS: escrita via `check_app_token()` funcionando para cada tabela nova

### Sprint 3 — Qualidade operacional (fechar gap vs GeoSite)
> O que está meia-boca e precisa ficar bom de verdade

- [ ] Tracer exibindo caminho real com cabos do grafo
- [ ] Auditoria detectando: DGO sem banco, segmento sem banco, ruptura sem banco
- [ ] ETL Telegram: `--dry-run` validado + `--commit` testado em staging
- [ ] Pilotos E2E 1, 2, 4, 5, 7, 8 executados e documentados
- [ ] BUG 3: corrigir assimetria bidirecional no BFS

### Sprint 4 — Produto de alto nível (superar GeoSite)
> O que diferencia de verdade

- [ ] Diagrama de continuidade/fusão/tubo loose
- [ ] Modo campo 100% offline com sync ao reconectar
- [ ] Auditoria corrigindo automaticamente (não só apontando)
- [ ] Histórico de rupturas com tempo de resolução e relatório

---

## 3. O QUE É CRÍTICO

Estes itens bloqueiam o uso real. Sem eles o sistema falha em campo:

1. **Tracer A→B** — hoje faz bbox geográfico, não BFS real. Resultado errado em topologia complexa.
2. **network_edges sem cabos** — o grafo não tem arestas de cabos. O BFS não vai funcionar mesmo depois de conectar o front.
3. **Persistência zero nas 4 tabelas novas** — caixa_emenda, DGO, segmento_cabo, evento_ruptura têm 0 linhas. Tudo que o operador cadastra some ao fechar o browser.
4. **Science no GitHub Pages** — sem o JSON publicado, o agrupamento CN/DDD falha silenciosamente. O operador não vê o erro.

---

## 4. O QUE ESTÁ MEIA-BOCA

Existe, funciona parcialmente, mas não está confiável:

- **Caixa de emenda**: aparece no mapa via `vw_caixas_emenda_mapa`, mas só se tiver dados no banco (0 linhas hoje). O front salva local, não no banco.
- **DGO**: tabela criada, trigger de sync pronto, mas CRUD no HTML ainda não existe. O operador não consegue cadastrar DGO pelo front.
- **Tracer**: botão existe, fluxo visual existe, mas o resultado é geograficamente incorreto.
- **Auditoria IA**: detecta problemas locais, mas não sabe distinguir "rascunho local" de "dado oficial no banco". Pode dar falsa sensação de pronto.
- **Login/RLS**: preparado com fallback REST, mas não foi validado com os 3 usuários reais em cenário de escrita.
- **ETL Telegram**: código atualizado, `vw_sites_lookup` integrado, mas nunca rodou `--commit` em produção confirmada.

---

## 5. O QUE DEPENDE DE BANCO

Nada avança sem estas ações no Supabase:

- Rodar `SELECT fn_sync_edges_from_cabos();` → popular arestas de cabos no grafo
- Validar RLS de escrita para `caixa_emenda`, `segmento_cabo`, `evento_ruptura` (já existe para `dgo`)
- Confirmar que `fn_tracer_bfs` retorna resultado correto após popular edges
- Diagnosticar: `SELECT COUNT(*) FROM cabos WHERE site_a_id IS NOT NULL AND site_b_id IS NOT NULL AND trajeto IS NOT NULL AND inativo_em IS NULL;`
- Promover `stg_enlaces_importacao` (633 registros pendentes) para `enlaces` quando ETL validado

---

## 6. O QUE DEPENDE DE FRONT

Nada avança sem estas ações no HTML/JS:

- `execRast()` → chamar `fn_tracer_bfs` via RPC (código já documentado no CONTEXTO_PROJETO.md)
- CRUD DGO: formulário de criação + painel de detalhe + campo DGO em enlace/cabo
- Formulários de caixa/segmento/ruptura → trocar `localStorage` por `INSERT` no Supabase
- Painel de rupturas consumindo `vw_rupturas_abertas` (endpoint já existe)
- Auditoria distinguir rascunho local vs dado oficial no banco

---

## 7. O QUE JÁ ESTÁ BOM

Pode confiar, não precisa tocar:

- Mapa principal: carrega sites (56.848) e cabos (7.913) com performance aceitável
- Publicação automatizada: `PUBLICAR-GIT.ps1` + `.bat` funcionando
- network_edges: 5.649 linhas, 0 duplicatas (BUG 1 resolvido)
- ETL Telegram: parser atualizado, `vw_sites_lookup` resolve SAG/VNZ/MGSAG corretamente
- Views do banco: `vw_continuidade_completa`, `vw_rupturas_abertas`, `vw_caixas_emenda_mapa` criadas e funcionais
- Triggers: `atualizado_em`, sync de `network_nodes` para DGO e caixa_emenda ativos
- Mobile base: controles maiores, barra de campo, modo campo, toque longo por ativo
- Orquestração multiagente: scripts de handoff e consolidação funcionando
- OTDR: `ponto_no_cabo` RPC chamado corretamente pelo front

---

## 8. RISCOS DE SEGUIR SEM CORRIGIR

| Risco | Consequência | Probabilidade |
|-------|-------------|---------------|
| Tracer com bbox em vez de BFS | Operador confia em rota errada em campo | Alta |
| 0 linhas nas tabelas novas | Operador cadastra, fecha o browser, perde tudo | Certa |
| network_edges sem cabos | BFS nunca vai funcionar mesmo após fix do front | Alta |
| Science fora do Pages | Agrupamento CN/DDD some sem aviso | Média |
| Auditoria não distingue rascunho/banco | Falsa sensação de pronto — dado some em produção | Alta |
| RLS não validado em escrita | Operador não consegue salvar nada no banco | Média |
| 633 registros em staging | Dados de enlace presos em staging, não em produção | Média |

---

## 9. PRÓXIMA AÇÃO OBJETIVA PARA CODEX

**Prioridade 1 — BUG 2 (tracer):**
Substituir o corpo de `execRast()` no `mapa-rede-optica.html` pela implementação BFS documentada no `CONTEXTO_PROJETO.md` (seção BUG 2). Resolver node_id para site A e B via `network_nodes`, chamar `fn_tracer_bfs` via POST RPC, desenhar o caminho pelos cabos retornados.

**Prioridade 2 — CRUD DGO:**
Implementar no HTML: formulário de criação de DGO (campos: codigo, nome, site_id, rack, fila, bastidor, modelo, fabricante, status), painel de detalhe ao clicar no marcador DGO, e campo `dgo_a_id`/`dgo_b_id` nos formulários de enlace e cabo.

**Prioridade 3 — Persistência caixa/segmento/ruptura:**
Trocar o `localStorage` dos formulários de caixa_emenda, segmento_cabo e evento_ruptura por chamadas `POST /rest/v1/{tabela}` no Supabase, usando o mesmo padrão de autenticação já existente no front.

---

## 10. PRÓXIMA AÇÃO OBJETIVA PARA CLAUDE

**Prioridade 1 — Popular grafo de cabos:**
Diagnosticar: `SELECT COUNT(*) FROM cabos WHERE site_a_id IS NOT NULL AND site_b_id IS NOT NULL AND trajeto IS NOT NULL AND inativo_em IS NULL;`
Se > 0, executar: `SELECT fn_sync_edges_from_cabos();`
Confirmar contagem de `network_edges` após execução.

**Prioridade 2 — Validar RLS de escrita:**
Confirmar que as policies de escrita (`check_app_token()`) estão ativas e corretas para `caixa_emenda`, `segmento_cabo` e `evento_ruptura`. Criar se faltarem, seguindo o padrão já existente em `dgo`.

**Prioridade 3 — Testar fn_tracer_bfs:**
Após popular edges de cabos, executar um teste manual do BFS entre dois sites conhecidos (ex: SAG → VNZ) e confirmar que retorna caminho coerente. Documentar o resultado.

---

## 11. PRÓXIMA AÇÃO OBJETIVA PARA GEMINI

**Prioridade 1 — Validação gap vs GeoSite:**
Executar o `CHECKLIST_GEOSITE_GAP.md` completo contra o sistema atual publicado em `https://lidiomar90.github.io/rede-optica`. Para cada item que falhar, classificar como: `abaixo do GeoSite`, `equivalente` ou `melhor`. Entregar tabela de resultado com os 3 gaps mais críticos para uso em campo.

**Prioridade 2 — Auditoria de coerência banco/front:**
Verificar se o que o front exibe (caixas, DGOs, segmentos, rupturas) tem correspondência real no banco. Identificar onde existe dado no front que não existe no Supabase e classificar como `incompleto`. Entregar lista priorizada.

**Prioridade 3 — Validar pilotos E2E 1, 2 e 7:**
Executar os pilotos 1 (abertura básica), 2 (Science + CN/DDD) e 7 (auditoria detecta regressão) conforme `PILOTOS_E2E_OPERACIONAIS.md` e preencher `EXECUCAO_TESTES_E2E.md` com resultado real.

---

## ESTADO RESUMIDO

| Dimensão | Estado |
|----------|--------|
| Banco estrutural | Bom — tabelas, views, RPCs, triggers prontos |
| Dados no banco | Crítico — 4 tabelas novas com 0 linhas |
| Grafo de rede | Crítico — sem arestas de cabos |
| Front visual | Bom — mapa, mobile, auditoria, painéis |
| Front funcional | Meia-boca — tracer errado, persistência local |
| Persistência oficial | Crítico — nada das tabelas novas vai para o banco |
| Deploy/publicação | OK — automatizado e funcionando |
| ETL | Meia-boca — nunca rodou `--commit` em produção |
| Comparação GeoSite | Ainda abaixo em: tracer, DGO, persistência |
