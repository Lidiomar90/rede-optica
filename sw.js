const CACHE_NAME = 'rede-optica-mg-v11';
const ASSETS = [
  './',
  './index.html',
  './mapa-rede-optica.html',
  './dashboard.html',
  './auditoria-revisao.html',
  './ia-assistente.html',
  './styles/operational-enterprise.css',
  './js/core/operational-foundation.js',
  './js/auth/auth-runtime.js',
  './js/inventory/inventory-runtime.js',
  './js/incidents/incidents-runtime.js',
  './js/sync/sync-runtime.js',
  './js/observability/observability-runtime.js',
  './sync_robusto_retry.js',
  './tratamento_erros_profissional.js',
  './otimizacao_ux_mobile.js',
  './science_sites_mg.json',
  'https://fonts.googleapis.com/css2?family=Manrope:wght@500;600;700;800&display=swap',
  'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css',
  'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('message', event => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
    ))
  );
});

self.addEventListener('fetch', event => {
  // Ignora chamadas para o Supabase (dinâmicas)
  if (event.request.url.includes('supabase.co')) {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then(cachedResponse => {
        return cachedResponse || fetch(event.request);
      })
  );
});
