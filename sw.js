const CACHE_NAME = 'rede-optica-mg-v7';
const ASSETS = [
  './',
  './index.html',
  './mapa-rede-optica.html',
  './dashboard.html',
  './auditoria-revisao.html',
  './ia-assistente.html',
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
    )).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  // Ignora chamadas para o Supabase (dinâmicas)
  if (event.request.url.includes('supabase.co')) {
    return;
  }
  if (event.request.method !== 'GET') {
    return;
  }

  const url = new URL(event.request.url);
  const isSameOrigin = url.origin === self.location.origin;
  const isHtmlRequest =
    event.request.mode === 'navigate' ||
    event.request.destination === 'document' ||
    (isSameOrigin && (url.pathname.endsWith('.html') || url.pathname === '/' || url.pathname.endsWith('/')));

  if (isHtmlRequest) {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          if (response && response.ok) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy)).catch(() => {});
          }
          return response;
        })
        .catch(async () => {
          const cachedResponse = await caches.match(event.request);
          if (cachedResponse) return cachedResponse;
          return caches.match('./mapa-rede-optica.html');
        })
    );
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then(async cachedResponse => {
        if (cachedResponse) return cachedResponse;
        const response = await fetch(event.request);
        if (response && response.ok && isSameOrigin) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy)).catch(() => {});
        }
        return response;
      })
  );
});
