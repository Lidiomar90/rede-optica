// ═══════════════════════════════════════════════════════════════════════════════
// MÓDULO DE SINCRONIZAÇÃO ROBUSTA COM RETRY AUTOMÁTICO
// Garante que nenhum dado seja perdido, mesmo com falhas de rede
// ═══════════════════════════════════════════════════════════════════════════════

class SincronizadorRobusto {
  constructor(configOrUrl, maybeHeaders) {
    const config = (typeof configOrUrl === 'object' && configOrUrl !== null)
      ? configOrUrl
      : { url: configOrUrl, headers: maybeHeaders };

    this.foundation = window.AppFoundation || null;
    this.supabaseUrl = config.url || '';
    this.supabaseHeaders = config.headers || config.writeHeaders || config.readHeaders || {};
    this.configSource = config.source || 'manual';
    this.ready = !!(this.supabaseUrl && this.supabaseHeaders && Object.keys(this.supabaseHeaders).length);
    this.filaSync = [];
    this.tentativas = {};
    this.maxTentativas = 5;
    this.backoffInicial = 1000;
    this.maxBackoff = 30000;
    this.statusSync = 'ocioso';
    this.ultimoErro = null;
  }

  log(level, event, context = {}) {
    if (this.foundation && typeof this.foundation.log === 'function') {
      this.foundation.log(level, event, context);
      return;
    }
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(`[SYNC:${level}] ${event}`, context);
  }

  notify(message, tone = 'info') {
    if (this.foundation && typeof this.foundation.notify === 'function') {
      this.foundation.notify(message, tone);
      return;
    }
    if (typeof showToast === 'function') {
      showToast(message, tone);
      return;
    }
    console.log(`[SYNC:notify:${tone}] ${message}`);
  }

  adicionarAFila(tipo, dados, id = null) {
    const itemSync = {
      id: id || `${tipo}_${Date.now()}_${Math.random()}`,
      tipo: tipo,
      dados: dados,
      timestamp: new Date().toISOString(),
      status: 'pendente',
      tentativas: 0,
      ultimoErro: null,
      checksum: this.calcularChecksum(dados)
    };

    this.filaSync.push(itemSync);
    this.salvarFilaNoStorage();
    this.notificarStatusSync();

    this.log('info', 'sync:queue:add', { itemId: itemSync.id, tipo });
    return itemSync.id;
  }

  calcularChecksum(dados) {
    const json = JSON.stringify(dados);
    let hash = 0;
    for (let i = 0; i < json.length; i++) {
      const char = json.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16);
  }

  async sincronizarItem(item) {
    if (item.status === 'sincronizado') return true;

    try {
      if (!this.ready) {
        throw new Error('Configuração Supabase indisponível para sincronização');
      }

      item.tentativas++;
      item.status = 'sincronizando';
      this.notificarStatusSync();

      const checksumAtual = this.calcularChecksum(item.dados);
      if (checksumAtual !== item.checksum) {
        throw new Error('Checksum inválido: dados foram corrompidos');
      }

      const { _method, _id, ...dadosLimpos } = item.dados;
      const metodo = _method || 'POST';
      const id = _id || null;

      let response;
      if (metodo === 'DELETE') {
        response = await fetch(`${this.supabaseUrl}/rest/v1/${item.tipo}?id=eq.${id}`, {
          method: 'DELETE',
          headers: { ...this.supabaseHeaders, 'Prefer': 'return=minimal' }
        });
      } else if (metodo === 'PATCH' && id) {
        response = await fetch(`${this.supabaseUrl}/rest/v1/${item.tipo}?id=eq.${id}`, {
          method: 'PATCH',
          headers: { ...this.supabaseHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify(dadosLimpos)
        });
      } else {
        response = await fetch(`${this.supabaseUrl}/rest/v1/${item.tipo}`, {
          method: 'POST',
          headers: { ...this.supabaseHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify(dadosLimpos)
        });
      }

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ message: response.statusText }));
        throw new Error(errorData.message || 'Erro na operação de sincronização');
      }

