/**
 * CableDiagramComponent - Renderiza diagrama visual de cabo óptico
 * Segue padrão ABNT para cores de tubos e fibras (12 cores padrão)
 * 
 * Responsabilidades:
 * - Renderização de diagrama com cores ABNT
 * - Agrupamento de dados por tubo loose
 * - Visualização de status de fibras (livre, ativa, reserva, danificada, em_teste)
 * - Interação (click em fibra, expandir/colapsar tubos)
 * 
 * Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.10
 */
class CableDiagramComponent {
  constructor() {
    this.container = null;
    this.cableData = null;
    
    // Cores ABNT para tubos e fibras (12 cores padrão)
    this.ABNT_COLORS = [
      { name: 'azul', hex: '#0066CC', border: '#0066CC' },
      { name: 'laranja', hex: '#FF6600', border: '#FF6600' },
      { name: 'verde', hex: '#00AA00', border: '#00AA00' },
      { name: 'marrom', hex: '#8B4513', border: '#8B4513' },
      { name: 'cinza', hex: '#808080', border: '#808080' },
      { name: 'branco', hex: '#FFFFFF', border: '#CCCCCC' },
      { name: 'vermelho', hex: '#CC0000', border: '#CC0000' },
      { name: 'preto', hex: '#000000', border: '#000000' },
      { name: 'amarelo', hex: '#FFCC00', border: '#FFCC00' },
      { name: 'violeta', hex: '#8B00FF', border: '#8B00FF' },
      { name: 'rosa', hex: '#FF69B4', border: '#FF69B4' },
      { name: 'agua', hex: '#00CCCC', border: '#00CCCC' }
    ];
    
    // Status de fibra com cores e ícones
    this.FIBER_STATUS = {
      livre: { label: 'Livre', color: '#45d08c', icon: '○' },
      ativa: { label: 'Ativa', color: '#48a8ff', icon: '●' },
      reserva: { label: 'Reserva', color: '#ffb648', icon: '◐' },
      danificada: { label: 'Danificada', color: '#ff5a68', icon: '✕' },
      em_teste: { label: 'Em Teste', color: '#8d6bff', icon: '◎' }
    };
  }
  
  /**
   * Renderiza o diagrama de cabo
   * @param {Array} cableData - Dados do cabo da view vw_diagrama_cabo_completo
   */
  render(cableData) {
    console.log('[CableDiagramComponent] Renderizando diagrama', cableData);
    
    this.cableData = cableData;
    this.container = document.getElementById('diagram-container');
    
    if (!this.container) {
      console.error('[CableDiagramComponent] Container do diagrama não encontrado');
      return;
    }
    
    // Agrupar dados por tubo
    const tubes = this.groupByTube(cableData);
    
    console.log('[CableDiagramComponent] Tubos agrupados:', tubes);
    
    // Renderizar HTML
    this.container.innerHTML = this.buildDiagramHTML(tubes);
    
    // Adicionar event listeners
    this.attachEventListeners();
    
    console.log('[CableDiagramComponent] Diagrama renderizado com sucesso');
  }
  
  /**
   * Agrupa dados por tubo loose
   * @param {Array} data - Dados brutos do cabo
   * @returns {Array} Array de tubos com suas fibras
   */
  groupByTube(data) {
    const tubes = {};
    
    data.forEach(row => {
      // Criar tubo se não existir
      if (!tubes[row.tubo_id]) {
        tubes[row.tubo_id] = {
          id: row.tubo_id,
          numero: row.numero_tubo,
          cor: row.tubo_cor,
          status: row.tubo_status,
          fibras: []
        };
      }
      
      // Adicionar fibra ao tubo
      if (row.fibra_id) {
        tubes[row.tubo_id].fibras.push({
          id: row.fibra_id,
          numero: row.numero_fibra,
          cor: row.fibra_cor,
          status: row.fibra_status,
          tipo_uso: row.fibra_tipo_uso,
          perda_total_db: row.perda_total_db,
          comprimento_metros: row.comprimento_metros
        });
      }
    });
    
    // Converter para array e ordenar por número do tubo
    return Object.values(tubes).sort((a, b) => a.numero - b.numero);
  }
  
