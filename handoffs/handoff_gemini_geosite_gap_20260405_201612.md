# Handoff Gemini â€” Gap Operacional vs GeoSite

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md

## Papel

Voce e o agente de validacao.
Quero uma analise pratica, nao conceitual.
Valide o uso real do mapa e compare com o que o usuario espera de um GeoSite operacional.

## Foco desta rodada

Analisar com prioridade:

1. mapa e leitura de linhas
2. DGO
3. caixa de emenda
4. usabilidade geral
5. uso em campo/mobile
6. se a auditoria realmente ajuda ou so parece ajudar

## Regra importante

Nao assuma que porque existe no HTML, funciona bem.
Valide em experiencia de uso:

- o que o GeoSite normalmente entrega e aqui ainda nao entrega
- o que aqui existe mas esta fraco
- o que aqui ja esta melhor

## Quadro de comparacao esperado

Quero que voce devolva em 3 blocos:

### 1. Falta aqui e faz falta

Liste o que ainda esta abaixo do que se espera de um GeoSite em:
- linhas
- navegacao
- DGO
- caixa
- operacao em campo

### 2. Existe, mas esta meia-boca

Liste o que existe no mapa atual, mas nao esta suficientemente robusto ou fluido.

### 3. Ja esta melhor

Liste o que o projeto atual ja faz melhor que um mapa operacional comum.

## Validacoes especificas

Use como criterio:
- clique em site
- clique em cabo
- clique em segmento
- clique em caixa
- clique em DGO
- clique/toque longo
- menu contextual
- edicao de linhas
- uso como Ponto A/B
- ruptura contextual
- auditoria com acao executavel

## Entrega desejada

Responda com:

1. Achados criticos
2. Achados altos
3. Achados medios
4. O que esta melhor que GeoSite
5. Proxima sprint recomendada

## Checklist GeoSite gap
# Checklist de Gap vs GeoSite

## Objetivo

Comparar a experiencia operacional do mapa atual da Rede Optica MG com o que o GeoSite normalmente entrega ou com o que voce ja usa no GeoSite em campo.

Este checklist nao serve para â€œficar bonitoâ€.
Serve para descobrir:

- o que o GeoSite faz e aqui ainda nao faz
- o que aqui ate existe, mas ainda esta fraco ou meia-boca
- o que ja esta melhor que o GeoSite

---

## 1. Mapa Base

- [ ] o mapa abre rapido
- [ ] o mapa nao abre poluido por padrao
- [ ] o operador escolhe o que ligar
- [ ] o preset de campo reduz o ruido visual
- [ ] a leitura das linhas fica clara em zoom medio e alto
- [ ] o clique no ativo nao exige â€œcaÃ§arâ€ no mapa

### Gap se falhar

- comportamento inferior ao GeoSite em leitura operacional basica

---

## 2. Sites

- [ ] site aparece com sigla/codigo primeiro
- [ ] site tem painel com informacao suficiente
- [ ] site mostra continuidade relacionada
- [ ] site pode virar `Ponto A`
- [ ] site pode virar `Ponto B`
- [ ] site permite abrir ruptura contextual
- [ ] toque longo/clique direito no site abre acoes uteis

### Gap se falhar

- o mapa ainda esta mais proximo de â€œvisualizacaoâ€ do que de ferramenta operacional

---

## 3. Linhas / Cabos

- [ ] cabo oficial abre painel proprio
- [ ] cabo mostra estado operacional
- [ ] cabo mostra rupturas ligadas
- [ ] cabo pode ser redesenhado
- [ ] clique direito no cabo abre acoes rapidas
- [ ] o operador entende facilmente se o cabo esta:
  - operacional
  - com ruptura
  - sem inventario local

### Gap se falhar

- GeoSite costuma parecer mais â€œclicavelâ€ e mais navegavel nas linhas do que o mapa atual

---

## 4. Segmentos

- [ ] segmento em rascunho aparece claramente no mapa
- [ ] segmento pode ser editado sem recriar
- [ ] ponto A/B podem ser reatribuÃ­dos
- [ ] segmento mostra estado operacional
- [ ] segmento indica se esta pronto para campo
- [ ] clique direito no segmento abre acoes uteis

### Gap se falhar

- continuidade fisica ainda esta mais fraca do que deveria para uso real

---

## 5. Caixa de Emenda

- [ ] caixa pode ser criada pelo mapa
- [ ] caixa pode ser criada pelo formulario
- [ ] caixa abre painel tecnico
- [ ] caixa mostra resumo operacional
- [ ] caixa mostra conexoes relacionadas
- [ ] caixa abre assistente de conexao
- [ ] caixa pode virar `Ponto A/B`
- [ ] toque longo/clique direito na caixa abre acoes rapidas