      item.status = 'sincronizado';
      item.ultimoErro = null;
      this.tentativas[item.id] = 0;

      this.log('info', 'sync:item:ok', { itemId: item.id, tipo: item.tipo, tentativas: item.tentativas });
      if (typeof adicionarAuditLog === 'function') {
        adicionarAuditLog('Sincronização', 'Sucesso', { itemId: item.id }, 'sucesso');
      }

      return true;
    } catch (error) {
      item.ultimoErro = error.message;
      item.status = 'erro';
      this.ultimoErro = error.message;

      this.log('error', 'sync:item:fail', { itemId: item.id, tipo: item.tipo, tentativas: item.tentativas, message: error.message });
      if (typeof adicionarAuditLog === 'function') {
        adicionarAuditLog('Sincronização', 'Falha', { itemId: item.id }, 'falha', error.message);
      }

      if (this.deveRetentar(error)) {
        return this.agendarRetry(item);
      } else {
        item.status = 'erro_permanente';
        return false;
      }
    }
  }

  deveRetentar(error) {
    const mensagem = error.message.toLowerCase();
    const errosTemporarios = ['network', 'timeout', 'econnrefused', 'enotfound', 'temporarily unavailable', 'too many requests'];
    return errosTemporarios.some(e => mensagem.includes(e));
  }

  agendarRetry(item) {
    if (item.tentativas >= this.maxTentativas) {
      this.log('warn', 'sync:item:max-retry', { itemId: item.id, tentativas: item.tentativas });
      return false;
    }

    const delay = Math.min(this.backoffInicial * Math.pow(2, item.tentativas - 1), this.maxBackoff);
    this.log('warn', 'sync:item:retry-scheduled', { itemId: item.id, delayMs: delay, tentativas: item.tentativas, maxTentativas: this.maxTentativas });

    setTimeout(() => {
      this.sincronizarItem(item).then(() => {
        this.salvarFilaNoStorage();
        this.notificarStatusSync();
      });
    }, delay);

    return true;
  }

  async sincronizarFila() {
    if (this.statusSync === 'sincronizando') {
      this.log('info', 'sync:queue:skip-already-running');
      return;
    }

    if (!this.ready) {
      this.statusSync = 'degradado';
      this.ultimoErro = 'Configuração Supabase indisponível';
      this.notificarStatusSync();
      this.log('warn', 'sync:queue:backend-unavailable', { source: this.configSource, hasUrl: !!this.supabaseUrl, hasHeaders: !!Object.keys(this.supabaseHeaders || {}).length });
      return false;
    }

    this.statusSync = 'sincronizando';
    this.notificarStatusSync();

    const itemsPendentes = this.filaSync.filter(i => i.status === 'pendente');

    if (itemsPendentes.length === 0) {
      this.statusSync = 'ocioso';
      this.notificarStatusSync();
      return;
    }

    this.log('info', 'sync:queue:start', { pendentes: itemsPendentes.length });

    for (const item of itemsPendentes) {
      await this.sincronizarItem(item);
      this.salvarFilaNoStorage();
    }

    this.statusSync = 'ocioso';
    this.notificarStatusSync();

    const itemsSincronizados = this.filaSync.filter(i => i.status === 'sincronizado').length;
    if (itemsSincronizados > 0) {
      if (typeof showToast === 'function') {
        this.notify(`${itemsSincronizados} item(ns) sincronizado(s) com sucesso`, 'ok');
      }
    }
    return true;
  }

  salvarFilaNoStorage() {
    try {
      localStorage.setItem('_ro_sync_fila', JSON.stringify(this.filaSync));
    } catch (error) {
      this.log('error', 'sync:storage:save-fail', { message: error.message || String(error) });
    }
  }

  carregarFilaDoStorage() {
    try {
      const filaArmazenada = localStorage.getItem('_ro_sync_fila');
      if (filaArmazenada) {
        this.filaSync = JSON.parse(filaArmazenada);
        this.log('info', 'sync:storage:load-ok', { total: this.filaSync.length });
      }
    } catch (error) {
      this.log('error', 'sync:storage:load-fail', { message: error.message || String(error) });
    }
  }

  notificarStatusSync() {
    const stats = {
      total: this.filaSync.length,
      pendentes: this.filaSync.filter(i => i.status === 'pendente').length,
      sincronizando: this.filaSync.filter(i => i.status === 'sincronizando').length,
      sincronizados: this.filaSync.filter(i => i.status === 'sincronizado').length,
      erros: this.filaSync.filter(i => i.status === 'erro' || i.status === 'erro_permanente').length,
      status: this.statusSync,
      ready: this.ready,
      configSource: this.configSource
    };

    const badge = document.getElementById('sync-queue-badge');
    if (badge) {
      badge.textContent = stats.pendentes > 0 ? `Fila sync: ${stats.pendentes}` : '';
      badge.style.display = stats.pendentes > 0 ? 'block' : 'none';
    }

    window.dispatchEvent(new CustomEvent('syncStatusChanged', { detail: stats }));
  }

  obterStatus() {
    return {
      fila: this.filaSync,
      statusGeral: this.statusSync,
      ultimoErro: this.ultimoErro,
      ready: this.ready,
      configSource: this.configSource
    };
  }

  limparFilaSincronizados() {
    this.filaSync = this.filaSync.filter(i => i.status !== 'sincronizado');
    this.salvarFilaNoStorage();
    this.notificarStatusSync();
  }

  forcarRetryErros() {
    const itensComErro = this.filaSync.filter(i => i.status === 'erro' || i.status === 'erro_permanente');
    itensComErro.forEach(item => {
      item.status = 'pendente';
      item.tentativas = 0;
    });
    this.salvarFilaNoStorage();
    this.sincronizarFila();
  }
}

