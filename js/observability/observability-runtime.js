(() => {
  const STORAGE_KEY = '_ro_observability_snapshot_v1';

  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  function save(snapshot) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(snapshot));
    } catch {}
  }

  function init() {
    if (window.ObservabilityRuntime && window.ObservabilityRuntime.initialized) {
      return window.ObservabilityRuntime;
    }

    const snapshot = load() || {
      initializedAt: new Date().toISOString(),
      lastHealth: null,
      lastSync: null,
      lastAuth: null,
      recentLogs: []
    };

    function rememberLog(entry) {
      snapshot.recentLogs.push(entry);
      while (snapshot.recentLogs.length > 50) snapshot.recentLogs.shift();
      save(snapshot);
    }

    window.addEventListener('app:health', event => {
      snapshot.lastHealth = event.detail;
      save(snapshot);
    });

    window.addEventListener('syncStatusChanged', event => {
      snapshot.lastSync = event.detail;
      save(snapshot);
    });

    window.addEventListener('auth:state', event => {
      snapshot.lastAuth = event.detail;
      save(snapshot);
    });

    window.addEventListener('app:log', event => {
      rememberLog(event.detail);
    });

    window.ObservabilityRuntime = {
      initialized: true,
      getSnapshot: () => JSON.parse(JSON.stringify(snapshot)),
      clearLogs() {
        snapshot.recentLogs = [];
        save(snapshot);
      }
    };

    return window.ObservabilityRuntime;
  }

  window.initObservabilityRuntime = init;
})();
