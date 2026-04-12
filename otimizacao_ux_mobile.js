// ═══════════════════════════════════════════════════════════════════════════════
// MÓDULO DE OTIMIZAÇÃO DE UX MOBILE E INTERFACE DE CAMPO
// Garante que a interface seja usável em celulares com luva e em condições de campo
// ═══════════════════════════════════════════════════════════════════════════════

class OtimizadorUXMobile {
  constructor() {
    this.isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    this.isTouch = () => window.matchMedia('(hover: none)').matches;
    this.viewportHeight = window.innerHeight;
    this.viewportWidth = window.innerWidth;
  }

  /**
   * Aplicar otimizações de UX Mobile ao carregar
   */
  aplicarOtimizacoes() {
    if (!this.isMobile) return;

    console.log('[UX-MOBILE] Aplicando otimizações para dispositivo móvel');

    this.otimizarBotoes();
    this.otimizarModais();
    this.otimizarFormularios();
    this.otimizarTeclado();
    this.adicionarGestosTouch();
    this.ajustarEspacamento();

    // Reajustar ao mudar orientação
    window.addEventListener('orientationchange', () => {
      setTimeout(() => this.aplicarOtimizacoes(), 300);
    });
  }

  /**
   * Otimizar tamanho e espaçamento de botões para toque
   */
  otimizarBotoes() {
    const botoes = document.querySelectorAll('button, .btn, [role="button"]');

    botoes.forEach(btn => {
      // Aumentar área de toque para mínimo 44x44px (recomendação Apple/Google)
      const style = window.getComputedStyle(btn);
      const altura = btn.offsetHeight;
      const largura = btn.offsetWidth;

      if (altura < 44 || largura < 44) {
        btn.style.minHeight = '44px';
        btn.style.minWidth = '44px';
        btn.style.padding = '12px 16px';
        btn.style.fontSize = '14px';
      }

      // Adicionar feedback visual ao toque
      btn.style.touchAction = 'manipulation';
      btn.addEventListener('touchstart', (e) => {
        btn.style.opacity = '0.7';
        btn.style.transform = 'scale(0.98)';
      });

      btn.addEventListener('touchend', (e) => {
        btn.style.opacity = '1';
        btn.style.transform = 'scale(1)';
      });

      // Desabilitar ao clicar para evitar duplicação
      btn.addEventListener('click', function(e) {
        if (this.dataset.loading === 'true') {
          e.preventDefault();
          return;
        }
        this.dataset.loading = 'true';
        this.disabled = true;
        setTimeout(() => {
          this.dataset.loading = 'false';
          this.disabled = false;
        }, 1000);
      });
    });
  }

  /**
   * Otimizar modais para não cortar em telas pequenas
   */
  otimizarModais() {
    const modais = document.querySelectorAll('[role="dialog"], .modal, .md');

    modais.forEach(modal => {
      const altura = modal.offsetHeight;
      const alturaViewport = this.viewportHeight;

      if (altura > alturaViewport * 0.9) {
        // Modal muito grande, ajustar
        modal.style.maxHeight = `calc(100vh - 120px)`;
        modal.style.overflowY = 'auto';
        modal.style.overflowX = 'hidden';
        modal.style.borderRadius = '16px 16px 0 0'; // Arredondar só o topo
        modal.style.position = 'fixed';
        modal.style.bottom = '0';
        modal.style.left = '0';
        modal.style.right = '0';
        modal.style.zIndex = '1000';

        // Adicionar padding para safe area (notch, home indicator)
        const safeBottom = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--mobile-safe-bottom')) || 0;
        modal.style.paddingBottom = `calc(16px + ${safeBottom}px)`;
      }

      // Garantir que o botão "Salvar" é sempre visível
      const btnSalvar = modal.querySelector('[data-action="save"], .save-btn, button:last-child');
      if (btnSalvar) {
        btnSalvar.style.position = 'sticky';
        btnSalvar.style.bottom = '0';
        btnSalvar.style.width = '100%';
        btnSalvar.style.marginTop = '16px';
      }
    });
  }