let sincronizador = null;

function inicializarSincronizador(config = {}) {
  sincronizador = new SincronizadorRobusto(config);
  sincronizador.carregarFilaDoStorage();
  sincronizador.notificarStatusSync();
  window.sincronizador = sincronizador;

  setInterval(() => {
    if (sincronizador.statusSync === 'ocioso' && sincronizador.filaSync.some(i => i.status === 'pendente')) {
      sincronizador.sincronizarFila();
    }
  }, 30000);

  window.addEventListener('online', () => {
    sincronizador.log('info', 'sync:network:online');
    if (sincronizador.ready) {
      sincronizador.notify('Conexão restaurada, sincronizando dados...', 'info');
      sincronizador.sincronizarFila();
    } else {
      sincronizador.notify('Conexão restaurada, mas o backend de sincronização ainda está indisponível.', 'warning');
    }
  });

  sincronizador.log('info', 'sync:init', {
    ready: sincronizador.ready,
    source: sincronizador.configSource,
    pendingItems: sincronizador.filaSync.filter(i => i.status === 'pendente').length
  });

  return sincronizador;
}

async function salvarComSincronizacao(tipo, dados, method, id, onSuccess, onError) {
  if (!sincronizador) {
    if (onError) onError(new Error('Sincronizador não inicializado'));
    throw new Error('Sincronizador não inicializado');
  }

  try {
    const dadosComMetadata = { ...dados, _method: method, _id: id };
    const itemId = sincronizador.adicionarAFila(tipo, dadosComMetadata);
    await sincronizador.sincronizarFila();
    if (onSuccess) onSuccess();
    return itemId;
  } catch (error) {
    if (onError) onError(error);
    else throw error;
  }
}

function obterDiagnosticoSincronizacao() {
  return sincronizador ? sincronizador.obterStatus() : { statusGeral: 'nao_inicializado', ready: false };
}
