const version = 1
const assetsCache = 'azimutt-static'
const assets = [
    '/',
    '/assets/images/education.gif',
    '/assets/images/exploration.gif',
    '/assets/images/closed-door.jpg',
    '/dist/elm.js',
    '/dist/styles.css',
    '/samples/basic.azimutt.json',
    '/samples/basic.json',
    '/samples/basic.sql',
    '/samples/gladys.azimutt.json',
    '/samples/gladys.json',
    '/samples/gladys.sql',
    '/samples/gospeak.azimutt.json',
    '/samples/gospeak.json',
    '/samples/gospeak.sql',
    '/samples/information_schema.sql',
    '/samples/pg_catalog.sql',
    '/samples/postgresql.azimutt.json',
    '/samples/wordpress.azimutt.json',
    '/samples/wordpress.json',
    '/samples/wordpress.sql',
    '/android-chrome-192x192.png',
    '/android-chrome-512x512.png',
    '/apple-touch-icon.png',
    '/browserconfig.xml',
    '/favicon.ico',
    '/favicon-16x16.png',
    '/favicon-32x32.png',
    '/logo.png',
    '/mstile-150x150.png',
    '/safari-pinned-tab.svg',
    '/script.js',
    '/site.webmanifest',
    '/sitemap.xml',
]

self.addEventListener('install', installEvent => {
    // console.log(`Installing V${version}...`, installEvent)
    installEvent.waitUntil(cacheAll(assets))
})

self.addEventListener('activate', activateEvent => {
    // console.log(`V${version} activated!`, activateEvent)
})

self.addEventListener('fetch', fetchEvent => {
    // console.log(`Fetch in V${version}.`, fetchEvent)
    const request = fetchEvent.request
    if (request.method === 'GET') {
        fetchAndUpdateCache(fetchEvent, request)
    }
})

function cacheAll(urls) {
    return caches.open(assetsCache).then(cache => cache.addAll(urls))
}

function fetchAndUpdateCache(fetchEvent, request) {
    fetchEvent.respondWith(
        caches.open(assetsCache).then(cache =>
            fetch(request)
                .then(response => {
                    cache.put(request, response.clone())
                    return response
                })
                .catch(err => cache.match(request).then(response => response || Promise.reject(err)))
        )
    )
}

function getFromCacheThenUpdateCache(fetchEvent, request) {
    fetchEvent.respondWith(getFromCache(request).catch(err => {
        console.warn(err)
        return fetch(request)
    }))
    fetchEvent.waitUntil(updateCache(request))
}

function getFromCache(request) {
    return caches.open(assetsCache)
        .then(cache => cache.match(request))
        .then(response => response || Promise.reject(new Error(`service worker cache miss for ${request.method} ${request.url}`)))
}

function updateCache(request) {
    return fetch(request).then(response =>
        caches.open(assetsCache).then(cache =>
            cache.put(request, response)
        )
    )
}
