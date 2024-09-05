import commonjs from "@rollup/plugin-commonjs"
import terser from "@rollup/plugin-terser"
import json from "@rollup/plugin-json"
import typescript from "@rollup/plugin-typescript"
import resolve from "@rollup/plugin-node-resolve"

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
        name: 'aml',
        plugins: [terser()],
    }],
    plugins: [
        resolve(),
        commonjs(),
        json(),
        typescript(),
    ]
}
