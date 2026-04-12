# CableDiagramComponent

Componente para renderização de diagramas visuais de cabos ópticos seguindo o padrão ABNT.

## Visão Geral

O `CableDiagramComponent` é responsável por renderizar diagramas interativos de cabos ópticos, mostrando tubos loose e fibras individuais com suas respectivas cores ABNT, status operacionais e informações técnicas.

## Requisitos Atendidos

- **12.1**: Renderização de diagrama com cores ABNT (12 cores padrão)
- **12.2**: Agrupamento de dados por tubo loose
- **12.3**: Visualização de status de fibras (livre, ativa, reserva, danificada, em_teste)
- **12.4**: Interação via click em fibra
- **12.5**: Expandir/colapsar tubos
- **12.6**: Exibição de detalhes da fibra
- **12.10**: Seguir convenção de cores ABNT

## Cores ABNT

O componente implementa as 12 cores padrão ABNT para tubos e fibras:

1. Azul (#0066CC)
2. Laranja (#FF6600)
3. Verde (#00AA00)
4. Marrom (#8B4513)
5. Cinza (#808080)
6. Branco (#FFFFFF)
7. Vermelho (#CC0000)
8. Preto (#000000)
9. Amarelo (#FFCC00)
10. Violeta (#8B00FF)
11. Rosa (#FF69B4)
12. Água (#00CCCC)

## Status de Fibras

O componente suporta 5 status operacionais:

- **Livre** (○): Fibra disponível para uso - Verde (#45d08c)
- **Ativa** (●): Fibra em uso - Azul (#48a8ff)
- **Reserva** (◐): Fibra reservada - Laranja (#ffb648)
- **Danificada** (✕): Fibra com problema - Vermelho (#ff5a68)
- **Em Teste** (◎): Fibra em teste - Roxo (#8d6bff)

## Uso

### Inicialização

```javascript
const diagramComponent = new CableDiagramComponent();
```

### Renderização

```javascript
// Dados do cabo da view vw_diagrama_cabo_completo
const cableData = [
  {
    cabo_id: 'uuid-cabo',
    cabo_nome: 'CABO-001',
    cabo_capacidade: 144,
    cabo_tipo: 'backbone',
    cabo_status: 'ativo',
    tubo_id: 'uuid-tubo-1',
    numero_tubo: 1,
    tubo_cor: 'azul',
    tubo_status: 'ativo',
    fibra_id: 'uuid-fibra-1',
    numero_fibra: 1,
    fibra_cor: 'azul',
    fibra_status: 'ativa',
    fibra_tipo_uso: 'backbone',
    perda_total_db: 0.5,
    comprimento_metros: 1500
  },
  // ... mais linhas
];

diagramComponent.render(cableData);
```

### Limpeza

```javascript
diagramComponent.clear();
```

## Estrutura de Dados

### Entrada (cableData)

Array de objetos com a seguinte estrutura (da view `vw_diagrama_cabo_completo`):

```javascript
{
  // Dados do cabo
  cabo_id: string,           // UUID do cabo
  cabo_nome: string,         // Nome do cabo
  cabo_capacidade: number,   // Capacidade total de fibras
  cabo_tipo: string,         // Tipo do cabo (backbone, distribuicao, etc)
  cabo_status: string,       // Status do cabo (ativo, inativo, etc)
  
  // Dados do tubo
  tubo_id: string,           // UUID do tubo
  numero_tubo: number,       // Número do tubo (1-12)
  tubo_cor: string,          // Cor ABNT do tubo
  tubo_status: string,       // Status do tubo
  
  // Dados da fibra
  fibra_id: string,          // UUID da fibra
  numero_fibra: number,      // Número da fibra (1-12)
  fibra_cor: string,         // Cor ABNT da fibra
  fibra_status: string,      // Status da fibra
  fibra_tipo_uso: string,    // Tipo de uso da fibra
  perda_total_db: number,    // Perda total em dB
  comprimento_metros: number // Comprimento em metros
}
```

## Eventos

### fiber-selected

Disparado quando uma fibra é clicada.

```javascript
document.addEventListener('fiber-selected', (e) => {
  console.log('Fibra selecionada:', e.detail.fiberId);
});
```

**Detalhe do evento:**
```javascript
{
  fiberId: string  // UUID da fibra selecionada
}
```

## Interações

### Click em Fibra

- Remove seleção anterior
- Adiciona classe `selected` à fibra clicada
- Dispara evento `fiber-selected`
- Integra com FiberRouteTracer para traçar rota

### Click em Header do Tubo

- Expande/colapsa o tubo
- Adiciona/remove classe `collapsed`
- Atualiza ícone de toggle (▼/▲)

## Estrutura HTML Gerada

```html
<div class="diagram-wrapper">
  <!-- Header com informações do cabo -->
  <div class="diagram-header">
    <div class="diagram-title">
      <h2>Nome do Cabo</h2>
      <button class="close-btn">×</button>
    </div>
    <div class="diagram-meta">
      <!-- Metadados do cabo -->
    </div>
  </div>
  
  <!-- Estatísticas de fibras -->
  <div class="diagram-stats">
    <div class="stat-card stat-livre">...</div>
    <div class="stat-card stat-ativa">...</div>
    <!-- ... -->
  </div>
  
  <!-- Legenda -->
  <div class="diagram-legend">...</div>
  
  <!-- Container de tubos -->
  <div class="tubes-container">
    <div class="tube" data-tube-id="uuid">
      <div class="tube-header">...</div>
      <div class="fibers-grid">
        <div class="fiber" data-fiber-id="uuid">
          <div class="fiber-circle">
            <span class="fiber-number">1</span>
          </div>
          <span class="fiber-status-icon">●</span>
          <span class="fiber-color-label">azul</span>
        </div>
        <!-- ... mais fibras -->
      </div>
    </div>
    <!-- ... mais tubos -->
  </div>
</div>
```

## Estilos CSS

Os estilos estão em `CableDiagramComponent.css` e incluem:

- Layout responsivo (mobile-first)
- Cores ABNT para tubos e fibras
- Indicadores visuais de status
- Animações de entrada
- Estados hover e selected
- Suporte para modo campo (botões grandes)

### Classes CSS Principais

- `.diagram-wrapper`: Container principal
- `.tube`: Tubo loose
- `.tube.collapsed`: Tubo colapsado
- `.fiber`: Fibra individual
- `.fiber.selected`: Fibra selecionada
- `.fiber-circle`: Círculo colorido da fibra
- `.stat-card`: Card de estatística

## Responsividade

O componente é totalmente responsivo com breakpoints em:

- **Desktop**: > 768px - Grid completo
- **Tablet**: 480px - 768px - Grid adaptado
- **Mobile**: < 480px - Grid compacto, 2 colunas de stats

## Integração com DiagramaManager

O componente é gerenciado pelo `DiagramaManager`:

```javascript
// DiagramaManager inicializa o componente
this.components.diagram = new CableDiagramComponent();

// DiagramaManager chama render quando necessário
this.components.diagram.render(cableData);
```

## Dependências

- **Nenhuma dependência externa** - Vanilla JavaScript puro
- Integra com `DiagramaManager` para orquestração
- Dispara eventos para `FiberRouteTracer`

## Arquivos

- `js/CableDiagramComponent.js` - Código JavaScript
- `js/CableDiagramComponent.css` - Estilos CSS
- `js/README_CableDiagramComponent.md` - Esta documentação

## Exemplo Completo

```javascript
// 1. Criar instância
const diagram = new CableDiagramComponent();

// 2. Buscar dados do cabo
const cableData = await fetch(
  `${SUPABASE_URL}/rest/v1/vw_diagrama_cabo_completo?cabo_id=eq.${cableId}`,
  {
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`
    }
  }
).then(r => r.json());

// 3. Renderizar diagrama
diagram.render(cableData);

// 4. Escutar eventos
document.addEventListener('fiber-selected', (e) => {
  console.log('Fibra selecionada:', e.detail.fiberId);
  // Traçar rota, mostrar detalhes, etc.
});
```

## Testes

Para testar o componente:

1. Abra `diagrama-fibra.html` no navegador
2. Clique em "Inicializar Sistema"
3. Clique em "Abrir Diagrama (Teste)"
4. Verifique a renderização do diagrama
5. Clique em fibras para testar seleção
6. Clique em headers de tubos para expandir/colapsar

## Próximos Passos

- [ ] Implementar FiberRouteTracer (Task 3.1)
- [ ] Implementar testes unitários (Task 2.4)
- [ ] Integrar com mapa-rede-optica.html
- [ ] Adicionar suporte para edição inline
- [ ] Implementar drag-and-drop para reorganização

## Referências

- Especificação: `.kiro/specs/diagrama/design.md`
- Requisitos: `.kiro/specs/diagrama/requirements.md`
- Tasks: `.kiro/specs/diagrama/tasks.md`
- Padrão ABNT: NBR 14565 (Cabeamento de telecomunicações para edifícios comerciais)
