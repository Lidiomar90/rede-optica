# Esteira Mobile/Campo — Rede Optica MG
**Gerado em:** 2026-04-05
**Papel:** Coordenador de backlog — foco mobile/campo

---

## 1. PRINCIPAIS GARGALOS MOBILE/CAMPO

### Gargalo 1 — Área útil do mapa destruída por controles
A barra de campo, legenda, botões laterais e sidebar competem pelo mesmo espaço em tela pequena. Em 360×800px (Android comum de campo) o mapa visível é menos de 50% da tela. O operador não consegue ver o que está clicando.

### Gargalo 2 — Legenda não recolhe de verdade
A legenda foi marcada como "recolhível no celular", mas continua ocupando espaço fixo quando aberta. Não há gesto de swipe para fechar. Em campo, o operador abre a legenda uma vez e não consegue fechar rápido.

### Gargalo 3 — Desenho de linha ainda depende de duplo clique
O fluxo de desenho foi adaptado para mobile, mas o ponto de finalização ainda tem comportamento inconsistente entre toque simples e duplo toque. Em campo com luva ou tela suja, duplo toque falha.

### Gargalo 4 — Auditoria IA não é usável no celular
Os cards da auditoria foram compactados, mas o painel ainda abre em modal de largura fixa que ultrapassa a tela. O score e os achados ficam cortados. A ação "corrigir" fica fora da área de toque.

### Gargalo 5 — Sem feedback de rede ruim
O modo offline existe, mas o indicador só aparece quando a rede cai completamente. Com rede lenta (2G/3G de campo), o mapa trava sem aviso. O operador não sabe se está carregando ou travado.

### Gargalo 6 — Cache local não cobre tudo
O cache cobre `sites` e `cabos`, mas não cobre `caixas_emenda`, `DGOs`, `segmentos` e `rupturas`. Em campo sem rede, o operador perde acesso a exatamente os ativos que mais precisa ver.

### Gargalo 7 — Barra de campo com atalhos que não funcionam offline
Os atalhos `nova caixa`, `nova ruptura` e `auditoria` na barra de campo abrem formulários que tentam buscar dados do banco. Sem rede, os formulários ficam em branco ou travam.

---

## 2. O QUE ESTÁ PESADO, SOBREPOSTO OU RUIM DE USAR

| Elemento | Problema real |
|----------|--------------|
| Sidebar lateral | Abre por cima do mapa, sem overlay escurecido, sem gesto de fechar por swipe |
| Botões de camadas | Ficam empilhados verticalmente, área de toque pequena, sem agrupamento visual claro |
| Painel de ativo | Abre em modal que não respeita safe area do iOS (notch/home bar) |
| Barra de campo | 5 atalhos em linha — em tela pequena os ícones ficam apertados, sem label visível |
| Legenda | Não tem posição fixa inteligente — sobrepõe o mapa em zoom baixo |
| Formulário de segmento | Campo de metragem usa input numérico sem teclado numérico forçado no mobile |
| Auditoria IA | Modal de largura fixa, scroll interno não funciona bem em iOS Safari |
| Toque longo | Delay de 500ms padrão — em campo com pressa parece que não funcionou |

---

## 3. O QUE ESTÁ IMPLEMENTADO MAS MEIA-BOCA

- **Modo Campo**: existe e aplica preset enxuto, mas não persiste entre sessões de forma confiável. Ao reabrir o browser, o modo campo some.
- **Cache offline**: implementado para sites/cabos, mas sem indicador de "última atualização do cache" — o operador não sabe se o cache tem 10 minutos ou 3 dias.
- **Toque longo por ativo**: implementado para site, caixa, DGO, ruptura — mas não para cabo/segmento no mobile. Clique em linha fina no celular é impreciso.
- **Barra de desenho**: `desfazer`, `finalizar`, `cancelar` existem, mas os botões somem quando o teclado virtual abre no mobile (viewport resize).
- **GPS**: atalho na barra de campo existe, mas não centraliza o mapa na posição atual de forma confiável em todos os browsers mobile.
- **Perfis rápidos** (`campo`, `limpo`, `transporte`, `incidentes`): existem, mas não há indicador visual de qual perfil está ativo no momento.
- **Controles maiores no mobile**: aumentados, mas sem feedback tátil (vibração) ao confirmar ação crítica como "salvar ruptura".

