import {defineConfig} from "vite";

export default defineConfig({
    build: {
        lib: {
            entry: ['ts-src/index.ts'],
            formats: ['cjs']
        },
        outDir: '../backend/priv/static/elm/ts'
    }
})
