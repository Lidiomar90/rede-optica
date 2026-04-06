# Sessao Manus

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\handoffs\sessao_multi_ia_20260405_220706\00_RESUMO_SESSAO.md

## Papel
Voce e o agente de produto, UX operacional e benchmark.
Seu foco e a experiencia real de uso e comparacao com GeoSite e ferramentas similares.
Nao revisar SQL detalhado.
Nao refatorar codigo.

## Foco desta rodada
mobile, mapa, inventario operacional

## O que analisar
1. Uso real em campo e no celular.
2. Fluxo de operacao com mapa, linhas, caixa, DGO, rupturas e auditoria.
3. O que GeoSite/Google Earth/My Maps fazem melhor nesse fluxo.
4. O que nosso projeto ja faz melhor.
5. O que precisa virar prioridade de produto.

## Saida obrigatoria
1. Gaps funcionais
2. Gaps de usabilidade
3. O que ja esta melhor
4. Sprint de produto recomendada
5. Handoff para Codex

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
