# FiberRouteTracer

Componente responsável por traçar rotas completas de fibras ópticas de ponta a ponta, desde a OLT até o cliente final.

## Responsabilidades

- Chamar RPC `tracer_rota_fibra` do Supabase
- Processar rotas retornadas pelo backend
- Calcular perda total acumulada ao longo da rota
- Renderizar painel de rota com informações detalhadas
- Integrar com mapa Leaflet para destaque visual de rotas

## Requisitos Atendidos

- **2.1**: Exibir rota completa de fibra individual
- **2.2**: Exibir todas as perdas ópticas ao longo da rota
- **2.7**: Permitir navegação entre elementos conectados
- **2.8**: Calcular perda total acumulada na rota
- **11.5**: Destacar rota selecionada no mapa

## Uso

### Inicialização

```javascript
const tracer = new FiberRouteTracer({
  supabaseUrl: 'https://xmqxhzmjxprhvyqwlqvz.supabase.co',
  supabaseKey: 'YOUR_SUPABASE_KEY'
});
```

### Traçar Rota

```javascript
const fiberId = 'uuid-da-fibra';
const route = await tracer.trace(fiberId);

console.log('Perda total:', route.totalLoss, 'dB');
console.log('Comprimento:', route.totalLength, 'm');
console.log('Conexões:', route.connections);
console.log('Segmentos:', route.segments.length);
```

### Renderizar Painel

```javascript
const html = tracer.renderRoutePanel(route);
document.getElementById('route-panel').innerHTML = html;
document.getElementById('route-panel').style.display = 'block';
```

## Estrutura de Dados

### Entrada (trace)

```javascript
fiberId: string // UUID da fibra
```

### Saída (route)

```javascript
{
  fiberId: string,           // UUID da fibra
  segments: Array,           // Segmentos da rota
  totalLoss: number,         // Perda total em dB
  totalLength: number,       // Comprimento total em metros
  connections: number,       // Número de conexões
  startPoint: {              // Ponto inicial
    cable: string,
    tube: number,
    tubeColor: string,
    fiber: number,
    fiberColor: string
  },
  endPoint: {                // Ponto final
    cable: string,
    tube: number,
    tubeColor: string,
    fiber: number,
    fiberColor: string
  }
}
```

### Segmento (segment)

```javascript
{
  nivel: number,                    // Nível na hierarquia
  fibra_id: string,                 // UUID da fibra
  fibra_numero: number,             // Número da fibra (1-12)
  fibra_cor: string,                // Cor ABNT da fibra
  tubo_numero: number,              // Número do tubo (1-12)
  tubo_cor: string,                 // Cor ABNT do tubo
  cabo_nome: string,                // Nome do cabo
  conexao_tipo: string,             // Tipo de conexão (fusao, conector_sc, etc)
  perda_conexao_db: number,         // Perda da conexão em dB
  perda_acumulada_db: number,       // Perda acumulada até este ponto
  local_conexao_nome: string,       // Nome do local da conexão
  local_conexao_geom: object,       // Geometria do local (GeoJSON)
  comprimento_metros: number        // Comprimento do segmento
}
```

## Integração com Mapa

O FiberRouteTracer é integrado com o mapa Leaflet através do DiagramaManager:

```javascript
// DiagramaManager chama o tracer
const route = await this.components.tracer.trace(fiberId);

// DiagramaManager destaca a rota no mapa
this.highlightRouteOnMap(route);
```

