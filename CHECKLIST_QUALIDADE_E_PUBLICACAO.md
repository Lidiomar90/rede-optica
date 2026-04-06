# Checklist Mestre de Qualidade e Publicacao

## Objetivo

Garantir que a Rede Optica MG esteja operacional de ponta a ponta antes de cada publicacao, com criterio de time senior:

- dados corretos
- mapa funcional
- inventario coerente
- fluxos de operacao validados
- regressao minimizada
- backlog explicito do que ainda nao esta pronto

---

## 1. Gate de Publicacao

Publicar somente se todos os itens abaixo estiverem `OK`:

- login funciona
- `mapa-rede-optica.html` abre sem erro visivel
- sites carregam
- cabos carregam
- `science_sites_mg.json` esta publicado junto
- aba `Sites` mostra agrupamento por `CN / DDD` e `localidade`
- aba `Auditoria IA` abre e mostra score/achados
- cadastro local de `caixa`
- cadastro local de `DGO`
- cadastro local de `segmento`
- pendencias automaticas aparecem
- `PUBLICAR-GIT.ps1` leva todos os arquivos necessarios

Se algum item acima falhar, a publicacao e classificada como:

- `bloqueada` se afetar operacao basica
- `incremental` se o problema nao impedir uso principal

---

## 2. Checklist Tecnico Completo

### A. Frontend Base

- [ ] [mapa-rede-optica.html](/C:/FIBRA%20CADASTRO/mapa-rede-optica.html) abre sem tela branca
- [ ] console sem erro JS critico
- [ ] tema escuro/claro alterna sem quebrar layout
- [ ] menu superior troca abas corretamente
- [ ] painel lateral abre em desktop e mobile
- [ ] busca nao trava a interface

### B. Login e Sessao

- [ ] login com usuario valido funciona
- [ ] usuario invalido recebe erro claro
- [ ] logout funciona
- [ ] perfil admin exibe aba de usuarios
- [ ] perfil leitura nao expõe acoes de escrita

### C. Mapa Principal

- [ ] contagem de sites aparece
- [ ] contagem de cabos aparece
- [ ] contagem de spans aparece
- [ ] sites renderizam no mapa
- [ ] cabos renderizam no mapa
- [ ] clique em site abre painel
- [ ] clique em cabo abre painel
- [ ] zoom/fitBounds nao jogam o mapa para coordenadas incorretas

### D. Aba Sites

- [ ] aba `Sites` sai do modo `Camadas`
- [ ] agrupamento por `CN / DDD` aparece visualmente
- [ ] localidade aparece dentro de cada CN
- [ ] itens clicaveis focam o mapa
- [ ] sem duplicidade por codigo
- [ ] site enriquecido com Science mostra `CN`, `localidade`, `endereco`, `ID financeiro`

### E. Base Science

- [ ] [science_sites_mg.json](/C:/FIBRA%20CADASTRO/science_sites_mg.json) existe localmente
- [ ] arquivo foi publicado no GitHub Pages
- [ ] [importar_science.py](/C:/FIBRA%20CADASTRO/importar_science.py) gera JSON sem erro
- [ ] total atual da base Science confere com a ultima geracao
- [ ] codigos duplicados nao existem
- [ ] sites sem coordenada invalida foram filtrados

### F. Auditoria IA Local

- [ ] aba `Auditoria IA` abre
- [ ] score operacional aparece
- [ ] resumo aparece
- [ ] fila de implementacao aparece
- [ ] achados da auditoria aparecem
- [ ] auditoria detecta ausencia da Science
- [ ] auditoria detecta agrupamento CN/localidade ausente
- [ ] auditoria detecta DGO sem site resolvido
- [ ] auditoria detecta segmento quebrado

### G. Inventario Operacional Local

- [ ] salvar `caixa` em rascunho funciona
- [ ] salvar `DGO` em rascunho funciona
- [ ] salvar `segmento` em rascunho funciona
- [ ] salvar `ruptura` em rascunho funciona
- [ ] resumo de rascunhos atualiza
- [ ] limpar rascunhos funciona

### H. Caixa de Emenda

- [ ] criar caixa pelo formulario
- [ ] criar caixa pelo mapa
- [ ] clique na caixa abre painel
- [ ] assistente de conexao da caixa abre
- [ ] pre-conexao da caixa salva
- [ ] diagrama de conexao aparece
- [ ] pendencia `caixa_sem_conexao` aparece quando necessario
- [ ] pendencia `ponta_solta` aparece quando necessario

### I. DGO

