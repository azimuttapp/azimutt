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
    queryDatabase: (url: DatabaseUrl, query: string) => ipcRenderer.invoke('queryDatabase', url, query),
    getDatabaseSchema: (url: DatabaseUrl) => ipcRenderer.invoke('getDatabaseSchema', url),
    getTableStats: (url: DatabaseUrl, table: TableId) => ipcRenderer.invoke('getTableStats', url, table),
    getColumnStats: (url: DatabaseUrl, column: ColumnRef) => ipcRenderer.invoke('getColumnStats', url, column)
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
