const version = 1
const assetsCache = 'azimutt-static'
const assets = [
    '/',
    '/assets/images/avatar-loic-knuchel.jpg',
    '/assets/images/avatar-oliver-searle-barnes.png',
    '/assets/images/background_hero.jpeg',
    '/assets/images/basic-schema.png',
    '/assets/images/gospeak-find-path.png',
    '/assets/images/gospeak-incoming-relation.png',
    '/assets/images/gospeak-layouts.png',
    '/assets/images/gospeak-schema-full.png',
    '/assets/images/gospeak-schema-light.png',
    '/assets/uuidv4.min.js',
    '/dist/elm.js',
    '/dist/styles.css',
    '/samples/basic.sql',
    '/samples/gospeak.sql',
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
