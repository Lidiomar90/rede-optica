(() => {
  const foundation = window.AppFoundation || null;

  function log(level, event, context = {}) {
    if (foundation && typeof foundation.log === 'function') {
      foundation.log(level, event, context);
      return;
    }
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(`[AUTH:${level}] ${event}`, context);
  }

  function readSession() {
    try {
      return typeof window.sessao !== 'undefined' ? window.sessao : null;
    } catch {
      return null;
    }
  }

  function readBackendState() {
    try {
      return typeof window.userBackendState !== 'undefined' ? window.userBackendState : null;
    } catch {
      return null;
    }
  }

  const state = {
    status: 'idle',
    lastAttemptAt: null,
    lastSuccessAt: null,
    lastError: null,
    backendState: readBackendState(),
    session: readSession()
  };

  function update(partial = {}) {
    Object.assign(state, partial, {
      backendState: readBackendState(),
      session: readSession()
    });
    window.dispatchEvent(new CustomEvent('auth:state', { detail: { ...state } }));
  }

  function wrapAsync(name, fn, hooks) {
    if (typeof fn !== 'function') return fn;
    return async function wrappedAuthFunction(...args) {
      try {
        if (hooks && typeof hooks.before === 'function') hooks.before(args);
        const result = await fn.apply(this, args);
        if (hooks && typeof hooks.after === 'function') hooks.after(args, result);
        return result;
      } catch (error) {
        if (hooks && typeof hooks.fail === 'function') hooks.fail(args, error);
        throw error;
      }
    };
  }

  function deriveLoginError() {
    const el = document.getElementById('lerr');
    return el ? (el.textContent || '').trim() : '';
  }

  function init() {
    if (window.AuthRuntime && window.AuthRuntime.initialized) {
      return window.AuthRuntime;
    }

    const originalLogin = window.login;
    const originalProbe = window.probeUserBackend;
    const originalLogout = window.logout;

    if (typeof originalLogin === 'function') {
      window.login = wrapAsync('login', originalLogin, {
        before() {
          update({
            status: 'authenticating',
            lastAttemptAt: new Date().toISOString(),
            lastError: null
          });
          log('info', 'auth:login:start');
        },
        after() {
          const sessao = readSession();
          const loginError = deriveLoginError();
          if (sessao && !loginError) {
            update({
              status: 'authenticated',
              lastSuccessAt: new Date().toISOString(),
              lastError: null
            });
            log('info', 'auth:login:success', { email: sessao.email || null, perfil: sessao.perfil || null });
          } else {
            update({
              status: 'rejected',
              lastError: loginError || 'Login rejeitado'
            });
            log('warn', 'auth:login:rejected', { message: loginError || 'Login rejeitado' });
          }
        },
        fail(_args, error) {
          update({
            status: 'failed',
            lastError: error.message || String(error)
          });
          log('error', 'auth:login:fail', { message: error.message || String(error) });
        }
      });
    }

    if (typeof originalProbe === 'function') {
      window.probeUserBackend = wrapAsync('probeUserBackend', originalProbe, {
        before(args) {
          log('info', 'auth:backend-probe:start', { force: !!args[0] });
        },
        after() {
          update({ backendState: readBackendState() });
          log('info', 'auth:backend-probe:finish', { backendState: readBackendState() });
        },
        fail(_args, error) {
          update({
            backendState: 'error',
            lastError: error.message || String(error)
          });
          log('error', 'auth:backend-probe:fail', { message: error.message || String(error) });
        }
      });
    }

    if (typeof originalLogout === 'function') {
      window.logout = function wrappedLogout(...args) {
        log('info', 'auth:logout:start');
        const result = originalLogout.apply(this, args);
        update({
          status: 'idle',
          session: null,
          lastError: null
        });
        log('info', 'auth:logout:finish');
        return result;
      };
    }

    update({
      status: readSession() ? 'authenticated' : 'idle'
    });

    window.AuthRuntime = {
      initialized: true,
      getState: () => ({ ...state }),
      refresh: () => update({})
    };

    log('info', 'auth:runtime:init', { status: state.status, backendState: state.backendState });
    return window.AuthRuntime;
  }

  window.initAuthRuntime = init;
})();
