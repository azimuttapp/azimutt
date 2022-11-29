const version = 1
const assetsCache = 'azimutt-static'
const assets = [
    '/',
    '/elm/assets/images/education.gif',
    '/elm/assets/images/exploration.gif',
    '/elm/assets/images/closed-door.jpg',
    '/elm/dist/elm.js',
    '/elm/dist/styles.css',
    '/elm/script.js',
    '/elm/styles.css',
    '/android-chrome-192x192.png',
    '/android-chrome-512x512.png',
    '/apple-touch-icon.png',
    '/browserconfig.xml',
    '/favicon.ico',
    '/favicon-16x16.png',
    '/favicon-32x32.png',
    '/images/logo_dark.svg',
    '/images/logo_icon_dark.svg',
    '/images/logo_icon_light.svg',
    '/images/logo_light.svg',
    '/mstile-150x150.png',
    '/safari-pinned-tab.svg',
    '/screenshot.png',
    '/screenshot-complex.png',
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
                    const shouldCache = /^https?:\/\//.test(request.url)
                    shouldCache && cache.put(request, response.clone())
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
