// ═══════════════════════════════════════════════════════════════════════════════
// MÓDULO DE TRATAMENTO DE ERROS PROFISSIONAL
// Notifica o usuário de forma clara e oferece ações corretivas
// ═══════════════════════════════════════════════════════════════════════════════

class GerenciadorErros {
  constructor() {
    this.errosRegistrados = [];
    this.maxErrosArmazenados = 100;
    this.listeners = [];
    this.foundation = window.AppFoundation || null;
  }

  log(level, event, context = {}) {
    if (this.foundation && typeof this.foundation.log === 'function') {
      this.foundation.log(level, event, context);
      return;
    }
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(`[ERRO:${level}] ${event}`, context);
  }

  notify(message, tone = 'error', options = {}) {
    if (typeof showToast === 'function') {
      showToast(message, tone, options);
      return;
    }
    if (this.foundation && typeof this.foundation.notify === 'function') {
      this.foundation.notify(message, tone);
      return;
    }
    console.log(`[ERRO:notify:${tone}] ${message}`);
  }

  showBusy(label = 'Processando...') {
    if (typeof showSpinner === 'function') {
      showSpinner(label);
      return;
    }
    if (this.foundation && typeof this.foundation.showSpinner === 'function') {
      this.foundation.showSpinner(label);
    }
  }

  hideBusy() {
    if (typeof hideSpinner === 'function') {
      hideSpinner();
      return;
    }
    if (this.foundation && typeof this.foundation.hideSpinner === 'function') {
      this.foundation.hideSpinner();
    }
  }

