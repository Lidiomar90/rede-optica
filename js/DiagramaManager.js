/**
 * DiagramaManager - Orquestrador principal do sistema de diagramas
 * 
 * Responsabilidades:
 * - Gerenciamento de estado global
 * - Detecção de modo offline/online
 * - Coordenação entre componentes
 * - Event listeners para integração com mapa
 * 
 * Requirements: 14.3, 14.4, 14.5
 */
class DiagramaManager {
  constructor() {
    // Estado global da aplicação
    this.state = {
      currentCable: null,
      currentFiber: null,
      selectedRoute: null,
      fieldMode: false,
      offlineMode: false,
      syncQueue: [],
      isInitialized: false
    };
    
    // Referências aos componentes
    this.components = {
      diagram: null,
      tracer: null,
      sync: null,
      parser: null,
      field: null,
      analyzer: null
    };
    
    // Configuração do Supabase (será injetada externamente)
    this.config = {
      supabaseUrl: null,
      supabaseKey: null
    };
  }
  
  /**
   * Inicializa o DiagramaManager e todos os componentes
   * @param {Object} config - Configuração com supabaseUrl e supabaseKey
   */
  async init(config) {
    try {
      console.log('[DiagramaManager] Inicializando...');
      
      // Validar configuração
      if (!config || !config.supabaseUrl || !config.supabaseKey) {
        throw new Error('Configuração inválida: supabaseUrl e supabaseKey são obrigatórios');
      }
      
      this.config = config;
      
      // Inicializar componentes (quando estiverem disponíveis)
      await this.initializeComponents();
      
      // Detectar modo offline
      this.setupOfflineDetection();
      
      // Carregar cache inicial (se OfflineSyncManager estiver disponível)
      if (this.components.sync) {
        await this.components.sync.loadInitialCache();
      }
      
      // Setup event listeners
      this.setupEventListeners();
      
      this.state.isInitialized = true;
      console.log('[DiagramaManager] Inicializado com sucesso');
      
      // Disparar evento de inicialização
      this.dispatchEvent('diagrama-initialized', { manager: this });
      
    } catch (error) {
      console.error('[DiagramaManager] Erro na inicialização:', error);
      throw error;
    }
  }
  
  /**
   * Inicializa os componentes do sistema
   * Componentes são inicializados apenas se suas classes estiverem disponíveis
   */
  async initializeComponents() {
    console.log('[DiagramaManager] Inicializando componentes...');
    
    // CableDiagramComponent
    if (typeof CableDiagramComponent !== 'undefined') {
      this.components.diagram = new CableDiagramComponent();
      console.log('[DiagramaManager] CableDiagramComponent inicializado');
    }
    
    // FiberRouteTracer
    if (typeof FiberRouteTracer !== 'undefined') {
      this.components.tracer = new FiberRouteTracer(this.config);
      console.log('[DiagramaManager] FiberRouteTracer inicializado');
    }
    
    // OfflineSyncManager
    if (typeof OfflineSyncManager !== 'undefined') {
      this.components.sync = new OfflineSyncManager(this.config);
      await this.components.sync.init();
      console.log('[DiagramaManager] OfflineSyncManager inicializado');
    }
    
    // SORParser
    if (typeof SORParser !== 'undefined') {
      this.components.parser = new SORParser();
      console.log('[DiagramaManager] SORParser inicializado');
    }
    
    // FieldModeUI
    if (typeof FieldModeUI !== 'undefined') {
      this.components.field = new FieldModeUI();
      console.log('[DiagramaManager] FieldModeUI inicializado');
    }
    
    // IntelligentAnalyzer
    if (typeof IntelligentAnalyzer !== 'undefined') {
      this.components.analyzer = new IntelligentAnalyzer(this.config);
      console.log('[DiagramaManager] IntelligentAnalyzer inicializado');
    }
  }
  
  /**
   * Configura detecção de modo offline/online
   */
  setupOfflineDetection() {
    console.log('[DiagramaManager] Configurando detecção offline/online');
    
    // Detectar estado inicial
    this.state.offlineMode = !navigator.onLine;
    this.updateNetworkStatus();
    
    // Listener para quando ficar online
    window.addEventListener('online', () => {
      console.log('[DiagramaManager] Conexão restaurada');
      this.state.offlineMode = false;
      this.updateNetworkStatus();
      
      // Sincronizar operações pendentes
      if (this.components.sync) {
        this.components.sync.syncPendingOperations();
      }
      
      // Disparar evento
      this.dispatchEvent('network-online');
    });
    
    // Listener para quando ficar offline
    window.addEventListener('offline', () => {
      console.log('[DiagramaManager] Conexão perdida - modo offline ativado');
      this.state.offlineMode = true;
      this.updateNetworkStatus();
      
      // Disparar evento
      this.dispatchEvent('network-offline');
    });
  }
  