  /**
   * Constrói o HTML completo do diagrama
   * @param {Array} tubes - Array de tubos
   * @returns {string} HTML do diagrama
   */
  buildDiagramHTML(tubes) {
    const cableName = this.cableData[0]?.cabo_nome || 'Cabo';
    const cableCapacity = this.cableData[0]?.cabo_capacidade || 0;
    const cableType = this.cableData[0]?.cabo_tipo || 'N/A';
    const cableStatus = this.cableData[0]?.cabo_status || 'N/A';
    
    // Calcular estatísticas
    const stats = this.calculateStats(tubes);
    
    return `
      <div class="diagram-wrapper">
        <!-- Header do diagrama -->
        <div class="diagram-header">
          <div class="diagram-title">
            <h2>${cableName}</h2>
            <button class="close-btn" onclick="closeDiagramModal()">×</button>
          </div>
          <div class="diagram-meta">
            <span class="meta-item">
              <strong>Tipo:</strong> ${cableType}
            </span>
            <span class="meta-item">
              <strong>Capacidade:</strong> ${cableCapacity} fibras
            </span>
            <span class="meta-item">
              <strong>Tubos:</strong> ${tubes.length}
            </span>
            <span class="meta-item">
              <strong>Status:</strong> <span class="status-badge status-${cableStatus}">${cableStatus}</span>
            </span>
          </div>
        </div>
        
        <!-- Estatísticas de fibras -->
        <div class="diagram-stats">
          <div class="stat-card stat-livre">
            <div class="stat-icon">○</div>
            <div class="stat-info">
              <div class="stat-value">${stats.livre}</div>
              <div class="stat-label">Livres</div>
            </div>
          </div>
          <div class="stat-card stat-ativa">
            <div class="stat-icon">●</div>
            <div class="stat-info">
              <div class="stat-value">${stats.ativa}</div>
              <div class="stat-label">Ativas</div>
            </div>
          </div>
          <div class="stat-card stat-reserva">
            <div class="stat-icon">◐</div>
            <div class="stat-info">
              <div class="stat-value">${stats.reserva}</div>
              <div class="stat-label">Reserva</div>
            </div>
          </div>
          <div class="stat-card stat-danificada">
            <div class="stat-icon">✕</div>
            <div class="stat-info">
              <div class="stat-value">${stats.danificada}</div>
              <div class="stat-label">Danificadas</div>
            </div>
          </div>
          <div class="stat-card stat-em_teste">
            <div class="stat-icon">◎</div>
            <div class="stat-info">
              <div class="stat-value">${stats.em_teste}</div>
              <div class="stat-label">Em Teste</div>
            </div>
          </div>
        </div>
        
        <!-- Legenda -->
        <div class="diagram-legend">
          <div class="legend-section">
            <span class="legend-title">Status das Fibras:</span>
            ${Object.entries(this.FIBER_STATUS).map(([key, val]) => `
              <span class="legend-item">
                <span class="legend-icon" style="color: ${val.color}">${val.icon}</span>
                <span class="legend-text">${val.label}</span>
              </span>
            `).join('')}
          </div>
        </div>
        
        <!-- Container de tubos -->
        <div class="tubes-container">
          ${tubes.map(tube => this.buildTubeHTML(tube)).join('')}
        </div>
      </div>
    `;
  }
  
  /**
   * Calcula estatísticas de fibras
   * @param {Array} tubes - Array de tubos
   * @returns {Object} Estatísticas por status
   */
  calculateStats(tubes) {
    const stats = {
      livre: 0,
      ativa: 0,
      reserva: 0,
      danificada: 0,
      em_teste: 0
    };
    
    tubes.forEach(tube => {
      tube.fibras.forEach(fiber => {
        if (stats.hasOwnProperty(fiber.status)) {
          stats[fiber.status]++;
        }
      });
    });
    
    return stats;
  }
  
  /**
   * Constrói o HTML de um tubo loose
   * @param {Object} tube - Dados do tubo
   * @returns {string} HTML do tubo
   */
  buildTubeHTML(tube) {
    const color = this.getColorHex(tube.cor);
    const statusClass = tube.status === 'ativo' ? 'active' : 'inactive';
    const fiberCount = tube.fibras.length;
    
    return `
      <div class="tube ${statusClass}" data-tube-id="${tube.id}">
        <div class="tube-header" style="background: linear-gradient(135deg, ${color} 0%, ${this.darkenColor(color, 20)} 100%)">
          <div class="tube-info">
            <span class="tube-number">Tubo ${tube.numero}</span>
            <span class="tube-color">${tube.cor}</span>
          </div>
          <div class="tube-meta">
            <span class="tube-fiber-count">${fiberCount} fibra${fiberCount !== 1 ? 's' : ''}</span>
            <span class="tube-status">${tube.status}</span>
            <span class="tube-toggle">▼</span>
          </div>
        </div>
        <div class="fibers-grid">
          ${tube.fibras.length > 0 
            ? tube.fibras.map(fiber => this.buildFiberHTML(fiber)).join('') 
            : '<div class="no-fibers">Nenhuma fibra cadastrada</div>'}
        </div>
      </div>
    `;
  }
  
  /**
   * Constrói o HTML de uma fibra individual
   * @param {Object} fiber - Dados da fibra
   * @returns {string} HTML da fibra
   */
  buildFiberHTML(fiber) {
    const color = this.getColorHex(fiber.cor);
    const status = this.FIBER_STATUS[fiber.status] || this.FIBER_STATUS.livre;
    const borderColor = fiber.cor === 'branco' ? '#CCCCCC' : color;
    
    // Tooltip com informações detalhadas
    const tooltip = this.buildFiberTooltip(fiber, status);
    
    return `
      <div class="fiber" 
           data-fiber-id="${fiber.id}"
           data-status="${fiber.status}"
           title="${tooltip}">
        <div class="fiber-circle" 
             style="background: ${color}; border-color: ${borderColor}">
          <span class="fiber-number">${fiber.numero}</span>
        </div>
        <span class="fiber-status-icon" style="color: ${status.color}">
          ${status.icon}
        </span>
        <span class="fiber-color-label">${fiber.cor}</span>
      </div>
    `;
  }
  
