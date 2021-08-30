import {defineConfig} from 'vite'
import elmPlugin from 'vite-plugin-elm'

/**
 * Problems:
 *  - some images are not detected and replaced (logo.png in index.html, urls in Elm)
 *  - service-worker is broken (compilation but also asset list)
 *
 * See:
 *  - https://github.com/ryannhg/elm-spa/tree/main/examples/05-vite
 *  - https://vitejs.dev/guide/assets.html#the-public-directory
 *  - https://vitejs.dev/config/#define
 *  - https://vitejs.dev/config/#assetsinclude
 */
export default defineConfig({
    root: 'public',
    plugins: [elmPlugin()],
    build: {
        assetsInlineLimit: 0 // https://vitejs.dev/config/#build-assetsinlinelimit
    }
})
