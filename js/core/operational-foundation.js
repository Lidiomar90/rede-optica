(() => {
  const LOG_KEY = '_ro_front_logs_v1';
  const MAX_LOGS = 300;
  const HEALTH_KEY = '_ro_health_last_v1';

  function nowIso() {
    return new Date().toISOString();
  }

  function has(name) {
    try {
      return typeof globalThis[name] !== 'undefined';
    } catch {
      return false;
    }
  }

  function getValue(name, fallback = null) {
    try {
      return has(name) ? globalThis[name] : fallback;
    } catch {
      return fallback;
    }
  }

  function loadJson(key, fallback) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch {
      return fallback;
    }
  }

  function saveJson(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch {
      return false;
    }
  }

  function normalizeTone(tone = 'info') {
    const map = {
      info: 'in',
      warning: 'wn',
      warn: 'wn',
      error: 'er',
      danger: 'er',
      success: 'ok',
      ok: 'ok'
    };
    return map[String(tone).toLowerCase()] || 'in';
  }

  function appendLog(entry) {
    const existing = loadJson(LOG_KEY, []);
    existing.push(entry);
    while (existing.length > MAX_LOGS) existing.shift();
    saveJson(LOG_KEY, existing);
  }

  function resolveSupabaseConfig() {
    const url = getValue('SU', '');
    const writeHeaders = getValue('WH', null);
    const readHeaders = getValue('RH', null);
    const activeHeaders = writeHeaders || readHeaders || {};
    return {
      ok: !!(url && activeHeaders && Object.keys(activeHeaders).length),
      url,
      headers: activeHeaders,
      writeHeaders: writeHeaders || {},
      readHeaders: readHeaders || {},
      source: writeHeaders ? 'WH' : (readHeaders ? 'RH' : 'none')
    };
  }

  function log(level, event, context = {}) {
    const entry = {
      ts: nowIso(),
      level: String(level || 'info').toLowerCase(),
      event,
      context,
      href: location.href,
      online: navigator.onLine,
      session: (() => {
        const sess = getValue('sessao', null);
        if (!sess) return null;
        return {
          email: sess.email || null,
          perfil: sess.perfil || null
        };
      })()
    };
    appendLog(entry);
    const fn = entry.level === 'error' ? console.error : entry.level === 'warn' ? console.warn : console.log;
    fn(`[APP:${entry.level}] ${event}`, context);
    window.dispatchEvent(new CustomEvent('app:log', { detail: entry }));
    return entry;
  }

  function notify(message, tone = 'info') {
    if (typeof globalThis.toast === 'function') {
      globalThis.toast(message, normalizeTone(tone));
      return;
    }
    console.log(`[notify:${tone}] ${message}`);
  }

  function audit(action, status, context = {}, severity = 'info', details = '') {
    const payload = {
      action,
      status,
      severity,
      details,
      context,
      timestamp: nowIso()
    };
    log(severity === 'error' ? 'error' : 'info', `audit:${action}:${status}`, payload);
    window.dispatchEvent(new CustomEvent('app:audit', { detail: payload }));
    return payload;
  }

  function showSpinner(label = 'Processando...') {
    document.body.dataset.runtimeBusy = '1';
    log('info', 'ui:busy:start', { label });
  }

  function hideSpinner() {
    delete document.body.dataset.runtimeBusy;
    log('info', 'ui:busy:end');
  }

  async function runHealthChecks() {
    const supabase = resolveSupabaseConfig();
    const checks = {
      ts: nowIso(),
      online: navigator.onLine,
      service_worker_supported: 'serviceWorker' in navigator,
      local_storage: (() => {
        try {
          localStorage.setItem('_ro_hc', '1');
          localStorage.removeItem('_ro_hc');
          return true;
        } catch {
          return false;
        }
      })(),
      supabase_configured: supabase.ok,
      supabase_url: supabase.url || null,
      auth_backend_state: typeof getValue('userBackendState', null) !== 'undefined' ? getValue('userBackendState', null) : null
    };
    saveJson(HEALTH_KEY, checks);
    window.dispatchEvent(new CustomEvent('app:health', { detail: checks }));
    return checks;
  }

  function guardedInit(name, initializer) {
    try {
      const result = initializer();
      log('info', `init:${name}:ok`);
      return result;
    } catch (error) {
      log('error', `init:${name}:fail`, { message: error.message || String(error) });
      notify(`Falha ao iniciar ${name}`, 'error');
      return null;
    }
  }

  function ensureLegacyAdapters() {
    if (typeof globalThis.showToast !== 'function') {
      globalThis.showToast = (message, tone) => notify(message, tone);
    }
    if (typeof globalThis.adicionarAuditLog !== 'function') {
      globalThis.adicionarAuditLog = (action, status, context, severity, details) => audit(action, status, context, severity, details);
    }
    if (typeof globalThis.showSpinner !== 'function') {
      globalThis.showSpinner = showSpinner;
    }
    if (typeof globalThis.hideSpinner !== 'function') {
      globalThis.hideSpinner = hideSpinner;
    }
  }

  ensureLegacyAdapters();

  globalThis.AppFoundation = {
    log,
    notify,
    audit,
    showSpinner,
    hideSpinner,
    resolveSupabaseConfig,
    runHealthChecks,
    guardedInit,
    loadLogs: () => loadJson(LOG_KEY, []),
    latestHealth: () => loadJson(HEALTH_KEY, null)
  };

  log('info', 'foundation:ready', { version: '2026.04.11.runtime' });
})();
