(() => {
  const foundation = window.AppFoundation || null;

  function log(level, event, context = {}) {
    if (foundation && typeof foundation.log === 'function') {
      foundation.log(level, event, context);
      return;
    }
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(`[SYNC-RUNTIME:${level}] ${event}`, context);
  }

  function init() {
    if (window.SyncRuntime && window.SyncRuntime.initialized) {
      return window.SyncRuntime;
    }

    const runtime = {
      initialized: true,
      lastStatus: null,
      getStatus() {
        try {
          if (typeof obterDiagnosticoSincronizacao === 'function') {
            return obterDiagnosticoSincronizacao();
          }
        } catch {}
        return runtime.lastStatus || { statusGeral: 'desconhecido', ready: false };
      }
    };

    window.addEventListener('syncStatusChanged', event => {
      runtime.lastStatus = event.detail;
      const badge = document.getElementById('sync-queue-badge');
      if (!badge) return;

      const detail = event.detail || {};
      const pendentes = detail.pendentes || 0;
      const erros = detail.erros || 0;
      const ready = typeof detail.ready === 'boolean' ? detail.ready : true;

      if (!ready) {
        badge.textContent = 'Sync degradado';
        badge.style.display = 'block';
        return;
      }

      if (erros > 0) {
        badge.textContent = `Sync erro: ${erros}`;
        badge.style.display = 'block';
        return;
      }

      if (pendentes > 0) {
        badge.textContent = `Fila sync: ${pendentes}`;
        badge.style.display = 'block';
        return;
      }

      badge.textContent = '';
      badge.style.display = 'none';
    });

    log('info', 'sync-runtime:init');
    window.SyncRuntime = runtime;
    return runtime;
  }

  window.initSyncRuntime = init;
})();
