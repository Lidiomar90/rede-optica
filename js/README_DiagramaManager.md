# DiagramaManager - Documentação

## Visão Geral

O `DiagramaManager` é o orquestrador principal do Sistema de Diagrama de Fibras Ópticas. Ele gerencia o estado global da aplicação, coordena os componentes, detecta modo offline/online e integra com o mapa Leaflet existente.

## Responsabilidades

- **Gerenciamento de Estado Global**: Mantém o estado centralizado da aplicação
- **Detecção Offline/Online**: Monitora a conectividade e ajusta o comportamento
- **Coordenação de Componentes**: Orquestra CableDiagramComponent, FiberRouteTracer, OfflineSyncManager, etc.
- **Event Listeners**: Integra com o mapa e outros componentes via eventos customizados
- **Integração com Supabase**: Gerencia chamadas à API REST do Supabase

## Instalação

### 1. Incluir o script no HTML

```html
<script src="js/DiagramaManager.js"></script>
```

### 2. Inicializar o DiagramaManager

```javascript
// Criar instância
const diagramaManager = new DiagramaManager();

// Configuração do Supabase
const config = {
  supabaseUrl: 'https://xmqxhzmjxprhvyqwlqvz.supabase.co',
  supabaseKey: 'sua-chave-aqui'
};

// Inicializar
await diagramaManager.init(config);
```

## API Pública

### Métodos Principais

#### `init(config)`
Inicializa o DiagramaManager e todos os componentes.

```javascript
await diagramaManager.init({
  supabaseUrl: 'https://...',
  supabaseKey: '...'
});
```

**Parâmetros:**
- `config.supabaseUrl` (string): URL do projeto Supabase
- `config.supabaseKey` (string): Chave anon do Supabase

**Retorna:** Promise<void>

---

#### `openCableDiagram(cableId)`
Abre o diagrama de um cabo específico.

```javascript
await diagramaManager.openCableDiagram('uuid-do-cabo');
```

**Parâmetros:**
- `cableId` (string): UUID do cabo

**Retorna:** Promise<void>

---

#### `traceFiberRoute(fiberId)`
Traça a rota completa de uma fibra.

```javascript
await diagramaManager.traceFiberRoute('uuid-da-fibra');
```

**Parâmetros:**
- `fiberId` (string): UUID da fibra

**Retorna:** Promise<void>

---

#### `toggleFieldMode(enabled)`
Ativa/desativa o modo campo.

```javascript
diagramaManager.toggleFieldMode(true); // Ativar
diagramaManager.toggleFieldMode(false); // Desativar
```

**Parâmetros:**
- `enabled` (boolean): Se o modo campo deve ser ativado

---

#### `getState()`
Retorna o estado atual do manager.

```javascript
const state = diagramaManager.getState();
console.log(state);
// {
//   currentCable: 'uuid-do-cabo',
//   currentFiber: 'uuid-da-fibra',
//   selectedRoute: {...},
//   fieldMode: false,
//   offlineMode: false,
//   syncQueue: [],
//   isInitialized: true
// }
```

**Retorna:** Object

---

#### `isInitialized()`
Verifica se o manager está inicializado.

```javascript
if (diagramaManager.isInitialized()) {
  console.log('Sistema pronto!');
}
```

**Retorna:** boolean

---

#### `isOffline()`
Verifica se está em modo offline.

```javascript
if (diagramaManager.isOffline()) {
  console.log('Sem conexão - usando cache local');
}
```

**Retorna:** boolean

---

#### `getComponent(componentName)`
Retorna um componente específico.

```javascript
const tracer = diagramaManager.getComponent('tracer');
if (tracer) {
  // Usar o FiberRouteTracer diretamente
}
```

**Parâmetros:**
- `componentName` (string): Nome do componente ('diagram', 'tracer', 'sync', 'parser', 'field', 'analyzer')

**Retorna:** Object | null

## Eventos Customizados

O DiagramaManager dispara e escuta vários eventos customizados para integração com outros componentes.

### Eventos Disparados

#### `diagrama-initialized`
Disparado quando o sistema é inicializado com sucesso.

```javascript
document.addEventListener('diagrama-initialized', (e) => {
  console.log('Sistema inicializado:', e.detail.manager);
});
```

---

#### `network-online`
Disparado quando a conexão é restaurada.

```javascript
document.addEventListener('network-online', () => {
  console.log('Conexão restaurada');
});
```

---

#### `network-offline`
Disparado quando a conexão é perdida.

```javascript
document.addEventListener('network-offline', () => {
  console.log('Modo offline ativado');
});
```

---

#### `diagram-opened`
Disparado quando um diagrama de cabo é aberto.

```javascript
document.addEventListener('diagram-opened', (e) => {
  console.log('Diagrama aberto:', e.detail.cableId);
  console.log('Dados:', e.detail.cableData);
});
```

---

#### `route-traced`
Disparado quando uma rota de fibra é traçada.

```javascript
document.addEventListener('route-traced', (e) => {
  console.log('Rota traçada:', e.detail.fiberId);
  console.log('Rota:', e.detail.route);
});
```

---

#### `field-mode-changed`
Disparado quando o modo campo é ativado/desativado.

```javascript
document.addEventListener('field-mode-changed', (e) => {
  console.log('Modo campo:', e.detail.enabled);
});
```

---

#### `error`
Disparado quando ocorre um erro.

```javascript
document.addEventListener('error', (e) => {
  console.error('Erro:', e.detail.message);
});
```