---

## 4. BACKLOG PRIORIZADO — SÓ MOBILE/CAMPO

| # | Item | Impacto campo | Esforço |
|---|------|--------------|---------|
| 1 | Área útil do mapa: sidebar como drawer com overlay + swipe para fechar | Crítico | Médio |
| 2 | Barra de campo: labels visíveis + área de toque mínima 48px | Crítico | Baixo |
| 3 | Formulários offline: funcionar sem rede (salvar local, sync depois) | Crítico | Alto |
| 4 | Cache offline expandido: caixas, DGOs, segmentos, rupturas | Crítico | Médio |
| 5 | Indicador de rede: lenta / offline / online com timestamp do cache | Alto | Baixo |
| 6 | Auditoria IA: modal responsivo com scroll nativo, ação "corrigir" sempre visível | Alto | Médio |
| 7 | Desenho de linha: finalizar por botão fixo, sem depender de duplo toque | Alto | Médio |
| 8 | Toque longo: delay reduzido para 300ms + feedback visual imediato | Alto | Baixo |
| 9 | Modo Campo: persistir em localStorage + indicador visual de modo ativo | Alto | Baixo |
| 10 | Painel de ativo: respeitar safe area iOS/Android (padding bottom dinâmico) | Médio | Baixo |
| 11 | Perfil ativo: badge/indicador no botão de perfis rápidos | Médio | Baixo |
| 12 | Barra de desenho: posição fixa que não some com teclado virtual | Médio | Médio |
| 13 | GPS: centralizar mapa + marcador de posição atual confiável | Médio | Médio |
| 14 | Cabo/segmento: toque longo em linha com área de toque expandida | Médio | Alto |
| 15 | Feedback tátil: vibração em ações críticas (salvar, confirmar ruptura) | Baixo | Baixo |

---

## 5. SPRINTS

### Sprint 1 — Mapa usável no celular (1 semana)
> Objetivo: o operador consegue abrir o mapa, navegar e clicar em ativos sem frustração

- [ ] Sidebar como drawer com overlay escurecido + swipe para fechar
- [ ] Barra de campo: labels visíveis + toque mínimo 48px em todos os botões
- [ ] Toque longo: delay 300ms + feedback visual (highlight imediato)
- [ ] Modo Campo: persistir em localStorage + badge de modo ativo
- [ ] Painel de ativo: safe area iOS/Android
- [ ] Indicador de rede: lenta / offline / online

**Critério de aceite:** abrir o mapa em Android 360px, clicar em um site, abrir o painel, fechar a sidebar — tudo sem sobreposição e sem precisar de zoom.

### Sprint 2 — Campo sem rede (1 semana)
> Objetivo: o operador consegue trabalhar 30 minutos sem internet e sincronizar depois

- [ ] Cache offline expandido: caixas, DGOs, segmentos, rupturas
- [ ] Timestamp do cache visível ("atualizado há X min")
- [ ] Formulários de caixa/ruptura/segmento: salvar local quando offline, fila de sync
- [ ] Barra de campo: atalhos funcionam offline (formulário abre com dados do cache)
- [ ] Indicador de fila de sync pendente ("3 itens aguardando envio")

**Critério de aceite:** criar uma ruptura sem rede, fechar o browser, reabrir, ver a ruptura ainda lá, reconectar e ver o sync acontecer.

### Sprint 3 — Desenho e auditoria no celular (1 semana)
> Objetivo: o operador consegue desenhar um segmento e auditar pendências direto do campo