  /**
   * Atualiza indicador visual de status de rede
   */
  updateNetworkStatus() {
    const indicator = document.getElementById('net-indicator');
    if (!indicator) return;
    
    if (this.state.offlineMode) {
      indicator.className = 'offline';
      indicator.textContent = 'Modo Offline';
      indicator.title = 'Sem conexão - alterações serão sincronizadas quando voltar online';
    } else {
      indicator.className = 'online';
      indicator.textContent = 'Online';
      indicator.title = 'Conectado ao servidor';
      
      // Remover flash após 3 segundos
      setTimeout(() => {
        indicator.classList.remove('online-flash');
      }, 3000);
    }
  }
  
  /**
   * Configura event listeners para integração com outros componentes
   */
  setupEventListeners() {
    console.log('[DiagramaManager] Configurando event listeners');
    
    // Evento: cabo selecionado no mapa
    document.addEventListener('cable-selected', (e) => {
      console.log('[DiagramaManager] Cabo selecionado:', e.detail.cableId);
      this.openCableDiagram(e.detail.cableId);
    });
    
    // Evento: fibra selecionada no diagrama
    document.addEventListener('fiber-selected', (e) => {
      console.log('[DiagramaManager] Fibra selecionada:', e.detail.fiberId);
      this.traceFiberRoute(e.detail.fiberId);
    });
    
    // Evento: modo campo ativado/desativado
    document.addEventListener('field-mode-toggle', (e) => {
      console.log('[DiagramaManager] Modo campo:', e.detail.enabled);
      this.toggleFieldMode(e.detail.enabled);
    });
    
    // Evento: sincronização completada
    document.addEventListener('sync-completed', (e) => {
      console.log('[DiagramaManager] Sincronização completada:', e.detail);
      this.updateSyncBadge();
    });
    
    // Evento: erro de sincronização
    document.addEventListener('sync-error', (e) => {
      console.error('[DiagramaManager] Erro de sincronização:', e.detail);
      this.showError('Erro ao sincronizar dados: ' + e.detail.message);
    });
  }
  
  /**
   * Abre o diagrama de um cabo
   * @param {string} cableId - UUID do cabo
   */
  async openCableDiagram(cableId) {
    try {
      console.log('[DiagramaManager] Abrindo diagrama do cabo:', cableId);
      
      if (!this.components.diagram) {
        throw new Error('CableDiagramComponent não está disponível');
      }
      
      this.state.currentCable = cableId;
      
      // Buscar dados do cabo (online ou cache)
      const cableData = await this.fetchCableData(cableId);
      
      if (!cableData || cableData.length === 0) {
        throw new Error('Nenhum dado encontrado para este cabo');
      }
      
      // Renderizar diagrama
      this.components.diagram.render(cableData);
      
      // Mostrar modal
      this.showDiagramModal();
      
      // Disparar evento
      this.dispatchEvent('diagram-opened', { cableId, cableData });
      
    } catch (error) {
      console.error('[DiagramaManager] Erro ao abrir diagrama:', error);
      this.showError('Não foi possível carregar o diagrama do cabo: ' + error.message);
    }
  }
  
  /**
   * Busca dados de um cabo (online ou cache)
   * @param {string} cableId - UUID do cabo
   * @returns {Promise<Array>} Dados do cabo
   */
  async fetchCableData(cableId) {
    if (this.state.offlineMode) {
      console.log('[DiagramaManager] Buscando cabo do cache:', cableId);
      
      if (!this.components.sync) {
        throw new Error('OfflineSyncManager não está disponível');
      }
      
      return await this.components.sync.getCableFromCache(cableId);
    } else {
      console.log('[DiagramaManager] Buscando cabo da API:', cableId);
      
      const data = await this.fetchFromAPI(cableId);
      
      // Atualizar cache se disponível
      if (this.components.sync) {
        await this.components.sync.updateCache('cables', cableId, data);
      }
      
      return data;
    }
  }
  
