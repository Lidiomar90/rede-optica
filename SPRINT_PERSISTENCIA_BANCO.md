# Esteira de Persistência Oficial — Rede Optica MG
**Gerado em:** 2026-04-05
**Papel:** Coordenador de backlog — foco banco/persistência/confiabilidade

---

## 1. O QUE HOJE AINDA É RASCUNHO LOCAL

Tudo abaixo existe no front, parece funcionar, mas some ao fechar o browser ou ao abrir em outro dispositivo:

| Item | Onde salva hoje | Deveria salvar em |
|------|----------------|-------------------|
| Caixa de emenda criada pelo operador | `localStorage` | `caixa_emenda` no Supabase |
| DGO criado pelo operador | `localStorage` | `dgo` no Supabase |
| Segmento físico desenhado | `localStorage` | `segmento_cabo` no Supabase |
| Ruptura registrada | `localStorage` | `evento_ruptura` no Supabase |
| Flags operacionais (site/cabo/caixa/DGO) | `localStorage` | campo `flags` nas tabelas ou tabela dedicada |
| Geometria redesenhada de cabo oficial | `localStorage` | campo `trajeto` em `cabos` via PATCH |
| Pré-conexão de caixa | `localStorage` | tabela de conexões (não existe ainda) |
| Conexão de DGO | `localStorage` | tabela de conexões ou campo em `segmento_cabo` |

**Resumo:** 8 fluxos de cadastro que o operador usa no dia a dia não persistem nada no banco oficial.

---

## 2. O QUE JÁ EXISTE NO FRONT MAS NÃO ESTÁ CONSOLIDADO NO BANCO

| Feature | Estado no front | Estado no banco | Classificação |
|---------|----------------|-----------------|---------------|
| CRUD caixa_emenda | Formulário + mapa + painel + assistente de conexão | Tabela criada, 0 linhas, sem RLS de escrita validada | **INCOMPLETO** |
| CRUD DGO | Painel e marcador existem, formulário de criação **não existe** | Tabela criada, 0 linhas, RLS ok, trigger ok | **INCOMPLETO** |
| CRUD segmento_cabo | Formulário + desenho + edição | Tabela criada, 0 linhas, sem RLS de escrita validada | **INCOMPLETO** |
| CRUD evento_ruptura | Formulário + marcador + OTDR | Tabela criada, 0 linhas, sem RLS de escrita validada | **INCOMPLETO** |
| Flags operacionais | Marcador visual + modal de edição + painel | Sem coluna nem tabela no banco | **INCOMPLETO** |
| Redesenho de cabo | Modal de redesenho + PATCH local | PATCH para `trajeto` em `cabos` não implementado | **INCOMPLETO** |
| Tracer A→B | Botão + fluxo visual | `fn_tracer_bfs` existe mas não é chamado; `network_edges` sem cabos | **INCOMPLETO** |
| Continuidade (segmentos) | Aba `Continu.` na sidebar | `vw_continuidade_completa` existe, front não consome | **INCOMPLETO** |
| Histórico de manutenção | Não existe no front | Não existe no banco | **NÃO INICIADO** |
| Ocupação/capacidade de fibras | Não existe no front | `fibras_livres` calculado em `caixa_emenda`, sem front | **NÃO INICIADO** |

---

## 3. LACUNAS QUE IMPEDEM CHAMAR ISSO DE INVENTÁRIO OPERACIONAL REAL

1. **Persistência zero nas 4 tabelas novas**: o operador cadastra, fecha o browser, perde tudo. Isso sozinho já desqualifica o sistema como inventário.

2. **Grafo de rede incompleto**: `network_edges` tem 5.649 linhas mas 0 são de cabos. O tracer não funciona. Continuidade não pode ser calculada.

3. **Flags sem banco**: o operador marca um ativo como "quebrado" ou "pendente" — essa informação some ao recarregar. Não existe histórico, não existe compartilhamento entre usuários.

4. **Sem histórico de manutenção**: não há como saber o que foi feito em um ativo, quando, por quem. Isso é requisito básico de inventário operacional.

5. **Sem ocupação/capacidade**: `fibras_livres` está calculado na tabela mas não aparece em nenhum painel. O operador não sabe se um cabo tem capacidade disponível.

6. **Mistura banco/rascunho sem separação visual clara**: o front não distingue claramente o que é dado oficial do banco e o que é rascunho local. O operador pode confiar em dado que não existe.

7. **633 registros presos em staging**: `stg_enlaces_importacao` tem 633 enlaces que nunca foram promovidos para `enlaces`. Esses dados existem mas não estão no inventário oficial.

---

## 4. BACKLOG PRIORIZADO — BANCO/PERSISTÊNCIA

