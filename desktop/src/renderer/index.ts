/**
 * This file will automatically be loaded by webpack and run in the "renderer" context.
 * To learn more about the differences between the "main" and the "renderer" context in
 * Electron, visit:
 *
 * https://electronjs.org/docs/latest/tutorial/process-model
 *
 * By default, Node.js integration in this file is disabled. When enabling Node.js integration
 * in a renderer process, please be aware of potential security implications. You can read
 * more about security risks here:
 *
 * https://electronjs.org/docs/tutorial/security
 *
 * To enable Node.js integration in this file, open up `main.js` and enable the `nodeIntegration`
 * flag:
 *
 * ```
 *  // Create the browser window.
 *  mainWindow = new BrowserWindow({
 *    width: 800,
 *    height: 600,
 *    webPreferences: {
 *      nodeIntegration: true
 *    }
 *  })
 * ```
 */

import './index.css'
import {DesktopBridge} from "@azimutt/shared";

declare global {
    export interface Window {
        desktop: DesktopBridge
    }
}

console.log('👋 This message is being logged by "renderer.js", included via webpack')

const bridge = window.desktop
const versions = bridge.versions
const information = document.getElementById('info')
information.innerText = `Cette application utilise Chrome (v${versions.chrome()}), Node.js (v${versions.node()}), et Electron (v${versions.electron()})`

const dbUrl = 'postgresql://postgres:postgres@localhost:5432/azimutt_dev'

setTimeout(() => {
    bridge.ping()
        .then(res => console.log('ping', res))
        .catch(err => console.error('ping', err))
}, 1000)

setTimeout(() => {
    bridge.queryDatabase(dbUrl, 'SELECT * FROM projects LIMIT 1;')
        .then(res => console.log('queryDatabase', res))
        .catch(err => console.error('queryDatabase', err))
}, 2000)

setTimeout(() => {
    bridge.getDatabaseSchema(dbUrl)
        .then(res => console.log('getDatabaseSchema', res))
        .catch(err => console.error('getDatabaseSchema', err))
}, 3000)

setTimeout(() => {
    bridge.getTableStats(dbUrl, 'public.users')
        .then(res => console.log('getTableStats', res))
        .catch(err => console.error('getTableStats', err))
}, 4000)

setTimeout(() => {
    bridge.getColumnStats(dbUrl, {table: 'public.users', column: 'email'})
        .then(res => console.log('getColumnStats', res))
        .catch(err => console.error('getColumnStats', err))
}, 5000)
