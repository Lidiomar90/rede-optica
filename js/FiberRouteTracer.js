/**
 * FiberRouteTracer - Traça rotas completas de fibras ópticas
 * 
 * Responsabilidades:
 * - Chamar RPC tracer_rota_fibra do Supabase
 * - Processar rotas retornadas
 * - Calcular perda total acumulada
 * - Renderizar painel de rota
 * - Integrar com mapa Leaflet para destaque visual
 * 
 * Requirements: 2.1, 2.2, 2.7, 2.8, 11.5
 */
class FiberRouteTracer {
  constructor(config) {
    this.config = config || {};
    this.currentRoute = null;
  }
  
  /**
   * Traça a rota completa de uma fibra
   * @param {string} fiberId - UUID da fibra
   * @returns {Promise<Object>} Objeto com dados da rota processada
   */
  async trace(fiberId) {
    try {
      console.log('[FiberRouteTracer] Traçando rota da fibra:', fiberId);
      
      // Validar entrada
      if (!fiberId) {
        throw new Error('fiberId é obrigatório');
      }
      
      // Validar configuração
      if (!this.config.supabaseUrl || !this.config.supabaseKey) {
        throw new Error('Configuração do Supabase não encontrada');
      }
      
      // Chamar RPC do Supabase
      const response = await fetch(
        `${this.config.supabaseUrl}/rest/v1/rpc/tracer_rota_fibra`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': this.config.supabaseKey,
            'Authorization': `Bearer ${this.config.supabaseKey}`
          },
          body: JSON.stringify({ p_fibra_id: fiberId })
        }
      );
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Falha ao traçar rota: ${response.status} ${response.statusText} - ${errorText}`);
      }
      
      const rawRoute = await response.json();
      
      // Validar resposta
      if (!Array.isArray(rawRoute)) {
        throw new Error('Resposta do RPC não é um array');
      }
      
      if (rawRoute.length === 0) {
        console.warn('[FiberRouteTracer] Rota vazia retornada para fibra:', fiberId);
        return {
          fiberId,
          segments: [],
          totalLoss: 0,
          totalLength: 0,
          connections: 0,
          startPoint: null,
          endPoint: null
        };
      }
      
      // Processar rota
      this.currentRoute = this.processRoute(rawRoute, fiberId);
      
      console.log('[FiberRouteTracer] Rota traçada com sucesso:', this.currentRoute);
      
      return this.currentRoute;
      
    } catch (error) {
      console.error('[FiberRouteTracer] Erro ao traçar rota:', error);
      throw error;
    }
  }
  
  /**
   * Processa dados brutos da rota
   * @param {Array} rawRoute - Dados brutos do RPC
   * @param {string} fiberId - UUID da fibra
   * @returns {Object} Rota processada
   */
  processRoute(rawRoute, fiberId) {
    // Calcular perda total acumulada (último segmento)
    const totalLoss = rawRoute.length > 0 
      ? (rawRoute[rawRoute.length - 1].perda_acumulada_db || 0)
      : 0;
    
    // Calcular comprimento total
    const totalLength = this.calculateTotalLength(rawRoute);
    
    // Contar conexões (segmentos com tipo de conexão)
    const connections = rawRoute.filter(s => s.conexao_tipo).length;
    
    // Obter pontos inicial e final
    const startPoint = this.getStartPoint(rawRoute);
    const endPoint = this.getEndPoint(rawRoute);
    
    return {
      fiberId,
      segments: rawRoute,
      totalLoss,
      totalLength,
      connections,
      startPoint,
      endPoint
    };
  }
  
  /**
   * Calcula o comprimento total da rota
   * @param {Array} route - Segmentos da rota
   * @returns {number} Comprimento total em metros
   */
  calculateTotalLength(route) {
    return route.reduce((sum, segment) => {
      // Usar comprimento do segmento se disponível
      const length = segment.comprimento_metros || 0;
      return sum + length;
    }, 0);
  }
  
  /**
   * Obtém informações do ponto inicial da rota
   * @param {Array} route - Segmentos da rota
   * @returns {Object|null} Informações do ponto inicial
   */
  getStartPoint(route) {
    if (route.length === 0) return null;
    
    const first = route[0];
    return {
      cable: first.cabo_nome || 'N/A',
      tube: first.numero_tubo || 0,
      tubeColor: first.tubo_cor || 'N/A',
      fiber: first.numero_fibra || 0,
      fiberColor: first.fibra_cor || 'N/A'
    };
  }
  
  /**
   * Obtém informações do ponto final da rota
   * @param {Array} route - Segmentos da rota
   * @returns {Object|null} Informações do ponto final
   */
  getEndPoint(route) {
    if (route.length === 0) return null;
    
    const last = route[route.length - 1];
    return {
      cable: last.cabo_nome || 'N/A',
      tube: last.numero_tubo || 0,
      tubeColor: last.tubo_cor || 'N/A',
      fiber: last.numero_fibra || 0,
      fiberColor: last.fibra_cor || 'N/A'
    };
  }
  
  /**
   * Renderiza o painel de rota em HTML
   * @param {Object} route - Dados da rota processada
   * @returns {string} HTML do painel de rota
   */
  renderRoutePanel(route) {
    if (!route || !route.segments) {
      return `
        <div class="route-panel">
          <div class="route-header">
            <h3>Rota da Fibra</h3>
          </div>
          <div class="route-empty">
            <p>Nenhuma rota disponível</p>
          </div>
        </div>
      `;
    }
    
    return `
      <div class="route-panel">
        <div class="route-header">
          <h3>Rota da Fibra</h3>
          <button class="close-btn" onclick="closeRoutePanel()">×</button>
        </div>
        