| # | Item | Impacto | Dependência |
|---|------|---------|-------------|
| 1 | Popular `network_edges` com cabos (`fn_sync_edges_from_cabos`) | Crítico | Banco |
| 2 | Persistir `caixa_emenda` no Supabase (INSERT real) | Crítico | Banco + Front |
| 3 | Persistir `DGO` no Supabase — CRUD completo | Crítico | Banco + Front |
| 4 | Persistir `segmento_cabo` no Supabase (INSERT real) | Crítico | Banco + Front |
| 5 | Persistir `evento_ruptura` no Supabase (INSERT real) | Crítico | Banco + Front |
| 6 | Validar RLS de escrita para as 4 tabelas novas | Crítico | Banco |
| 7 | Separação visual banco/rascunho no front | Alto | Front |
| 8 | Flags: persistir no banco (coluna ou tabela dedicada) | Alto | Banco + Front |
| 9 | Promover 633 registros de `stg_enlaces_importacao` para `enlaces` | Alto | Banco + Processo |
| 10 | Consumir `vw_continuidade_completa` no front (aba Continu.) | Alto | Front |
| 11 | PATCH de `trajeto` em `cabos` ao redesenhar | Médio | Front |
| 12 | Histórico de manutenção: tabela + front básico | Médio | Banco + Front |
| 13 | Ocupação/capacidade: exibir `fibras_livres` nos painéis | Médio | Front |
| 14 | Sync de rascunhos locais para banco ao reconectar | Médio | Front |
| 15 | Auditoria distinguir rascunho local vs dado oficial | Médio | Front |

---

## 5. SEPARAÇÃO POR DEPENDÊNCIA

### Depende só do banco (Claude faz)
- Rodar `fn_sync_edges_from_cabos()` e confirmar contagem
- Validar/criar RLS de escrita para `caixa_emenda`, `segmento_cabo`, `evento_ruptura`
- Criar coluna `flags jsonb` em `sites`, `cabos`, `caixa_emenda`, `dgo` — ou tabela `ativo_flag`
- Criar tabela `historico_manutencao` (ativo_id, ativo_tabela, descricao, usuario_id, criado_em)
- Promover `stg_enlaces_importacao` → `enlaces` após validação do ETL

### Depende só do front (Codex faz)
- Trocar `localStorage` por `POST /rest/v1/{tabela}` em caixa/segmento/ruptura
- Formulário de criação de DGO (não existe ainda)
- Separação visual: badge "OFICIAL" vs "RASCUNHO LOCAL" em cada ativo
- Consumir `vw_continuidade_completa` na aba `Continu.`
- Exibir `fibras_livres` no painel de caixa_emenda
- Fila de sync: salvar local quando offline, enviar ao reconectar

### Depende de banco + front (sequencial)
- Flags: banco cria coluna/tabela → front lê e escreve
- Histórico de manutenção: banco cria tabela → front exibe e insere
- Redesenho de cabo: banco confirma que PATCH em `trajeto` é seguro → front implementa

### Depende de validação (Gemini faz)
- Confirmar que `fn_tracer_bfs` retorna caminho correto após popular edges
- Confirmar que RLS não bloqueia escrita legítima dos 3 usuários
- Confirmar que dados promovidos de staging aparecem corretamente no mapa
- Confirmar que rascunho local e dado oficial ficam visualmente distintos

---

## 6. O QUE É CRÍTICO AGORA

Estes 4 itens, se não resolvidos, fazem o sistema ser um protótipo para sempre:

1. **Popular `network_edges` com cabos** — sem isso o tracer nunca funciona, a continuidade nunca é calculada, o grafo é inútil.

2. **Persistir as 4 tabelas novas** — sem isso o operador perde tudo que cadastra. Não existe inventário sem persistência.

3. **Validar RLS de escrita** — sem isso o INSERT vai falhar silenciosamente para o operador e ele não vai saber por quê.

4. **Formulário de criação de DGO no front** — a tabela existe, o trigger existe, a RLS existe, mas o operador não tem como cadastrar um DGO. A feature está 80% pronta e travada no último passo.

---

## 7. O QUE PODE ESPERAR

- Histórico de manutenção: importante, mas não bloqueia o uso atual
- Ocupação/capacidade de fibras: `fibras_livres` já está calculado, só falta exibir — pode entrar na Sprint 3
- Diagrama de fusão/tubo loose: não iniciado, não bloqueia nada hoje
- BUG 3 (assimetria bidirecional no BFS): não afeta hoje pois todos os cabos são `bidirecional=true`
- Sync de rascunhos locais para banco: importante, mas só faz sentido após a persistência direta estar funcionando

---

## 8. RISCOS DE SEGUIR OPERANDO SEM PERSISTÊNCIA REAL

| Risco | Consequência | Probabilidade |
|-------|-------------|---------------|
| Operador cadastra caixa/DGO/segmento e perde ao fechar browser | Retrabalho, desconfiança no sistema, volta para planilha | Certa |
| Flags de status sumindo ao recarregar | Equipe não compartilha estado operacional — cada um vê uma coisa diferente | Certa |
| Tracer retornando rota errada | Decisão operacional baseada em dado incorreto | Alta |
| 633 enlaces presos em staging | Inventário de enlaces incompleto — análise de impacto errada | Alta |
| Auditoria não distinguindo rascunho/banco | Falsa sensação de pronto — dado some em produção sem aviso | Alta |
| RLS bloqueando escrita sem mensagem clara | Operador tenta salvar, não consegue, acha que salvou | Média |

