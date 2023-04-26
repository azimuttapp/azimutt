// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

import {ColumnRef, DatabaseUrl, ElectronBridge, TableId} from "./shared";

const {contextBridge, ipcRenderer} = require('electron')

contextBridge.exposeInMainWorld('electron', {
    // we can also expose variables, not just functions
    versions: {
        node: () => process.versions.node,
        chrome: () => process.versions.chrome,
        electron: () => process.versions.electron
    },
    ping: () => ipcRenderer.invoke('ping'),
    getDatabaseSchema: (url: DatabaseUrl) => Promise.reject('not implemented'),
    getTableStats: (url: DatabaseUrl, table: TableId) => Promise.reject('not implemented'),
    getColumnStats: (url: DatabaseUrl, column: ColumnRef) => Promise.reject('not implemented'),
    execQuery: (url: DatabaseUrl, query: string) => Promise.reject('not implemented')
} as ElectronBridge)

window.addEventListener('DOMContentLoaded', () => {
    const replaceText = (selector: string, text: string) => {
        const element = document.getElementById(selector)
        if (element) element.innerText = text
    }

    for (const dependency of ['chrome', 'node', 'electron']) {
        replaceText(`${dependency}-version`, process.versions[dependency])
    }
})
