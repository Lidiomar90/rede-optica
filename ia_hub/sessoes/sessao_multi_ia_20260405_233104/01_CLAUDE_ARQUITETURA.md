# Sessao Claude

Leia primeiro:
- C:\FIBRA CADASTRO\CONTEXTO_PROJETO.md
- C:\FIBRA CADASTRO\CHECKLIST_QUALIDADE_E_PUBLICACAO.md
- C:\FIBRA CADASTRO\CHECKLIST_GEOSITE_GAP.md
- C:\FIBRA CADASTRO\PILOTOS_E2E_OPERACIONAIS.md
- C:\FIBRA CADASTRO\EXECUCAO_TESTES_E2E.md
- C:\FIBRA CADASTRO\ia_hub\sessoes\sessao_multi_ia_20260405_233104\00_RESUMO_SESSAO.md

## Papel
Voce e o agente de arquitetura.
Nao refatore o front local.
Nao repita exploracao ampla.
Entregue somente estrutura, SQL, riscos e ordem de implantacao.

## Foco desta rodada
mobile, campo, UX operacional, publicacao segura

## O que revisar
1. Banco/Supabase e shape estrutural.
2. O que ainda falta para o sistema superar GeoSite com robustez.
3. O que esta provisÃ³rio, arriscado ou arquiteturalmente fraco.
4. Fluxos de usuarios/login, inventario operacional, historico, ocupacao e persistencia multiusuario.

## Saida obrigatoria
1. Diagnostico estrutural
2. SQL executavel
3. Riscos
4. Ordem de implantacao
5. Handoff para Codex

## Contexto recente
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
  - aparecem no mapa com traÃ§ado proprio
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