---

## 9. PRÓXIMA AÇÃO OBJETIVA PARA CLAUDE

**Ação 1 — Popular grafo (hoje):**
```
SELECT COUNT(*) FROM cabos 
WHERE site_a_id IS NOT NULL AND site_b_id IS NOT NULL 
AND trajeto IS NOT NULL AND inativo_em IS NULL;
```
Se > 0: `SELECT fn_sync_edges_from_cabos();`
Confirmar: `SELECT COUNT(*) FROM network_edges WHERE ativo_tabela = 'cabos';`

**Ação 2 — Validar RLS de escrita (hoje):**
Confirmar que `caixa_emenda`, `segmento_cabo` e `evento_ruptura` têm policy de escrita com `check_app_token()`. Se não tiver, criar seguindo o padrão de `dgo`.

**Ação 3 — Criar estrutura de flags (esta semana):**
Decidir entre: (a) coluna `flags jsonb default '{}'` em cada tabela relevante, ou (b) tabela `ativo_flag (id, ativo_tabela, ativo_id, tipo, valor, usuario_id, criado_em)`. Opção (b) é mais limpa para histórico e compartilhamento. Criar e documentar no CONTEXTO_PROJETO.md.

---

## 10. PRÓXIMA AÇÃO OBJETIVA PARA CODEX

**Ação 1 — Persistir caixa_emenda (hoje):**
No formulário de salvar caixa, substituir:
```javascript
// ANTES
localStorage.setItem('caixas', JSON.stringify([...]))
// DEPOIS
await fetch(`${SU}/rest/v1/caixa_emenda`, {
  method: 'POST',
  headers: {...RH, 'Content-Type': 'application/json', 'Prefer': 'return=representation'},
  body: JSON.stringify({ codigo, nome, tipo, site_id, lat, lng, ... })
})
```
Mesmo padrão para `segmento_cabo` e `evento_ruptura`.

**Ação 2 — Formulário de criação de DGO (hoje):**
Criar modal/formulário com campos: `codigo` (obrigatório), `nome`, `site_id` (select de sites), `rack`, `fila`, `bastidor`, `modelo`, `fabricante`, `status`. POST para `/rest/v1/dgo`. Após salvar, recarregar marcadores DGO no mapa.

**Ação 3 — Badge banco/rascunho (esta semana):**
Em cada marcador e painel de ativo, adicionar indicador visual:
- `🔵 OFICIAL` quando o dado veio do banco Supabase
- `🟡 RASCUNHO` quando o dado está só no localStorage

---

## 11. O QUE GEMINI DEVE VALIDAR

1. **Teste de persistência ponta a ponta**: após Codex implementar o INSERT real, criar uma caixa, fechar o browser, reabrir e confirmar que a caixa ainda aparece. Registrar resultado.

2. **Validar RLS em escrita**: tentar fazer um INSERT em `caixa_emenda` via REST com o token anon e com o token de usuário autenticado. Confirmar qual funciona e qual bloqueia corretamente.

3. **Conferir `fn_tracer_bfs` após popular edges**: executar o tracer entre dois sites conhecidos (ex: SAG → VNZ) e confirmar se o caminho retornado faz sentido topológico. Comparar com o que o GeoSite mostraria.

4. **Auditoria distinguindo rascunho/banco**: verificar se a auditoria IA acusa corretamente quando um ativo está só em rascunho local. Se não acusar, classificar como problema de confiabilidade.

5. **Staging → produção**: confirmar que os 633 registros de `stg_enlaces_importacao` estão íntegros e prontos para promoção. Verificar se há duplicatas ou conflitos com `enlaces` existentes antes de promover.

---

## ESTADO RESUMIDO DE PERSISTÊNCIA

| Tabela/Feature | Banco | Front | Persistência real | Prioridade |
|----------------|-------|-------|-------------------|-----------|
| `sites` | ✅ 56.848 linhas | ✅ carrega | ✅ oficial | — |
| `cabos` | ✅ 7.913 linhas | ✅ carrega | ✅ oficial | — |
| `enlaces` | ✅ 2.276 linhas | ✅ carrega | ✅ oficial | — |
| `network_edges` | ⚠️ sem cabos | — | ⚠️ incompleto | Crítico |
| `dgo` | ✅ tabela ok | ❌ sem formulário | ❌ 0 linhas | Crítico |
| `caixa_emenda` | ✅ tabela ok | ⚠️ salva local | ❌ 0 linhas | Crítico |
| `segmento_cabo` | ✅ tabela ok | ⚠️ salva local | ❌ 0 linhas | Crítico |
| `evento_ruptura` | ✅ tabela ok | ⚠️ salva local | ❌ 0 linhas | Crítico |
| `flags` | ❌ não existe | ⚠️ salva local | ❌ não persiste | Alto |
| `stg_enlaces` | ⚠️ 633 em staging | — | ⚠️ não promovido | Alto |
| histórico manut. | ❌ não existe | ❌ não existe | ❌ não existe | Médio |
| ocupação/fibras | ⚠️ calculado | ❌ não exibe | ❌ não visível | Médio |