- [ ] criar DGO pelo formulario
- [ ] DGO aparece no mapa
- [ ] clique no DGO abre painel proprio
- [ ] DGO pode ser usado como `Ponto A`
- [ ] DGO pode ser usado como `Ponto B`
- [ ] assistente de conexao do DGO abre
- [ ] conexao do DGO salva em rascunho
- [ ] pendencia `dgo_sem_site_resolvido` aparece quando necessario
- [ ] pendencia `dgo_sem_conexao` aparece quando necessario
- [ ] pendencia `dgo_incompleto` aparece quando necessario

### J. Segmentos

- [ ] desenhar segmento no mapa funciona
- [ ] formulario recebe metragem
- [ ] selecao `Ponto A` no mapa funciona
- [ ] selecao `Ponto B` no mapa funciona
- [ ] segmento em rascunho aparece no mapa
- [ ] editar segmento existente funciona
- [ ] segmento liga `site ↔ caixa`
- [ ] segmento liga `caixa ↔ DGO`
- [ ] segmento liga `site ↔ DGO`

### K. Ruptura e OTDR

- [ ] abrir OTDR funciona
- [ ] ponto de ruptura aparece
- [ ] trecho lancado aparece
- [ ] nova caixa visual aparece quando ha metragem lancada
- [ ] incidente pode ser gerado a partir do OTDR
- [ ] ruptura em rascunho aparece no mapa

### L. Rotas e Tracer

- [ ] formulario de rota salva
- [ ] lista de rotas carrega
- [ ] tracer abre
- [ ] tracer nao usa mais logica incorreta se o banco ja tiver RPC correta
- [ ] caminho exibido condiz com o banco

### M. ETL Telegram

- [ ] [etl_telegram_rede_optica.py](/C:/FIBRA%20CADASTRO/etl_telegram_rede_optica.py) compila
- [ ] `SB_KEY` via ambiente funciona
- [ ] `vw_sites_lookup` resolve os codigos
- [ ] `--dry-run` executa
- [ ] parser reconhece `SAG`, `VNZ`, `MGSAG`, `MGVNZ`
- [ ] falsos positivos principais foram reduzidos

### N. Publicacao

- [ ] [PUBLICAR-GIT.ps1](/C:/FIBRA%20CADASTRO/PUBLICAR-GIT.ps1) inclui `science_sites_mg.json`
- [ ] `.gitignore` protege `telegram/`, `*.dwg`, `*.apk`, `privado/`
- [ ] publish conclui sem erro real
- [ ] GitHub Pages atualiza a versao nova

---

## 3. O Que Hoje Parece Solido

- mapa principal carregando dados reais
- publicacao automatizada
- base Science gerada localmente
- auditoria local inicial
- inventario local em rascunho
- caixa e DGO com fluxo basico local

---

## 4. O Que Hoje Ainda Esta Incompleto

- `DGO` ainda esta forte no front local, mas nao consolidado no banco
- `caixa_emenda`, `segmento_cabo` e `evento_ruptura` reais no Supabase ainda dependem do Claude/banco
- tracer do front ainda precisa estar 100% plugado no RPC correto do banco
- auditoria ainda e baseada em regras locais, nao corrige sozinha
- parte do inventario ainda e `rascunho local`, nao persistencia oficial

---

## 5. O Que Hoje Esta Meia-Boca ou com Risco

- agrupamento `CN / DDD` dependia da Science publicada; sem o JSON no Pages, falhava silenciosamente
- auditoria inicial nao estava acusando esse erro com firmeza suficiente
- existem fluxos que parecem prontos visualmente, mas ainda nao estao persistidos no banco
- o projeto mistura front real, rascunho local e banco oficial; isso precisa ficar explicitamente separado

---

## 6. Criterio Senior de Aprovacao

Projeto so pode ser chamado de `operacional de alto nivel` quando:

- o que aparece no mapa corresponde ao dado oficial
- o que o usuario cadastra nao se perde
- o sistema detecta inconsistencias sozinho
- o backlog do que falta esta visivel
- nao existe falsa sensacao de pronto

Hoje o projeto esta em:

- `bom prototipo operacional evoluido`

Ainda nao esta em:

- `inventario operacional definitivo`

---

## 7. Regra de Decisao

### Pode publicar como melhoria incremental

Quando:

- mapa abre
- sites/cabos carregam
- Science publicada aparece
- auditoria funciona
- nao ha erro JS critico

### Nao pode publicar como versao “definitiva”

Enquanto:

- DGO nao estiver persistido no banco
- continuidade nao estiver validada no backend
- ruptura/caixa/segmento nao estiverem em modelo oficial no Supabase