  /**
   * Constrói o tooltip de uma fibra
   * @param {Object} fiber - Dados da fibra
   * @param {Object} status - Status da fibra
   * @returns {string} Texto do tooltip
   */
  buildFiberTooltip(fiber, status) {
    let tooltip = `Fibra ${fiber.numero} - ${fiber.cor}\nStatus: ${status.label}`;
    
    if (fiber.tipo_uso) {
      tooltip += `\nTipo de Uso: ${fiber.tipo_uso}`;
    }
    
    if (fiber.perda_total_db !== null && fiber.perda_total_db !== undefined) {
      tooltip += `\nPerda Total: ${fiber.perda_total_db} dB`;
    }
    
    if (fiber.comprimento_metros !== null && fiber.comprimento_metros !== undefined) {
      tooltip += `\nComprimento: ${fiber.comprimento_metros} m`;
    }
    
    return tooltip;
  }
  
  /**
   * Obtém a cor hexadecimal de uma cor ABNT
   * @param {string} colorName - Nome da cor ABNT
   * @returns {string} Código hexadecimal da cor
   */
  getColorHex(colorName) {
    const color = this.ABNT_COLORS.find(c => c.name === colorName);
    return color ? color.hex : '#808080';
  }
  
  /**
   * Escurece uma cor hexadecimal
   * @param {string} hex - Cor hexadecimal
   * @param {number} percent - Percentual de escurecimento (0-100)
   * @returns {string} Cor escurecida
   */
  darkenColor(hex, percent) {
    // Remove # se presente
    hex = hex.replace('#', '');
    
    // Converte para RGB
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    
    // Escurece
    const factor = (100 - percent) / 100;
    const newR = Math.round(r * factor);
    const newG = Math.round(g * factor);
    const newB = Math.round(b * factor);
    
    // Converte de volta para hex
    return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`;
  }
  
  /**
   * Adiciona event listeners aos elementos do diagrama
   */
  attachEventListeners() {
    console.log('[CableDiagramComponent] Adicionando event listeners');
    
    // Click em fibra
    this.container.querySelectorAll('.fiber').forEach(fiberEl => {
      fiberEl.addEventListener('click', (e) => {
        e.stopPropagation();
        const fiberId = e.currentTarget.dataset.fiberId;
        this.onFiberClick(fiberId, e.currentTarget);
      });
    });
    
    // Click em header do tubo (expandir/colapsar)
    this.container.querySelectorAll('.tube-header').forEach(tubeHeader => {
      tubeHeader.addEventListener('click', (e) => {
        const tube = e.currentTarget.closest('.tube');
        this.toggleTube(tube);
      });
    });
  }
  
  /**
   * Handler para click em fibra
   * @param {string} fiberId - UUID da fibra
   * @param {HTMLElement} fiberEl - Elemento DOM da fibra
   */
  onFiberClick(fiberId, fiberEl) {
    console.log('[CableDiagramComponent] Fibra clicada:', fiberId);
    
    // Remover seleção anterior
    this.container.querySelectorAll('.fiber').forEach(f => {
      f.classList.remove('selected');
    });
    
    // Adicionar seleção à fibra clicada
    fiberEl.classList.add('selected');
    
    // Disparar evento para tracer de rota
    document.dispatchEvent(new CustomEvent('fiber-selected', {
      detail: { fiberId },
      bubbles: true
    }));
  }
  
  /**
   * Expande ou colapsa um tubo
   * @param {HTMLElement} tubeEl - Elemento DOM do tubo
   */
  toggleTube(tubeEl) {
    const isCollapsed = tubeEl.classList.contains('collapsed');
    
    if (isCollapsed) {
      tubeEl.classList.remove('collapsed');
      console.log('[CableDiagramComponent] Tubo expandido');
    } else {
      tubeEl.classList.add('collapsed');
      console.log('[CableDiagramComponent] Tubo colapsado');
    }
    
    // Atualizar ícone de toggle
    const toggleIcon = tubeEl.querySelector('.tube-toggle');
    if (toggleIcon) {
      toggleIcon.textContent = isCollapsed ? '▼' : '▲';
    }
  }
  
  /**
   * Limpa o diagrama
   */
  clear() {
    if (this.container) {
      this.container.innerHTML = '';
    }
    this.cableData = null;
  }
}

// Exportar para uso global
if (typeof window !== 'undefined') {
  window.CableDiagramComponent = CableDiagramComponent;
}
