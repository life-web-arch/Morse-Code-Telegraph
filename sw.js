// sw.js

const CACHE_NAME = 'morse-telegraph-v1';

self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // 1. Handle the Share Target (POST)
    if (event.request.method === 'POST' && url.pathname === '/_share-audio') {
        event.respondWith((async () => {
            try {
                const formData = await event.request.formData();
                const file = formData.get('audioFile');
                
                if (file) {
                    const cache = await caches.open('shared-audio-cache');
                    await cache.put('/shared-file', new Response(file, {
                        headers: {
                            'content-type': file.type || 'application/octet-stream',
                            'content-length': file.size
                        }
                    }));
                }
                return Response.redirect('/?shared=1', 303);
            } catch (err) {
                console.error("Share target failed", err);
                return Response.redirect('/', 303);
            }
        })());
        return; // Important: Stop execution here for share targets
    }

    // 2. CRITICAL FIX: Handle normal requests
    // Without this, the browser thinks your page is broken, so it blocks installation.
    event.respondWith(
        fetch(event.request).catch(() => {
            // Optional: You could return a custom offline page here
            return caches.match(event.request); 
        })
    );
});
