const CACHE_NAME = 'poketibia-cache-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/manifest.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.map((k) => (k !== CACHE_NAME ? caches.delete(k) : Promise.resolve())))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  const isAsset = url.pathname.startsWith('/assets/') || url.pathname.endsWith('.js') || url.pathname.endsWith('.css');
  const isImage = ['.png','.jpg','.jpeg','.gif','.webp','.svg'].some(ext => url.pathname.endsWith(ext)) || url.pathname.startsWith('/uploads/');
  event.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req)
        .then((res) => {
          const resClone = res.clone();
          if (isAsset || isImage || url.origin === location.origin) {
            caches.open(CACHE_NAME).then((cache) => cache.put(req, resClone)).catch(() => {});
          }
          return res;
        })
        .catch(() => cached || new Response(null, { status: 504 }));
      return (isAsset || isImage) ? (cached || network) : (cached || network);
    })
  );
});
