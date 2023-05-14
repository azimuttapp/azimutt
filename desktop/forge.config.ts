import {MakerDeb} from '@electron-forge/maker-deb';
import {MakerRpm} from '@electron-forge/maker-rpm';
import {MakerSquirrel} from '@electron-forge/maker-squirrel';
import {MakerZIP} from '@electron-forge/maker-zip';
import {WebpackPlugin} from '@electron-forge/plugin-webpack';
import PublisherGithub from "@electron-forge/publisher-github";
import type {ForgeConfig} from '@electron-forge/shared-types';
import {mainConfig} from './webpack.main.config';
import {rendererConfig} from './webpack.renderer.config';

// TODO: https://www.electronforge.io/guides/code-signing
// TODO: https://www.electronjs.org/docs/latest/tutorial/tutorial-packaging#important-signing-your-code
// TODO: see https://github.com/electron/fiddle/tree/fc906d7049f1e173c488fa53972d6db868132e84/.github/workflows for github workflow publish
const config: ForgeConfig = {
    rebuildConfig: {},
    plugins: [
        new WebpackPlugin({
            mainConfig,
            renderer: {
                config: rendererConfig,
                entryPoints: [
                    {
                        html: './src/renderer/index.html',
                        js: './src/renderer/index.ts',
                        name: 'main_window',
                        preload: {
                            js: './src/preload.ts',
                        },
                    },
                ],
            },
        }),
    ],
    packagerConfig: {
        /* osxSign: {},
        osxNotarize: {
            tool: 'notarytool',
            appleId: process.env.APPLE_ID,
            appleIdPassword: process.env.APPLE_PASSWORD,
            teamId: process.env.APPLE_TEAM_ID,
        } */
    },
    makers: [
        new MakerSquirrel({
            /* certificateFile: './cert.pfx',
            certificatePassword: process.env.CERTIFICATE_PASSWORD */
        }),
        new MakerZIP({}, ['darwin']),
        new MakerRpm({}),
        new MakerDeb({})
    ],
    publishers: [
        new PublisherGithub({
            repository: {owner: 'azimuttapp', name: 'azimutt'},
            prerelease: true,
            draft: true,
        })
    ]
};

export default config;