  /**
   * Registrar erro com contexto completo
   */
  registrarErro(tipo, mensagem, contexto = {}, severidade = 'erro') {
    const erro = {
      id: `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      tipo: tipo, // 'rede', 'validacao', 'banco', 'autenticacao', 'desconhecido'
      mensagem: mensagem,
      contexto: contexto,
      severidade: severidade, // 'info', 'aviso', 'erro', 'critico'
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      url: window.location.href
    };

    this.errosRegistrados.push(erro);
    if (this.errosRegistrados.length > this.maxErrosArmazenados) {
      this.errosRegistrados.shift();
    }

    // Salvar no localStorage para análise posterior
    this.salvarErrosNoStorage();

    // Disparar evento
    this.notificarListeners(erro);

    this.log(erro.severidade === 'critico' || erro.severidade === 'erro' ? 'error' : 'warn', `erro:${erro.tipo}`, erro);

    return erro.id;
  }

  /**
   * Traduzir erro técnico para mensagem amigável
   */
  traduzirErro(erro) {
    const mensagem = erro.message?.toLowerCase() || '';

    // Erros de rede
    if (mensagem.includes('network') || mensagem.includes('econnrefused')) {
      return {
        titulo: '🌐 Sem Conexão',
        mensagem: 'Verifique sua conexão de internet. Os dados serão sincronizados automaticamente quando a conexão for restaurada.',
        acao: 'Reconectar',
        tipo: 'rede'
      };
    }

    // Timeout
    if (mensagem.includes('timeout')) {
      return {
        titulo: '⏱️ Conexão Lenta',
        mensagem: 'O servidor está demorando para responder. Tente novamente em alguns segundos.',
        acao: 'Tentar Novamente',
        tipo: 'timeout'
      };
    }

    // Rate limit
    if (mensagem.includes('429') || mensagem.includes('too many requests')) {
      return {
        titulo: '🚦 Muitas Requisições',
        mensagem: 'Você está fazendo muitas requisições. Aguarde alguns segundos antes de tentar novamente.',
        acao: 'Aguardar',
        tipo: 'rate_limit'
      };
    }

    // Autenticação
    if (mensagem.includes('401') || mensagem.includes('unauthorized')) {
      return {
        titulo: '🔐 Sessão Expirada',
        mensagem: 'Sua sessão expirou. Por favor, faça login novamente.',
        acao: 'Fazer Login',
        tipo: 'autenticacao'
      };
    }

    // Validação
    if (mensagem.includes('validation') || mensagem.includes('invalid')) {
      return {
        titulo: '⚠️ Dados Inválidos',
        mensagem: 'Verifique os dados preenchidos e tente novamente.',
        acao: 'Corrigir',
        tipo: 'validacao'
      };
    }

    // Erro genérico
    return {
      titulo: '❌ Erro Desconhecido',
      mensagem: `Algo deu errado: ${erro.message || 'Erro desconhecido'}`,
      acao: 'Tentar Novamente',
      tipo: 'desconhecido'
    };
  }

  /**
   * Exibir erro ao usuário com toast
   */
  exibirErroAoUsuario(erro, opcoes = {}) {
    const traducao = this.traduzirErro(erro);
    const mensagemCompleta = `${traducao.titulo}\n${traducao.mensagem}`;

    this.notify(mensagemCompleta, 'error', {
      duracao: opcoes.duracao || 5000,
      acao: traducao.acao,
      callback: opcoes.callback
    });

    this.registrarErro(traducao.tipo, traducao.mensagem, { erro: erro.message });
  }

  /**
   * Wrapper para requisições HTTP com tratamento de erro
   */
  async executarComTratamento(funcao, nomeOperacao = 'Operação') {
    try {
      this.showBusy(nomeOperacao);
      const resultado = await funcao();
      this.hideBusy();
      return resultado;
    } catch (erro) {
      this.hideBusy();
      this.exibirErroAoUsuario(erro, {
        callback: () => {
          // Opção de retry
          console.log(`Retry de ${nomeOperacao}`);
        }
      });
      throw erro;
    }
  }

  /**
   * Validar dados antes de salvar
   */
  validarDados(dados, schema) {
    const erros = [];

    for (const [campo, regra] of Object.entries(schema)) {
      const valor = dados[campo];

      // Verificar se é obrigatório
      if (regra.obrigatorio && !valor) {
        erros.push(`${campo} é obrigatório`);
      }

      // Verificar tipo
      if (valor && regra.tipo) {
        if (typeof valor !== regra.tipo) {
          erros.push(`${campo} deve ser ${regra.tipo}`);
        }
      }

      // Verificar comprimento mínimo
      if (valor && regra.minLength && valor.length < regra.minLength) {
        erros.push(`${campo} deve ter pelo menos ${regra.minLength} caracteres`);
      }

      // Verificar comprimento máximo
      if (valor && regra.maxLength && valor.length > regra.maxLength) {
        erros.push(`${campo} não pode ter mais de ${regra.maxLength} caracteres`);
      }

      // Verificar padrão regex
      if (valor && regra.pattern && !regra.pattern.test(valor)) {
        erros.push(`${campo} está em formato inválido`);
      }
    }

    return {
      valido: erros.length === 0,
      erros: erros
    };
  }

  /**
   * Salvar erros no localStorage para análise
   */
  salvarErrosNoStorage() {
    try {
      localStorage.setItem('_ro_erros_log', JSON.stringify(this.errosRegistrados));
    } catch (error) {
      console.error('[ERRO] Não foi possível salvar log de erros:', error);
    }
  }

  /**
   * Carregar erros do localStorage
   */
  carregarErrosDoStorage() {
    try {
      const errosArmazenados = localStorage.getItem('_ro_erros_log');
      if (errosArmazenados) {
        this.errosRegistrados = JSON.parse(errosArmazenados);
      }
    } catch (error) {
      console.error('[ERRO] Não foi possível carregar log de erros:', error);
    }
  }

  /**
   * Registrar listener para erros
   */
  adicionarListener(callback) {
    this.listeners.push(callback);
  }

  /**
   * Notificar listeners
   */
  notificarListeners(erro) {
    this.listeners.forEach(callback => {
      try {
        callback(erro);
      } catch (error) {
        console.error('[ERRO] Erro ao notificar listener:', error);
      }
    });
  }

  /**
   * Obter histórico de erros
   */
  obterHistorico(filtro = {}) {
    let erros = this.errosRegistrados;

    if (filtro.tipo) {
      erros = erros.filter(e => e.tipo === filtro.tipo);
    }

    if (filtro.severidade) {
      erros = erros.filter(e => e.severidade === filtro.severidade);
    }

    if (filtro.ultimas) {
      erros = erros.slice(-filtro.ultimas);
    }

    return erros;
  }

  /**
   * Gerar relatório de erros para envio ao suporte
   */
  gerarRelatorioErros() {
    return {
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      url: window.location.href,
      erros: this.errosRegistrados,
      resumo: {
        total: this.errosRegistrados.length,
        porTipo: this.agruparPorTipo(),
        porSeveridade: this.agruparPorSeveridade()
      }
    };
  }

  /**
   * Agrupar erros por tipo
   */
  agruparPorTipo() {
    const grupos = {};
    this.errosRegistrados.forEach(erro => {
      grupos[erro.tipo] = (grupos[erro.tipo] || 0) + 1;
    });
    return grupos;
  }

  /**
   * Agrupar erros por severidade
   */
  agruparPorSeveridade() {
    const grupos = {};
    this.errosRegistrados.forEach(erro => {
      grupos[erro.severidade] = (grupos[erro.severidade] || 0) + 1;
    });
    return grupos;
  }

  /**
   * Limpar histórico de erros
   */
  limparHistorico() {
    this.errosRegistrados = [];
    localStorage.removeItem('_ro_erros_log');
  }
}

// Instância global
let gerenciadorErros = new GerenciadorErros();

/**
 * Inicializar tratamento de erros global
 */
function inicializarTratamentoErros() {
  gerenciadorErros.carregarErrosDoStorage();

  // Capturar erros não tratados
  window.addEventListener('error', (event) => {
    gerenciadorErros.registrarErro(
      'desconhecido',
      event.message,
      { arquivo: event.filename, linha: event.lineno },
      'critico'
    );
  });

  // Capturar promessas rejeitadas
  window.addEventListener('unhandledrejection', (event) => {
    gerenciadorErros.registrarErro(
      'desconhecido',
      event.reason?.message || 'Promise rejeitada',
      { reason: event.reason },
      'critico'
    );
  });

  // Monitorar conexão
  window.addEventListener('offline', () => {
    gerenciadorErros.registrarErro('rede', 'Conexão perdida', {}, 'aviso');
    gerenciadorErros.notify('Você ficou offline. Os dados serão sincronizados quando a conexão for restaurada.', 'warning');
  });

  window.addEventListener('online', () => {
    gerenciadorErros.registrarErro('rede', 'Conexão restaurada', {}, 'info');
    gerenciadorErros.notify('Conexão restaurada.', 'success');
  });

  gerenciadorErros.log('info', 'error-manager:init');
}

/**
 * Schema de validação para DGO
 */
const SCHEMA_DGO = {
  nome: { obrigatorio: true, tipo: 'string', minLength: 3, maxLength: 100 },
  lat: { obrigatorio: true, tipo: 'number' },
  lng: { obrigatorio: true, tipo: 'number' },
  site_id: { obrigatorio: true, tipo: 'string' }
};

/**
 * Schema de validação para Caixa
 */
const SCHEMA_CAIXA = {
  nome: { obrigatorio: true, tipo: 'string', minLength: 3, maxLength: 100 },
  lat: { obrigatorio: true, tipo: 'number' },
  lng: { obrigatorio: true, tipo: 'number' },
  finalidade: { obrigatorio: true, tipo: 'string' }
};

/**
 * Schema de validação para Segmento
 */
const SCHEMA_SEGMENTO = {
  de_id: { obrigatorio: true, tipo: 'string' },
  para_id: { obrigatorio: true, tipo: 'string' },
  comprimento_km: { obrigatorio: true, tipo: 'number' }
};
