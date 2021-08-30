const version = 1
const assetsCache = 'azimutt-static'
const assets = [
    '/',
    '/samples/basic.json',
    '/samples/gospeak.sql',
    '/samples/wordpress.sql',
    '/android-chrome-192x192.png',
    '/android-chrome-512x512.png',
    '/apple-touch-icon.png',
    '/browserconfig.xml',
    '/favicon.ico',
    '/favicon-16x16.png',
    '/favicon-32x32.png',
    '/index.html',
    '/logo.png',
    '/mstile-150x150.png',
    '/safari-pinned-tab.svg',
    '/screenshot.png',
    '/screenshot-complex.png',
]
// console.log(`Run V${version}...`)

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
        fetchEvent.respondWith(getFromCache(request).catch(err => {
            console.warn(err)
            return fetch(request)
        }))
        fetchEvent.waitUntil(updateCache(request))
    }
})

function cacheAll(urls) {
    return caches.open(assetsCache).then(cache => cache.addAll(urls))
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

function fetchAndUpdateCache(request) {
    return caches.open(assetsCache).then(cache =>
        fetch(request)
            .then(response => {
                cache.put(request, response.clone())
                return response
            })
            .catch(err => cache.match(request).then(response => response || Promise.reject(err)))
    )
}