---

#### `success`
Disparado quando uma operação é bem-sucedida.

```javascript
document.addEventListener('success', (e) => {
  console.log('Sucesso:', e.detail.message);
});
```

### Eventos Escutados

#### `cable-selected`
Escuta quando um cabo é selecionado (ex: no mapa).

```javascript
// Disparar evento para abrir diagrama
document.dispatchEvent(new CustomEvent('cable-selected', {
  detail: { cableId: 'uuid-do-cabo' }
}));
```

---

#### `fiber-selected`
Escuta quando uma fibra é selecionada (ex: no diagrama).

```javascript
// Disparar evento para traçar rota
document.dispatchEvent(new CustomEvent('fiber-selected', {
  detail: { fiberId: 'uuid-da-fibra' }
}));
```

---

#### `field-mode-toggle`
Escuta quando o modo campo deve ser alternado.

```javascript
// Disparar evento para ativar modo campo
document.dispatchEvent(new CustomEvent('field-mode-toggle', {
  detail: { enabled: true }
}));
```

---

#### `sync-completed`
Escuta quando a sincronização é completada.

```javascript
document.dispatchEvent(new CustomEvent('sync-completed', {
  detail: { count: 5, success: true }
}));
```

---

#### `sync-error`
Escuta quando ocorre erro na sincronização.

```javascript
document.dispatchEvent(new CustomEvent('sync-error', {
  detail: { message: 'Erro ao sincronizar' }
}));
```

## Integração com Mapa Leaflet

O DiagramaManager integra automaticamente com o mapa Leaflet existente para destacar rotas de fibras.

### Requisitos

- Variável global `window.map` deve conter a instância do Leaflet
- Biblioteca Leaflet deve estar carregada

### Exemplo de Integração

```javascript
// No mapa-rede-optica.html
const map = L.map('map').setView([-19.9167, -43.9345], 13);
window.map = map; // Expor globalmente

// Adicionar listener para click em cabo
map.on('click', (e) => {
  const cableId = e.layer.feature.properties.id;
  
  // Disparar evento para abrir diagrama
  document.dispatchEvent(new CustomEvent('cable-selected', {
    detail: { cableId }
  }));
});
```

## Modo Offline

O DiagramaManager detecta automaticamente quando a conexão é perdida e ativa o modo offline.

### Comportamento

- **Online**: Busca dados da API do Supabase e atualiza cache local
- **Offline**: Usa dados do cache local (IndexedDB)
- **Sincronização**: Quando a conexão é restaurada, sincroniza operações pendentes automaticamente

### Indicador Visual

O DiagramaManager atualiza automaticamente o elemento `#net-indicator`:

```html
<div id="net-indicator">Online</div>
```

Classes CSS aplicadas:
- `.online`: Conexão ativa
- `.offline`: Sem conexão

## Componentes Integrados

O DiagramaManager coordena os seguintes componentes:

### CableDiagramComponent
Renderiza diagramas visuais de cabos com tubos e fibras (padrão ABNT).

### FiberRouteTracer
Traça rotas completas de fibras de ponta a ponta.

### OfflineSyncManager
Gerencia cache local (IndexedDB) e sincronização offline.

### SORParser
Parser de arquivos OTDR (.SOR) com extração de eventos.

### FieldModeUI
Interface simplificada para uso em campo por técnicos.

### IntelligentAnalyzer
Detecta inconsistências e sugere correções automaticamente.

## Exemplo Completo

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Diagrama de Fibras</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css">
</head>
<body>
  <div id="net-indicator">Inicializando...</div>
  <div id="map" style="height: 100vh;"></div>
  <div id="diagram-modal" style="display: none;"></div>
  <div id="route-panel" style="display: none;"></div>
  
  <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js"></script>
  <script src="js/DiagramaManager.js"></script>
  
  <script>
    // Inicializar mapa
    const map = L.map('map').setView([-19.9167, -43.9345], 13);
    window.map = map;
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
    
    // Inicializar DiagramaManager
    const diagramaManager = new DiagramaManager();
    
    diagramaManager.init({
      supabaseUrl: 'https://xmqxhzmjxprhvyqwlqvz.supabase.co',
      supabaseKey: 'sua-chave-aqui'
    }).then(() => {
      console.log('Sistema pronto!');
    });
    
    // Configurar listeners
    document.addEventListener('diagrama-initialized', () => {
      console.log('DiagramaManager inicializado');
    });
    
    document.addEventListener('network-offline', () => {
      alert('Modo offline ativado - alterações serão sincronizadas quando voltar online');
    });
  </script>
</body>
</html>
```

## Requisitos Atendidos

Este componente atende aos seguintes requisitos da especificação:

- **Requisito 14.3**: Integração com Leaflet.js para renderização de mapas
- **Requisito 14.4**: Compatibilidade com mapa-rede-optica.html existente
- **Requisito 14.5**: Compatibilidade com dashboard.html existente

## Próximos Passos

1. Implementar componentes restantes (CableDiagramComponent, FiberRouteTracer, etc.)
2. Criar testes unitários e de integração
3. Adicionar suporte a PWA para modo offline robusto
4. Implementar sistema de notificações toast
5. Adicionar telemetria e logging

## Suporte

Para dúvidas ou problemas, consulte:
- Documento de Design: `.kiro/specs/diagrama/design.md`
- Documento de Requisitos: `.kiro/specs/diagrama/requirements.md`
- Tasks: `.kiro/specs/diagrama/tasks.md`