  /**
   * Busca dados de um cabo da API do Supabase
   * @param {string} cableId - UUID do cabo
   * @returns {Promise<Array>} Dados do cabo
   */
  async fetchFromAPI(cableId) {
    const url = `${this.config.supabaseUrl}/rest/v1/vw_diagrama_cabo_completo?cabo_id=eq.${cableId}`;
    
    const response = await fetch(url, {
      headers: {
        'apikey': this.config.supabaseKey,
        'Authorization': `Bearer ${this.config.supabaseKey}`
      }
    });
    
    if (!response.ok) {
      throw new Error(`Falha ao buscar dados do cabo: ${response.status} ${response.statusText}`);
    }
    
    return await response.json();
  }
  
  /**
   * Traça a rota completa de uma fibra
   * @param {string} fiberId - UUID da fibra
   */
  async traceFiberRoute(fiberId) {
    try {
      console.log('[DiagramaManager] Traçando rota da fibra:', fiberId);
      
      if (!this.components.tracer) {
        throw new Error('FiberRouteTracer não está disponível');
      }
      
      this.state.currentFiber = fiberId;
      
      // Traçar rota
      const route = await this.components.tracer.trace(fiberId);
      
      this.state.selectedRoute = route;
      
      // Destacar rota no mapa
      this.highlightRouteOnMap(route);
      
      // Mostrar painel de rota
      this.showRoutePanel(route);
      
      // Disparar evento
      this.dispatchEvent('route-traced', { fiberId, route });
      
    } catch (error) {
      console.error('[DiagramaManager] Erro ao traçar rota:', error);
      this.showError('Não foi possível traçar a rota da fibra: ' + error.message);
    }
  }
  
  /**
   * Destaca a rota no mapa Leaflet
   * @param {Object} route - Dados da rota
   */
  highlightRouteOnMap(route) {
    console.log('[DiagramaManager] Destacando rota no mapa');
    
    // Integração com mapa existente (Leaflet)
    if (typeof window.map === 'undefined' || !window.map) {
      console.warn('[DiagramaManager] Mapa Leaflet não encontrado');
      return;
    }
    
    if (!route.segments || route.segments.length === 0) {
      console.warn('[DiagramaManager] Rota sem segmentos');
      return;
    }
    
    // Remover rotas anteriores
    if (window.traceLayer) {
      window.map.removeLayer(window.traceLayer);
    }
    
    // Criar nova camada para a rota
    window.traceLayer = L.layerGroup();
    
    route.segments.forEach((segment, index) => {
      if (segment.local_conexao_geom) {
        try {
          const geojson = typeof segment.local_conexao_geom === 'string' 
            ? JSON.parse(segment.local_conexao_geom) 
            : segment.local_conexao_geom;
          
          L.geoJSON(geojson, {
            style: {
              color: '#48a8ff',
              weight: 4,
              opacity: 0.8,
              className: 'trace-line'
            },
            onEachFeature: (feature, layer) => {
              layer.bindPopup(`
                <strong>Segmento ${index + 1}</strong><br>
                ${segment.cabo_nome}<br>
                Tubo ${segment.tubo_numero} - Fibra ${segment.fibra_numero}
              `);
            }
          }).addTo(window.traceLayer);
        } catch (error) {
          console.error('[DiagramaManager] Erro ao processar geometria:', error);
        }
      }
    });
    
    window.traceLayer.addTo(window.map);
    
    // Ajustar zoom para mostrar toda a rota
    if (window.traceLayer.getBounds && window.traceLayer.getBounds().isValid()) {
      window.map.fitBounds(window.traceLayer.getBounds(), { padding: [50, 50] });
    }
  }
  
  /**
   * Mostra o painel de rota
   * @param {Object} route - Dados da rota
   */
  showRoutePanel(route) {
    const panel = document.getElementById('route-panel');
    if (!panel) {
      console.warn('[DiagramaManager] Painel de rota não encontrado');
      return;
    }
    
    if (this.components.tracer && this.components.tracer.renderRoutePanel) {
      panel.innerHTML = this.components.tracer.renderRoutePanel(route);
    } else {
      // Renderização básica se o tracer não estiver disponível
      panel.innerHTML = `
        <div class="route-panel">
          <div class="route-header">
            <h3>Rota da Fibra</h3>
            <button class="close-btn" onclick="document.getElementById('route-panel').style.display='none'">×</button>
          </div>
          <div class="route-summary">
            <p>Perda Total: ${route.totalLoss ? route.totalLoss.toFixed(3) : 'N/A'} dB</p>
            <p>Segmentos: ${route.segments ? route.segments.length : 0}</p>
          </div>
        </div>
      `;
    }
    
    panel.style.display = 'block';
  }
  