  /**
   * Otimizar formulários para entrada em campo
   */
  otimizarFormularios() {
    const inputs = document.querySelectorAll('input, textarea, select');

    inputs.forEach(input => {
      // Aumentar tamanho do input
      input.style.minHeight = '44px';
      input.style.fontSize = '16px'; // Evitar zoom automático em iOS
      input.style.padding = '12px';

      // Adicionar espaço entre inputs
      input.style.marginBottom = '16px';

      // Melhorar contraste
      input.style.borderWidth = '2px';

      // Adicionar ícone de limpeza para inputs de texto
      if (input.type === 'text' || input.type === 'search') {
        const wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        input.parentNode.insertBefore(wrapper, input);
        wrapper.appendChild(input);

        const btnLimpar = document.createElement('button');
        btnLimpar.innerHTML = '✕';
        btnLimpar.style.position = 'absolute';
        btnLimpar.style.right = '8px';
        btnLimpar.style.top = '50%';
        btnLimpar.style.transform = 'translateY(-50%)';
        btnLimpar.style.background = 'none';
        btnLimpar.style.border = 'none';
        btnLimpar.style.cursor = 'pointer';
        btnLimpar.style.fontSize = '18px';
        btnLimpar.style.color = 'var(--t3)';
        btnLimpar.style.padding = '8px';
        btnLimpar.style.display = input.value ? 'block' : 'none';

        btnLimpar.addEventListener('click', (e) => {
          e.preventDefault();
          input.value = '';
          input.focus();
          btnLimpar.style.display = 'none';
        });

        input.addEventListener('input', () => {
          btnLimpar.style.display = input.value ? 'block' : 'none';
        });

        wrapper.appendChild(btnLimpar);
      }
    });
  }

  /**
   * Otimizar teclado virtual
   */
  otimizarTeclado() {
    const inputs = document.querySelectorAll('input, textarea');

    inputs.forEach(input => {
      // Definir tipo de teclado apropriado
      if (input.name?.includes('email')) {
        input.type = 'email';
        input.inputMode = 'email';
      } else if (input.name?.includes('phone') || input.name?.includes('telefone')) {
        input.type = 'tel';
        input.inputMode = 'tel';
      } else if (input.name?.includes('lat') || input.name?.includes('lng') || input.name?.includes('numero')) {
        input.inputMode = 'decimal';
      }

      // Ao focar, scroll para o input
      input.addEventListener('focus', () => {
        setTimeout(() => {
          input.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }, 300);
      });
    });
  }

