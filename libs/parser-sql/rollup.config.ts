import commonjs from "@rollup/plugin-commonjs"
import terser from "@rollup/plugin-terser"
import json from "@rollup/plugin-json"
import typescript from "@rollup/plugin-typescript"
import resolve from "@rollup/plugin-node-resolve"

// used to generate a min file to be used in backend/lib/azimutt_web/templates/website/_converter-editors-script.html.heex
export default {
    input: 'src/index.ts',
    output: [{
        file: 'out/bundle.js',
        format: 'cjs',
        sourcemap: true,
    }, {
        file: 'out/bundle.min.js',
        format: 'iife',
        sourcemap: true,
        name: 'sql',
        plugins: [terser()],
    }],
    plugins: [
        resolve(),
        commonjs(),
        json(),
        typescript(),
    ]
}
