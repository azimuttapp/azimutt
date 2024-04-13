// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

import {
    AttributeRef,
    ConnectorAttributeStats,
    ConnectorEntityStats,
    Database,
    DatabaseQuery,
    DatabaseUrl,
    DesktopBridge,
    EntityRef,
    QueryAnalyze,
    QueryResults
} from "@azimutt/models";

const {contextBridge, ipcRenderer} = require('electron')

contextBridge.exposeInMainWorld('desktop', {
    versions: {
        node: () => process.versions.node,
        chrome: () => process.versions.chrome,
        electron: () => process.versions.electron
    },
    ping: () => ipcRenderer.invoke('ping'),
    getSchema: (url: DatabaseUrl): Promise<Database> => ipcRenderer.invoke('getSchema', url),
    getQueryHistory: (url: DatabaseUrl): Promise<DatabaseQuery[]> => ipcRenderer.invoke('getQueryHistory', url),
    execute: (url: DatabaseUrl, query: string, parameters: any[]): Promise<QueryResults> => ipcRenderer.invoke('execute', url, query, parameters),
    analyze: (url: DatabaseUrl, query: string, parameters: any[]): Promise<QueryAnalyze> => ipcRenderer.invoke('analyze', url, query, parameters),
    getEntityStats: (url: DatabaseUrl, ref: EntityRef): Promise<ConnectorEntityStats> => ipcRenderer.invoke('getEntityStats', url, ref),
    getAttributeStats: (url: DatabaseUrl, ref: AttributeRef): Promise<ConnectorAttributeStats> => ipcRenderer.invoke('getAttributeStats', url, ref),
} as DesktopBridge)

// window.addEventListener('DOMContentLoaded', () => {
//     // code executed on page load
// })