  /**
   * Adicionar gestos de toque (swipe, long-press)
   */
  adicionarGestosTouch() {
    let touchStartX = 0;
    let touchStartY = 0;
    let touchStartTime = 0;

    document.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      touchStartTime = Date.now();
    });

    document.addEventListener('touchend', (e) => {
      const touchEndX = e.changedTouches[0].clientX;
      const touchEndY = e.changedTouches[0].clientY;
      const touchDuration = Date.now() - touchStartTime;

      const deltaX = touchEndX - touchStartX;
      const deltaY = touchEndY - touchStartY;

      // Swipe para fechar modal (swipe down)
      if (deltaY > 100 && touchDuration < 500) {
        const modal = document.querySelector('[role="dialog"], .modal.on, .md.on');
        if (modal) {
          const btnFechar = modal.querySelector('[data-action="close"], .close-btn, button:first-child');
          if (btnFechar) btnFechar.click();
        }
      }

      // Long-press para menu de contexto
      if (touchDuration > 500 && Math.abs(deltaX) < 10 && Math.abs(deltaY) < 10) {
        const target = e.target.closest('[data-context-menu]');
        if (target) {
          target.dispatchEvent(new Event('contextmenu'));
        }
      }
    });
  }

  /**
   * Ajustar espaçamento para modo campo
   */
  ajustarEspacamento() {
    // Aumentar espaçamento entre elementos para evitar cliques acidentais
    const elementos = document.querySelectorAll('button, .btn, input, select, textarea, [role="button"]');

    elementos.forEach(el => {
      const style = window.getComputedStyle(el);
      const margin = parseInt(style.margin) || 0;

      if (margin < 8) {
        el.style.margin = '8px';
      }
    });

    // Aumentar line-height para melhor legibilidade em campo
    const textos = document.querySelectorAll('label, p, span, div');
    textos.forEach(el => {
      el.style.lineHeight = '1.6';
    });
  }

  /**
   * Modo "Campo" — Simplificar UI ao máximo
   */
  ativarModoCampo() {
    console.log('[UX-MOBILE] Ativando modo campo');

    // Ocultar elementos não essenciais
    const elementosOcultos = [
      '#nav', // Abas de navegação
      '#lc', // Camadas
      '.sbstats', // Estatísticas
      '.sbpill' // Pills de status
    ];

    elementosOcultos.forEach(seletor => {
      const el = document.querySelector(seletor);
      if (el) el.style.display = 'none';
    });

    // Aumentar tamanho da sidebar para 100% em mobile
    const sb = document.getElementById('sb');
    if (sb) {
      sb.style.width = '100%';
      sb.style.maxWidth = '100%';
    }

    // Aumentar tamanho do mapa
    const mapa = document.getElementById('map');
    if (mapa) {
      mapa.style.flex = '1';
    }

    // Botões flutuantes para ações principais
    this.criarBotoesFlutantes();
  }

  /**
   * Criar botões flutuantes para ações principais
   */
  criarBotoesFlutantes() {
    const fab = document.createElement('div');
    fab.id = 'fab-menu';
    fab.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      z-index: 500;
      display: flex;
      flex-direction: column;
      gap: 10px;
      align-items: flex-end;
    `;

    const acoes = [
      { icone: '📍', label: 'DGO', acao: () => openM('dgo') },
      { icone: '📦', label: 'Caixa', acao: () => openM('caixa') },
      { icone: '🔗', label: 'Segmento', acao: () => openM('segmento') },
      { icone: '🚨', label: 'Ruptura', acao: () => openM('ruptura') }
    ];

    acoes.forEach(acao => {
      const btn = document.createElement('button');
      btn.innerHTML = acao.icone;
      btn.title = acao.label;
      btn.style.cssText = `
        width: 56px;
        height: 56px;
        border-radius: 50%;
        background: var(--gr);
        color: #000;
        border: none;
        font-size: 24px;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(0,0,0,.3);
        transition: transform .2s;
      `;

      btn.addEventListener('click', acao.acao);
      btn.addEventListener('touchstart', () => btn.style.transform = 'scale(0.9)');
      btn.addEventListener('touchend', () => btn.style.transform = 'scale(1)');

      fab.appendChild(btn);
    });

    document.body.appendChild(fab);
  }

  /**
   * Detectar orientação e ajustar layout
   */
  ajustarOrientacao() {
    const isPortrait = window.innerHeight > window.innerWidth;

    if (isPortrait) {
      document.body.style.flexDirection = 'column';
    } else {
      document.body.style.flexDirection = 'row';
    }
  }
}

// Instância global
let otimizadorUX = new OtimizadorUXMobile();

/**
 * Inicializar otimizações de UX Mobile
 */
function inicializarOtimizacoesUXMobile() {
  otimizadorUX.aplicarOtimizacoes();
  otimizadorUX.ajustarOrientacao();

  // Reajustar ao redimensionar
  window.addEventListener('resize', () => {
    otimizadorUX.ajustarOrientacao();
  });

  console.log('[UX-MOBILE] Otimizações inicializadas');
}

/**
 * Ativar modo campo
 */
function ativarModoCampo() {
  otimizadorUX.ativarModoCampo();
  localStorage.setItem('_ro_modo_campo', 'true');
}

/**
 * Desativar modo campo
 */
function desativarModoCampo() {
  location.reload(); // Recarregar para voltar ao normal
  localStorage.removeItem('_ro_modo_campo');
}
