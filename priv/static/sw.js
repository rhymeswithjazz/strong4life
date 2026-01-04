// Service Worker for Strong4Life PWA
// Provides offline caching for basic app functionality

const CACHE_NAME = 'strong4life-v1';
const RUNTIME_CACHE = 'strong4life-runtime';

// Assets to cache on install
const PRECACHE_URLS = [
  '/',
  '/dashboard',
  '/history',
  '/progress',
  '/assets/app.css',
  '/assets/app.js',
  '/manifest.json',
  '/images/icon-192.png',
  '/images/icon-512.png'
];

// Install event - cache essential assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== RUNTIME_CACHE)
          .map((name) => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') {
    return;
  }

  // Skip Phoenix LiveView websocket connections
  if (event.request.url.includes('/live/websocket')) {
    return;
  }

  // Skip API requests that need real-time data
  if (event.request.url.includes('/api/')) {
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request).then((response) => {
        // Don't cache non-successful responses
        if (!response || response.status !== 200 || response.type === 'error') {
          return response;
        }

        // Clone the response
        const responseToCache = response.clone();

        // Cache static assets and pages
        if (
          event.request.url.includes('/assets/') ||
          event.request.url.includes('/images/') ||
          event.request.url.match(/\.(css|js|png|jpg|jpeg|svg|woff|woff2)$/)
        ) {
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        } else {
          // Cache HTML pages in runtime cache
          caches.open(RUNTIME_CACHE).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }

        return response;
      }).catch(() => {
        // If both cache and network fail, show offline page
        if (event.request.mode === 'navigate') {
          return caches.match('/dashboard');
        }
      });
    })
  );
});
