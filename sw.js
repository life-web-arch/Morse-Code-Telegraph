self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);
    
    // Intercept the OS share action
    if (event.request.method === 'POST' && url.pathname === '/_share-audio') {
        event.respondWith((async () => {
            try {
                const formData = await event.request.formData();
                const file = formData.get('audioFile');
                
                if (file) {
                    // Temporarily store the shared file in the Cache API
                    const cache = await caches.open('shared-audio-cache');
                    await cache.put('/shared-file', new Response(file, {
                        headers: {
                            'content-type': file.type || 'application/octet-stream',
                            'content-length': file.size
                        }
                    }));
                }
                // Redirect into the app with a flag to let it know a file is waiting
                return Response.redirect('/?shared=1', 303);
            } catch (err) {
                console.error("Share target processing failed", err);
                return Response.redirect('/', 303);
            }
        })());
    }
});
