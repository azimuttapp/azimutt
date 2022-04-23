#!/usr/bin/env node

import { copy } from 'esbuild-plugin-copy';
import * as esbuild from "esbuild";

esbuild.build({
    entryPoints: ['src/background.ts', 'src/appendButton.ts'],
    bundle: true,
    outdir: 'dist',
    plugins: [
        copy({
            assets: {
                from: ['./public/*', 'manifest.json'],
                to: ['./dist'],
            }
        })
    ]
}).catch(() => process.exit(1));