        <div class="route-summary">
          <div class="route-metric">
            <span class="metric-label">Perda Total</span>
            <span class="metric-value">${route.totalLoss.toFixed(3)} dB</span>
          </div>
          <div class="route-metric">
            <span class="metric-label">Comprimento</span>
            <span class="metric-value">${this.formatLength(route.totalLength)}</span>
          </div>
          <div class="route-metric">
            <span class="metric-label">Conexões</span>
            <span class="metric-value">${route.connections}</span>
          </div>
          <div class="route-metric">
            <span class="metric-label">Segmentos</span>
            <span class="metric-value">${route.segments.length}</span>
          </div>
        </div>
        
        ${route.startPoint ? `
          <div class="route-endpoints">
            <div class="endpoint start">
              <span class="endpoint-label">Origem</span>
              <span class="endpoint-cable">${route.startPoint.cable}</span>
              <span class="endpoint-fiber">T${route.startPoint.tube} (${route.startPoint.tubeColor}) - F${route.startPoint.fiber} (${route.startPoint.fiberColor})</span>
            </div>
            ${route.endPoint && route.segments.length > 1 ? `
              <div class="endpoint end">
                <span class="endpoint-label">Destino</span>
                <span class="endpoint-cable">${route.endPoint.cable}</span>
                <span class="endpoint-fiber">T${route.endPoint.tube} (${route.endPoint.tubeColor}) - F${route.endPoint.fiber} (${route.endPoint.fiberColor})</span>
              </div>
            ` : ''}
          </div>
        ` : ''}
        
        <div class="route-path">
          <h4>Caminho Completo</h4>
          ${this.renderRoutePath(route.segments)}
        </div>
      </div>
    `;
  }
  
  /**
   * Renderiza o caminho da rota (segmentos)
   * @param {Array} segments - Segmentos da rota
   * @returns {string} HTML dos segmentos
   */
  renderRoutePath(segments) {
    if (!segments || segments.length === 0) {
      return '<p class="route-empty">Nenhum segmento encontrado</p>';
    }
    
    return segments.map((segment, index) => {
      const isFirst = index === 0;
      const hasConnection = segment.conexao_tipo;
      const perda = segment.perda_acumulada_db || 0;
      
      return `
        <div class="route-segment ${isFirst ? 'first' : ''} ${hasConnection ? 'has-connection' : ''}">
          <div class="segment-marker">${index + 1}</div>
          <div class="segment-info">
            <div class="segment-cable">
              <strong>${segment.cabo_nome || 'Cabo desconhecido'}</strong>
            </div>
            <div class="segment-fiber">
              Tubo ${segment.numero_tubo || '?'} <span class="color-badge" style="background: ${this.getColorHex(segment.tubo_cor)}">${segment.tubo_cor || 'N/A'}</span>
              - Fibra ${segment.numero_fibra || '?'} <span class="color-badge" style="background: ${this.getColorHex(segment.fibra_cor)}">${segment.fibra_cor || 'N/A'}</span>
            </div>
            ${hasConnection ? `
              <div class="segment-connection">
                <span class="connection-icon">⚡</span>
                <span class="connection-type">${this.formatConnectionType(segment.conexao_tipo)}</span>
                ${segment.perda_conexao_db ? `<span class="connection-loss">${segment.perda_conexao_db.toFixed(3)} dB</span>` : ''}
                ${segment.local_conexao_nome ? `<span class="connection-location">em ${segment.local_conexao_nome}</span>` : ''}
              </div>
            ` : ''}
            <div class="segment-loss">
              Perda acumulada: <strong>${perda.toFixed(3)} dB</strong>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }
  
  /**
   * Formata o comprimento para exibição
   * @param {number} meters - Comprimento em metros
   * @returns {string} Comprimento formatado
   */
  formatLength(meters) {
    if (meters >= 1000) {
      return `${(meters / 1000).toFixed(2)} km`;
    }
    return `${meters.toFixed(0)} m`;
  }
  
  /**
   * Formata o tipo de conexão para exibição
   * @param {string} type - Tipo de conexão
   * @returns {string} Tipo formatado
   */
  formatConnectionType(type) {
    const types = {
      'fusao': 'Fusão',
      'conector_sc': 'Conector SC',
      'conector_lc': 'Conector LC',
      'conector_fc': 'Conector FC',
      'acoplador': 'Acoplador'
    };
    return types[type] || type || 'Conexão';
  }
  
  /**
   * Obtém o código hexadecimal de uma cor ABNT
   * @param {string} colorName - Nome da cor ABNT
   * @returns {string} Código hexadecimal
   */
  getColorHex(colorName) {
    const ABNT_COLORS = {
      'azul': '#0066CC',
      'laranja': '#FF6600',
      'verde': '#00AA00',
      'marrom': '#8B4513',
      'cinza': '#808080',
      'branco': '#FFFFFF',
      'vermelho': '#CC0000',
      'preto': '#000000',
      'amarelo': '#FFCC00',
      'violeta': '#8B00FF',
      'rosa': '#FF69B4',
      'agua': '#00CCCC'
    };
    
    return ABNT_COLORS[colorName] || '#808080';
  }
  
  /**
   * Retorna a rota atual
   * @returns {Object|null} Rota atual ou null
   */
  getCurrentRoute() {
    return this.currentRoute;
  }
  
  /**
   * Limpa a rota atual
   */
  clearRoute() {
    this.currentRoute = null;
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.FiberRouteTracer = FiberRouteTracer;
}
