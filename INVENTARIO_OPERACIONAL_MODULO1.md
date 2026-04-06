# INVENTARIO OPERACIONAL REAL — MODULO 1

> Escopo funcional local preparado enquanto o Claude estiver indisponivel.
> Objetivo: sair de um mapa de ativos e evoluir para uma representacao fisica rastreavel da rede.

---

## OBJETIVO DO MODULO

Permitir representar no sistema:

- caixas de emenda reais
- DGOs reais
- trechos fisicos de cabo entre pontos reais
- eventos de rompimento e reparo
- pendencias de continuidade e ponta solta

Este modulo e a base para no futuro mapear:

- tubo loose ↔ tubo loose
- fibra ↔ fibra
- carona em outros cabos
- continuidade ponta A → ponta B
- vistoria e inventario completo de rede externa e DGO

---

## PRINCIPIOS FUNCIONAIS

1. Nada deve existir de forma abstrata demais.
   Todo cabo precisa ligar pontos reais: site, caixa ou DGO.

2. Toda interligacao deve ser rastreavel.
   Se um enlace usa carona ou passa por varias caixas, isso precisa aparecer.

3. Tudo que ficar sem continuidade deve gerar pendencia operacional.

4. O mapa deve servir a operacao.
   Bonito e util, mas prioridade total para leitura tecnica e manutencao.

---

## ENTIDADES DO MODULO 1

### 1. Caixa de emenda

Funcao:
- representar caixa em campo
- registrar modelo, fabricante e necessidade de troca
- indicar se foi vistoriada
- vincular observacoes operacionais

Informacoes minimas esperadas:
- codigo
- nome
- tipo de instalacao: aereo, subterraneo, misto
- modelo: ETK, PLP, FIST, outro
- fabricante
- status
- precisa_troca
- vistoriada
- observacao
- coordenada

### 2. DGO

Funcao:
- representar terminacao interna no site
- mapear rack, fila, bastidor e posicoes

Informacoes minimas esperadas:
- codigo
- nome
- site
- rack
- fila
- bastidor
- fabricante
- modelo
- status
- observacao

### 3. Segmento de cabo

Funcao:
- representar o trecho fisico real entre dois pontos concretos
- indicar se o trecho e aereo, subterraneo ou misto

Pontos validos:
- site
- caixa
- dgo

Informacoes minimas esperadas:
- cabo
- ponto A tipo/id
- ponto B tipo/id
- tipo_lancamento
- metragem
- fabricante
- modelo do cabo
- data de fabricacao
- lote
- geometria
- observacao

### 4. Evento de ruptura

Funcao:
- registrar rompimento em campo
- indicar metragem OTDR
- indicar cabo lancado no reparo
- indicar caixa nova criada no reparo

Informacoes minimas esperadas:
- cabo ou segmento afetado
- ponto de falha
- distancia_otdr_m
- metragem_lancada_m
- tipo_reparo
- status
- responsavel
- observacao completa

### 5. Pendencia de continuidade

Funcao:
- sinalizar rede mal cadastrada
- apontar onde falta levantamento

Casos esperados:
- ponta solta
- caixa sem conexao
- dgo sem conexao
- cabo sem origem ou destino coerente
- segmento sem continuidade logica

---

## FLUXOS LOCAIS QUE O FRONT PRECISA TER

### Fluxo 1: cadastrar caixa

O usuario deve conseguir:
- clicar no mapa
- escolher "nova caixa de emenda"
- preencher modelo, fabricante, tipo de instalacao, status, precisa_troca, vistoriada
- salvar com observacao rica

Resultado esperado no mapa:
- marcador proprio de caixa
- popup/painel com todos os dados tecnicos

### Fluxo 2: cadastrar DGO

O usuario deve conseguir:
- abrir um site
- adicionar DGO vinculado ao site
- informar rack, fila, bastidor, modelo, fabricante e observacao

Resultado esperado:
- DGO visivel no painel do site
- possibilidade futura de inventariar fibras no DGO

### Fluxo 3: cadastrar segmento fisico

O usuario deve conseguir:
- desenhar trecho no mapa
- escolher ponto A e ponto B reais
- definir se e aereo, subterraneo ou misto
- informar metragem, cabo, fabricante, lote e observacao

Resultado esperado:
- o cabo deixa de ser apenas um desenho
- passa a ser um trecho com origem e destino rastreaveis

### Fluxo 4: registrar ruptura

O usuario deve conseguir:
- clicar no ponto do rompimento
- informar metragem OTDR
- informar se houve lancamento de cabo
- informar se criou nova caixa
- descrever o reparo

Resultado esperado no mapa:
- ponto de rompimento com cor propria
- trecho novo lancado com outra cor
- marcador da nova caixa
- observacao operacional completa

### Fluxo 5: painel de pendencias

O usuario deve conseguir:
- abrir lista de pendencias
- ver ponta solta e continuidade quebrada
- clicar e ir para o ponto no mapa

---

## REGRAS DE NEGOCIO LOCAIS

1. Um cabo so deve ser considerado valido se tiver continuidade por pontos reais.

2. Um segmento deve sempre ligar dois pontos validos.

3. Rompimento com cabo lancado deve gerar:
- marca do ponto de falha
- trecho novo destacado
- caixa nova quando aplicavel

4. Caixa sem vistoria deve ficar identificada.

5. Caixa com `precisa_troca = true` deve aparecer em destaque operacional.

6. Tudo que ficar sem fechamento logico deve entrar em pendencia.

---

## O QUE O FRONT PRECISARA MOSTRAR

### No mapa

- caixas
- DGOs
- segmentos
- pontos de ruptura
- trechos reparados
- pendencias

### No painel lateral

- busca por caixa, DGO, cabo e codigo
- filtros por tipo de instalacao
- filtros por status
- filtros por precisa_troca
- filtros por vistoriada

### No painel do ativo

Para caixa:
- modelo
- fabricante
- tipo de instalacao
- status
- vistoriada
- precisa_troca
- observacao

Para DGO:
- site
- rack
- fila
- bastidor
- modelo
- fabricante
- observacao

Para segmento:
- ponto A
- ponto B
- tipo de lancamento
- cabo
- lote
- fabricante
- modelo
- metragem
- observacao

Para ruptura:
- cabo/segmento
- distancia OTDR
- metragem lancada
- nova caixa
- responsavel
- status
- observacao

---

## PROXIMA IMPLEMENTACAO LOCAL ASSIM QUE O BANCO ESTIVER PRONTO

1. adicionar abas e formularios no `mapa-rede-optica.html`
2. criar marcadores visuais para caixa e ruptura
3. criar fluxo de cadastro de segmento
4. criar fluxo de cadastro de DGO
5. criar painel de pendencias

---

## DEPENDENCIA EXTERNA

Este modulo depende do banco Supabase para:

- criar as tabelas base
- expor endpoints REST
- fornecer views de pendencia
- garantir integridade com FKs e constraints

Enquanto o banco nao estiver pronto, o front nao deve inventar estrutura definitiva.