O destaque visual é feito através da classe CSS `.trace-line` que aplica:
- Cor azul (#48a8ff)
- Largura de 4px
- Opacidade de 0.8
- Animação de pulso

## Métodos Públicos

### trace(fiberId)

Traça a rota completa de uma fibra.

**Parâmetros:**
- `fiberId` (string): UUID da fibra

**Retorna:**
- Promise<Object>: Rota processada

**Throws:**
- Error: Se fiberId não for fornecido
- Error: Se configuração do Supabase estiver ausente
- Error: Se a chamada ao RPC falhar

### renderRoutePanel(route)

Renderiza o painel de rota em HTML.

**Parâmetros:**
- `route` (Object): Rota processada

**Retorna:**
- string: HTML do painel

### getCurrentRoute()

Retorna a rota atualmente traçada.

**Retorna:**
- Object|null: Rota atual ou null

### clearRoute()

Limpa a rota atual.

## Métodos Privados

### processRoute(rawRoute, fiberId)

Processa dados brutos do RPC.

### calculateTotalLength(route)

Calcula comprimento total da rota.

### getStartPoint(route)

Obtém informações do ponto inicial.

### getEndPoint(route)

Obtém informações do ponto final.

### renderRoutePath(segments)

Renderiza HTML dos segmentos.

### formatLength(meters)

Formata comprimento para exibição (m ou km).

### formatConnectionType(type)

Formata tipo de conexão para exibição.

### getColorHex(colorName)

Obtém código hexadecimal de cor ABNT.

## Cores ABNT Suportadas

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
12. Água/Ciano (#00CCCC)

## Tipos de Conexão

- `fusao`: Fusão
- `conector_sc`: Conector SC
- `conector_lc`: Conector LC
- `conector_fc`: Conector FC
- `acoplador`: Acoplador

## Estilos CSS

Os estilos estão definidos em `FiberRouteTracer.css` e incluem:

- Layout do painel lateral
- Métricas de rota (grid 2x2)
- Pontos de origem/destino
- Segmentos com marcadores numerados
- Conexões destacadas
- Badges de cores ABNT
- Animação de pulso para rota no mapa
- Responsividade mobile
- Modo campo (botões maiores)

## Eventos

O FiberRouteTracer não dispara eventos diretamente. A integração com eventos é feita através do DiagramaManager:

```javascript
// Evento disparado quando rota é traçada
document.dispatchEvent(new CustomEvent('route-traced', {
  detail: { fiberId, route }
}));
```

## Tratamento de Erros

O componente trata os seguintes erros:

1. **fiberId ausente**: Lança erro com mensagem clara
2. **Configuração ausente**: Lança erro se supabaseUrl ou supabaseKey não estiverem definidos
3. **Falha no RPC**: Captura erro HTTP e inclui status e mensagem
4. **Resposta inválida**: Valida se resposta é array
5. **Rota vazia**: Retorna objeto com valores padrão (0 segmentos)

## Exemplo Completo

```javascript
// Inicializar
const tracer = new FiberRouteTracer({
  supabaseUrl: 'https://xmqxhzmjxprhvyqwlqvz.supabase.co',
  supabaseKey: 'YOUR_KEY'
});

// Traçar rota
try {
  const route = await tracer.trace('uuid-da-fibra');
  
  // Exibir informações
  console.log(`Rota de ${route.startPoint.cable} até ${route.endPoint.cable}`);
  console.log(`Perda total: ${route.totalLoss.toFixed(3)} dB`);
  console.log(`Comprimento: ${(route.totalLength / 1000).toFixed(2)} km`);
  console.log(`${route.connections} conexões em ${route.segments.length} segmentos`);
  
  // Renderizar painel
  const panel = document.getElementById('route-panel');
  panel.innerHTML = tracer.renderRoutePanel(route);
  panel.style.display = 'block';
  
  // Destacar no mapa (via DiagramaManager)
  diagramaManager.highlightRouteOnMap(route);
  
} catch (error) {
  console.error('Erro ao traçar rota:', error);
  alert('Não foi possível traçar a rota da fibra');
}
```

## Dependências

- Supabase (backend)
- RPC `tracer_rota_fibra` (PostgreSQL)
- Leaflet.js (para integração com mapa)
- DiagramaManager (orquestração)

## Compatibilidade

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile (Android 8+, iOS 14+)

## Performance

- Tracer de rota: < 3 segundos (Requisito 15.2)
- Renderização de painel: < 500ms
- Suporta rotas com até 50 segmentos (limite do RPC)

## Notas de Implementação

1. O RPC `tracer_rota_fibra` deve estar implementado no Supabase
2. O painel é renderizado em HTML puro (sem frameworks)
3. A integração com o mapa é feita através do DiagramaManager
4. O componente é stateless (não mantém estado interno além da rota atual)
5. Todos os cálculos são feitos no frontend após receber dados do backend
6. O componente valida todas as entradas e saídas
7. Erros são propagados para o chamador (DiagramaManager)

## Próximos Passos

- [ ] Implementar cache de rotas traçadas
- [ ] Adicionar suporte a modo offline
- [ ] Implementar exportação de rota (PDF, CSV)
- [ ] Adicionar gráfico de perda ao longo da rota
- [ ] Implementar comparação entre rotas
- [ ] Adicionar suporte a rotas bidirecionais

## Referências

- Design Document: `.kiro/specs/diagrama/design.md`
- Requirements: `.kiro/specs/diagrama/requirements.md`
- Tasks: `.kiro/specs/diagrama/tasks.md`
- DiagramaManager: `js/README_DiagramaManager.md`
- CableDiagramComponent: `js/README_CableDiagramComponent.md`