### Gap se falhar

- o operador ainda nao consegue tratar a caixa como entidade operacional de verdade

---

## 6. DGO

- [ ] DGO aparece como ponto real no mapa
- [ ] DGO abre painel proprio
- [ ] DGO mostra continuidade
- [ ] DGO mostra conexoes registradas
- [ ] DGO pode virar `Ponto A/B`
- [ ] DGO abre assistente de conexao
- [ ] auditoria acusa DGO sem site e DGO sem conexao
- [ ] toque longo/clique direito no DGO abre acoes rapidas

### Gap se falhar

- DGO ainda esta abaixo do nivel esperado para ferramenta de rede de alto nivel

---

## 7. Ruptura / OTDR

- [ ] ruptura aparece com destaque claro
- [ ] marcador de cabo lancado aparece
- [ ] nova caixa aparece quando aplicavel
- [ ] o operador consegue sair da ruptura e ir para o ponto relacionado
- [ ] auditoria prioriza ruptura como item alto

### Gap se falhar

- uso em contingencia/campo continua inferior ao ideal

---

## 8. Usabilidade

- [ ] clique esquerdo faz a acao principal esperada
- [ ] clique direito abre menu contextual util
- [ ] toque longo funciona no mobile
- [ ] o usuario nao precisa voltar toda hora para a sidebar
- [ ] a auditoria leva para a correcao com um clique
- [ ] o sistema reduz passos em vez de aumentar passos

### Gap se falhar

- GeoSite pode continuar parecendo mais fluido mesmo sem ter mais recurso

---

## 9. Mobile e Campo

- [ ] botÃµes ficam grandes o suficiente
- [ ] desenhar linha no mobile e viavel
- [ ] finalizar / desfazer / cancelar ficam claros
- [ ] field bar ajuda de verdade
- [ ] cache local ajuda sem rede
- [ ] modo campo reduz o peso visual

### Gap se falhar

- o sistema ainda fica â€œdesktop-firstâ€, nao â€œfield-firstâ€

---

## 10. Auditoria

- [ ] auditoria detecta erro real
- [ ] auditoria prioriza o que bloqueia campo
- [ ] auditoria distingue:
  - quebrado
  - pendente
  - pronto para campo
- [ ] auditoria oferece acao executavel
- [ ] auditoria nao gera falsa sensaÃ§Ã£o de pronto

### Gap se falhar

- a IA ainda esta mais para painel bonito do que para ferramenta de operacao

---

## 11. O Que Ja Parece Melhor Que GeoSite

Marcar somente quando estiver realmente melhor:

- [ ] agrupamento por CN / DDD e localidade
- [ ] auditoria operacional com score e priorizacao
- [ ] sugestao automatica de caixa/emenda
- [ ] navegaÃ§Ã£o entre ativos relacionados
- [ ] ruptura com cabo lanÃ§ado e nova caixa
- [ ] preset de campo

---

## 12. Decisao Final

- [ ] ainda abaixo do GeoSite
- [ ] equivalente ao GeoSite
- [ ] melhor que o GeoSite em uso operacional

## Observacao final

Descrever sem filtro:

- o que ainda esta fraco
- o que esta quebrado
- o que esta melhor
- o que precisa entrar na proxima sprint

## Execucao recente
# Execucao dos Testes E2E

## Regra

Para cada piloto:

- marque `OK` ou `FALHOU`
- descreva o que foi encontrado de verdade
- classifique a falha:
  - `front`
  - `banco`
  - `dados`
  - `deploy`
  - `processo`
- defina a proxima acao

---

## Rodada Atual

Data:

Executor:

Versao publicada:

Commit:

---

## Piloto 1 â€” Abertura Basica

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 2 â€” Science + CN / DDD

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 3 â€” Caixa

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 4 â€” DGO

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 5 â€” Segmento

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 6 â€” Ruptura

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 7 â€” Auditoria Detecta Regressao

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Piloto 8 â€” Publicacao

Status:

Resultado encontrado:

Tipo de falha:

Proxima acao:

---

## Decisao Final

- [ ] Pode publicar incrementalmente
- [ ] Nao pode publicar
- [ ] Pode seguir para consolidacao com banco

Observacao final:

## Contexto recente
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
  - desenho de linha agora fica viÃ¡vel no mobile sem depender de duplo clique
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

### Melhoria recente adicional â€” toque longo por ativo

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
