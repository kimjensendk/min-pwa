const CACHE_NAME = "hotel-sportsbooking-supabase-v1";
const FILES = [
  ".",
  "index.html",
  "manifest.json",
  "icon.svg",
  "config.js"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(FILES))
  );
});

self.addEventListener("fetch", event => {
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request))
  );
});
