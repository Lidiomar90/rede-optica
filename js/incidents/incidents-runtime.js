(() => {
  const foundation = window.AppFoundation || null;

  function log(level, event, context = {}) {
    if (foundation && typeof foundation.log === 'function') {
      foundation.log(level, event, context);
      return;
    }
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(`[INCIDENTS:${level}] ${event}`, context);
  }

  function readIncidents() {
    return Array.isArray(window.allInc) ? window.allInc : [];
  }

  function summarize(incidents) {
    const rows = Array.isArray(incidents) ? incidents : [];
    return {
      ts: new Date().toISOString(),
      total: rows.length,
      abertos: rows.filter(x => x.status !== 'resolvido').length,
      criticos: rows.filter(x => String(x.severidade || '').toLowerCase() === 'critica').length,
      emAtendimento: rows.filter(x => String(x.status || '').toLowerCase() === 'em_atendimento').length,
      resolvidos: rows.filter(x => String(x.status || '').toLowerCase() === 'resolvido').length
    };
  }

  function wrapAsync(name, fn) {
    if (typeof fn !== 'function') return fn;
    return async function wrappedIncidentFn(...args) {
      log('info', `incidents:${name}:start`, { argsCount: args.length });
      try {
        const result = await fn.apply(this, args);
        const state = summarize(readIncidents());
        window.dispatchEvent(new CustomEvent('incidents:state', { detail: state }));
        log('info', `incidents:${name}:ok`, state);
        return result;
      } catch (error) {
        log('error', `incidents:${name}:fail`, { message: error.message || String(error) });
        throw error;
      }
    };
  }

  function init() {
    if (window.IncidentsRuntime && window.IncidentsRuntime.initialized) {
      return window.IncidentsRuntime;
    }

    if (typeof window.loadIncidentes === 'function') {
      window.loadIncidentes = wrapAsync('load', window.loadIncidentes);
    }
    if (typeof window.resolverInc === 'function') {
      window.resolverInc = wrapAsync('resolve', window.resolverInc);
    }

    const runtime = {
      initialized: true,
      getState() {
        return summarize(readIncidents());
      }
    };

    window.IncidentsRuntime = runtime;
    window.dispatchEvent(new CustomEvent('incidents:state', { detail: runtime.getState() }));
    log('info', 'incidents-runtime:init', runtime.getState());
    return runtime;
  }

  window.initIncidentsRuntime = init;
})();
