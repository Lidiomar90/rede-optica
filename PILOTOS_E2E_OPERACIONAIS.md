# Pilotos e Testes Ficticios E2E

## Objetivo

Rodar cenarios controlados, do inicio ao fim, para provar o comportamento do sistema como se fosse operacao real.

Cada piloto abaixo deve registrar:

- resultado esperado
- resultado encontrado
- status final
- se a falha e de front, banco, dados ou processo

---

## Piloto 1 — Abertura Basica do Sistema

### Cenario

Usuario abre o portal, entra no mapa e verifica se o sistema esta vivo.

### Passos

1. abrir [mapa-rede-optica.html](/C:/FIBRA%20CADASTRO/mapa-rede-optica.html)
2. fazer login com usuario valido
3. esperar o carregamento do mapa
4. verificar contadores no topo
5. trocar para aba `Sites`
6. abrir `Auditoria IA`

### Esperado

- sem erro visual
- mapa com sites e cabos
- aba `Sites` funcional
- aba `Auditoria IA` mostrando score

### Falha critica se

- login falhar
- mapa nao carregar
- aba `Sites` ficar vazia
- auditoria nao abrir

---

## Piloto 2 — Science + Agrupamento CN / DDD

### Cenario

Verificar se a base Science publicada esta realmente enriquecendo os sites.

### Passos

1. abrir aba `Sites`
2. conferir se aparecem grupos `CN / DDD`
3. abrir uma localidade
4. clicar em um site da localidade
5. validar `CN`, `localidade`, `endereco` e `ID financeiro`

### Esperado

- grupos `CN / DDD` visiveis
- localidade dentro do CN
- site com dados Science

### Falha critica se

- a aba `Sites` nao agrupar por `CN / DDD`
- a Science nao estiver publicada
- o painel do site nao mostrar dados extras

---

## Piloto 3 — Caixa de Emenda Operacional

### Cenario

Criar uma caixa, conecta-la e ver o sistema detectar pendencias.

### Dados ficticios

- codigo: `CX-PILOTO-001`
- nome: `Caixa teste abordagem BAM`
- tipo: `aereo`
- modelo: `FIST`
- fabricante: `Furukawa`
- status: `vistoriar`

### Passos

1. criar a caixa pelo formulario
2. clicar nela no mapa
3. abrir `Assistente de conexão`
4. salvar uma pre-conexao
5. checar pendencias

### Esperado

- caixa aparece no mapa
- painel da caixa abre
- diagrama mostra conexoes
- pendencias coerentes aparecem

### Falha alta se

- a caixa nao renderizar
- o painel nao abrir
- a conexao nao salvar

---

## Piloto 4 — DGO como Ponto Real

### Cenario

Cadastrar DGO, ligando-o a um site conhecido e validando continuidade.

### Dados ficticios

- codigo: `DGO-SAG-PILOTO-01`
- site: `SAG`
- rack: `Rack 02`
- fila: `Fila 2A`
- bastidor: `BT 41/46`
- modelo: `Huawei`
- fabricante: `Huawei`

### Passos

1. cadastrar o DGO
2. verificar se ele aparece no mapa
3. clicar no DGO
4. abrir `Conectar DGO`
5. salvar uma conexao
6. criar um segmento usando o DGO como ponta
7. abrir `Auditoria IA`

### Esperado

- DGO aparece no mapa
- painel do DGO abre
- DGO pode ser ponta A ou B
- auditoria acusa pendencia se a continuidade ficar incompleta

### Falha critica se

- DGO nao aparece
- DGO nao e selecionavel
- DGO nao entra em pendencias

---

## Piloto 5 — Segmento Fisico Completo

### Cenario

Criar um segmento entre dois pontos reais e editar depois.

### Dados ficticios

- cabo: `PILOTO-SAG-DGO-001`
- ponto A: `SAG`
- ponto B: `DGO-SAG-PILOTO-01`
- tipo: `misto`
- metragem: `200`
- fabricante: `Prysmian`
- lote: `LOT-PILOTO-2026`

### Passos

1. abrir cadastro de segmento
2. selecionar `Ponto A` no mapa
3. selecionar `Ponto B` no mapa
4. salvar
5. clicar na linha
6. editar o segmento

### Esperado

- segmento aparece
- painel abre
- edicao atualiza o rascunho existente

### Falha alta se

- segmento nao desenha
- ponto A/B nao resolve
- editar duplica em vez de atualizar

---

## Piloto 6 — Ruptura com Cabo Lancado

### Cenario

Simular uma ruptura com nova caixa e cabo lancado.

### Dados ficticios

- cabo: `PILOTO-SAG-DGO-001`
- OTDR: `3500`
- cabo lancado: `200`
- nova caixa: `CX-PILOTO-002`
- tipo reparo: `nova_caixa`

### Passos

1. cadastrar ruptura
2. verificar marcador no mapa
3. verificar indicativo de trecho lancado
4. verificar se a nova caixa aparece

### Esperado

- marcador de ruptura
- marcador de cabo lancado
- indicacao visual clara

### Falha alta se

- ruptura nao aparecer
- informacoes de OTDR sumirem

---

## Piloto 7 — Auditoria Deve Acusar Regressao

### Cenario

Testar se a auditoria detecta um erro real de estrutura.

### Setup ficticio

- remover temporariamente `science_sites_mg.json` do publish
- ou cadastrar DGO com `site` invalido

### Esperado

- auditoria marca problema alto
- fila de implementacao aponta o ajuste
- score cai

### Falha critica se

- o erro existe e a auditoria nao acusa

---

## Piloto 8 — Publicacao

### Cenario

Garantir que a versao publicada no GitHub Pages reflete a local.

### Passos

1. rodar [PUBLICAR-GIT.ps1](/C:/FIBRA%20CADASTRO/PUBLICAR-GIT.ps1)
2. aguardar Pages atualizar
3. abrir [mapa-rede-optica.html](https://lidiomar90.github.io/rede-optica/mapa-rede-optica.html)
4. repetir Pilotos 1 e 2 rapidamente

### Esperado

- o online reflete o local
- `science_sites_mg.json` esta disponivel
- agrupamento `CN / DDD` aparece no online

### Falha critica se

- local funciona e online nao

---

## Tabela de Status Recomendada

Para cada piloto, registrar:

| Piloto | Resultado | Tipo de falha | Acao |
|---|---|---|---|
| 1 | OK / FALHOU | front / banco / dados / deploy | corrigir |
| 2 | OK / FALHOU | front / dados / deploy | corrigir |
| 3 | OK / FALHOU | front / logica | corrigir |
| 4 | OK / FALHOU | front / banco / modelo | corrigir |
| 5 | OK / FALHOU | front / logica | corrigir |
| 6 | OK / FALHOU | front / operacao | corrigir |
| 7 | OK / FALHOU | auditoria | corrigir |
| 8 | OK / FALHOU | deploy | corrigir |

---

## Julgamento Senior

Se os pilotos 1, 2, 4, 5, 7 e 8 falharem, o sistema ainda nao pode ser chamado de:

- `inventario operacional confiavel`

Se passarem, ele pode ser chamado de:

- `plataforma operacional em consolidacao`

Se tudo passar e o banco estiver alinhado, ai sim ele se aproxima de:

- `produto operacional de alto nivel`
