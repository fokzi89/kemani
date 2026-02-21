/// <reference types="@sveltejs/kit" />
import { build, files, version } from '$service-worker';

const CACHE = `cache-${version}`;

const ASSETS = [
    ...build, // the app itself
    ...files  // everything in `static`
];

self.addEventListener('install', (event: any) => {
    // Create a new cache and add all files to it
    async function addFilesToCache() {
        const cache = await caches.open(CACHE);
        await cache.addAll(ASSETS);
    }

    event.waitUntil(addFilesToCache());
});

self.addEventListener('activate', (event: any) => {
    // Remove previous caches
    async function deleteOldCaches() {
        for (const key of await caches.keys()) {
            if (key !== CACHE) await caches.delete(key);
        }
    }

    event.waitUntil(deleteOldCaches());
});

self.addEventListener('fetch', (event: any) => {
    // ignore POST requests etc
    if (event.request.method !== 'GET') return;

    // ignore API requests (important for dynamic ecommerce data)
    if (event.request.url.includes('/api/') || event.request.url.includes('/auth/')) return;

    // ignore dynamic routes that should always be fresh (cart, checkout, orders)
    // Actually, SvelteKit usually handles page data internally, but assets should be cached.
    // Let's implement stale-while-revalidate for pages, cache-first for assets.

    async function respond() {
        const url = new URL(event.request.url);
        const cache = await caches.open(CACHE);

        // serve build assets from cache immediately
        if (ASSETS.includes(url.pathname)) {
            return cache.match(event.request);
        }

        // for everything else, try the network first, but fall back to cache if offline
        try {
            const response = await fetch(event.request);

            if (response.status === 200) {
                cache.put(event.request, response.clone());
            }

            return response;
        } catch {
            return cache.match(event.request);
        }
    }

    event.respondWith(respond());
});