- [ ] Desenho de linha: finalizar por botão fixo (sem duplo toque)
- [ ] Barra de desenho: posição fixa que não some com teclado virtual
- [ ] Auditoria IA: modal responsivo, scroll nativo, ação "corrigir" sempre visível
- [ ] Toque longo em cabo/segmento com área expandida
- [ ] GPS: centralizar mapa + marcador de posição confiável
- [ ] Perfil ativo: badge no botão de perfis rápidos

**Critério de aceite:** desenhar um segmento no celular do início ao fim sem precisar de desktop. Abrir auditoria, ver achados, clicar em "corrigir" — tudo sem scroll horizontal.

---

## 6. GANHOS ESPERADOS POR SPRINT

| Sprint | Ganho real |
|--------|-----------|
| Sprint 1 | Operador para de reclamar que "o mapa não funciona no celular". Área útil do mapa aumenta ~40%. Sidebar para de sobrepor o mapa. |
| Sprint 2 | Operador consegue trabalhar em campo sem depender de 4G. Dados não se perdem mais quando a rede cai. Confiança no sistema aumenta. |
| Sprint 3 | Operador consegue fazer cadastro completo de campo sem desktop. Auditoria vira ferramenta real de campo, não só painel bonito. |

---

## 7. RISCOS SE NÃO CORRIGIRMOS AGORA

| Risco | Consequência |
|-------|-------------|
| Sidebar sobrepondo mapa | Operador abandona o celular e volta para papel/WhatsApp |
| Formulários quebrando sem rede | Dados de campo se perdem — operador perde confiança no sistema |
| Cache sem caixas/DGOs | Em campo, o operador não vê os ativos que mais precisa — usa o GeoSite no lugar |
| Auditoria cortada no mobile | A feature mais diferenciada do sistema fica inacessível em campo |
| Modo campo sumindo ao reabrir | Operador precisa reconfigurar toda vez — abandona o modo campo |
| Desenho dependendo de duplo toque | Segmentos não são cadastrados em campo — backlog de cadastro cresce |

---

## 8. PRÓXIMA AÇÃO OBJETIVA PARA CODEX

**Sprint 1 — fazer primeiro:**

1. Converter sidebar em drawer mobile: adicionar classe `drawer-mobile` quando `window.innerWidth < 768`, overlay `div` com `opacity:0.5` atrás, evento `touchstart` no overlay para fechar, `transform: translateX(-100%)` quando fechado.

2. Barra de campo: garantir `min-height: 48px` e `min-width: 48px` em todos os botões, adicionar `<span class="field-label">` visível abaixo do ícone (não só tooltip).

3. Modo Campo: ao ativar, salvar `localStorage.setItem('modoCampo', '1')` e ao carregar a página verificar e reaplicar. Adicionar badge `●` no botão quando ativo.

4. Toque longo: reduzir `touchstart` timeout de 500ms para 300ms em todos os marcadores.

---

## 9. O QUE GEMINI DEVE VALIDAR

1. **Teste real em mobile**: abrir `https://lidiomar90.github.io/rede-optica/mapa-rede-optica.html` em viewport 360×800 (ou DevTools mobile) e executar o Piloto 1 completo. Registrar cada ponto onde a interface quebra, sobrepõe ou fica inacessível.

2. **Checklist GeoSite gap — seções 8 e 9**: executar especificamente as seções de Usabilidade e Mobile/Campo do `CHECKLIST_GEOSITE_GAP.md` e classificar cada item como `abaixo do GeoSite`, `equivalente` ou `melhor`.

3. **Auditoria no mobile**: verificar se o painel de Auditoria IA abre corretamente em viewport mobile, se o scroll funciona, se o botão "corrigir" está acessível sem scroll horizontal.

4. **Modo offline simulado**: desligar a rede no DevTools e tentar criar uma caixa e uma ruptura. Registrar o que acontece — erro, trava ou salva local.
