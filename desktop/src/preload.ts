// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

import {ColumnRef, DatabaseUrl, TableId} from "@azimutt/database-types";
import {DesktopBridge} from "@azimutt/shared";

const {contextBridge, ipcRenderer} = require('electron')

contextBridge.exposeInMainWorld('desktop', {
    // we can also expose variables, not just functions
    versions: {
        node: () => process.versions.node,
        chrome: () => process.versions.chrome,
        electron: () => process.versions.electron
    },
    ping: () => ipcRenderer.invoke('ping'),
    databaseQuery: (url: DatabaseUrl, query: string) => ipcRenderer.invoke('databaseQuery', url, query),
    databaseSchema: (url: DatabaseUrl) => Promise.reject('not implemented'),
    tableStats: (url: DatabaseUrl, table: TableId) => Promise.reject('not implemented'),
    columnStats: (url: DatabaseUrl, column: ColumnRef) => Promise.reject('not implemented')
} as DesktopBridge)

window.addEventListener('DOMContentLoaded', () => {
    const replaceText = (selector: string, text: string) => {
        const element = document.getElementById(selector)
        if (element) element.innerText = text
    }

    for (const dependency of ['chrome', 'node', 'electron']) {
        replaceText(`${dependency}-version`, process.versions[dependency])
    }
})