  /**
   * Mostra o modal de diagrama
   */
  showDiagramModal() {
    const modal = document.getElementById('diagram-modal');
    if (!modal) {
      console.warn('[DiagramaManager] Modal de diagrama não encontrado');
      return;
    }
    
    modal.style.display = 'block';
    modal.classList.add('show');
    
    // Adicionar listener para fechar ao clicar fora
    setTimeout(() => {
      const closeOnOutsideClick = (e) => {
        if (e.target === modal) {
          this.closeDiagramModal();
          modal.removeEventListener('click', closeOnOutsideClick);
        }
      };
      modal.addEventListener('click', closeOnOutsideClick);
    }, 100);
  }
  
  /**
   * Fecha o modal de diagrama
   */
  closeDiagramModal() {
    const modal = document.getElementById('diagram-modal');
    if (!modal) return;
    
    modal.classList.remove('show');
    setTimeout(() => {
      modal.style.display = 'none';
    }, 300);
    
    this.state.currentCable = null;
  }
  
  /**
   * Ativa/desativa modo campo
   * @param {boolean} enabled - Se o modo campo deve ser ativado
   */
  toggleFieldMode(enabled) {
    console.log('[DiagramaManager] Modo campo:', enabled);
    
    this.state.fieldMode = enabled;
    
    if (enabled) {
      if (this.components.field && this.components.field.activate) {
        this.components.field.activate();
      }
      document.body.classList.add('field-mode');
    } else {
      if (this.components.field && this.components.field.deactivate) {
        this.components.field.deactivate();
      }
      document.body.classList.remove('field-mode');
    }
    
    // Disparar evento
    this.dispatchEvent('field-mode-changed', { enabled });
  }
  
  /**
   * Atualiza o badge de fila de sincronização
   */
  updateSyncBadge() {
    const badge = document.getElementById('sync-queue-badge');
    if (!badge) return;
    
    const count = this.state.syncQueue.length;
    
    if (count > 0) {
      badge.textContent = `${count} pendente${count > 1 ? 's' : ''}`;
      badge.classList.add('show');
    } else {
      badge.classList.remove('show');
    }
  }
  
  /**
   * Mostra mensagem de erro
   * @param {string} message - Mensagem de erro
   */
  showError(message) {
    console.error('[DiagramaManager]', message);
    
    // Tentar usar sistema de notificação se disponível
    if (typeof showToast === 'function') {
      showToast(message, 'error');
    } else {
      // Fallback para alert
      alert(message);
    }
    
    // Disparar evento
    this.dispatchEvent('error', { message });
  }
  
  /**
   * Mostra mensagem de sucesso
   * @param {string} message - Mensagem de sucesso
   */
  showSuccess(message) {
    console.log('[DiagramaManager]', message);
    
    // Tentar usar sistema de notificação se disponível
    if (typeof showToast === 'function') {
      showToast(message, 'success');
    }
    
    // Disparar evento
    this.dispatchEvent('success', { message });
  }
  
  /**
   * Dispara um evento customizado
   * @param {string} eventName - Nome do evento
   * @param {Object} detail - Dados do evento
   */
  dispatchEvent(eventName, detail = {}) {
    const event = new CustomEvent(eventName, { 
      detail,
      bubbles: true,
      cancelable: true
    });
    document.dispatchEvent(event);
  }
  
  /**
   * Retorna o estado atual do manager
   * @returns {Object} Estado atual
   */
  getState() {
    return { ...this.state };
  }
  
  /**
   * Verifica se o manager está inicializado
   * @returns {boolean} True se inicializado
   */
  isInitialized() {
    return this.state.isInitialized;
  }
  
  /**
   * Verifica se está em modo offline
   * @returns {boolean} True se offline
   */
  isOffline() {
    return this.state.offlineMode;
  }
  
  /**
   * Retorna o componente especificado
   * @param {string} componentName - Nome do componente
   * @returns {Object|null} Componente ou null
   */
  getComponent(componentName) {
    return this.components[componentName] || null;
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.DiagramaManager = DiagramaManager;
}
