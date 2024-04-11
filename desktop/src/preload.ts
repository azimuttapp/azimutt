// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

import {
    AttributeRef,
    ConnectorAttributeStats,
    ConnectorEntityStats,
    Database,
    DatabaseQuery,
    DatabaseUrlParsed,
    DesktopBridge,
    EntityRef,
    QueryAnalyze,
    QueryResults
} from "@azimutt/database-model";

const {contextBridge, ipcRenderer} = require('electron')

contextBridge.exposeInMainWorld('desktop', {
    versions: {
        node: () => process.versions.node,
        chrome: () => process.versions.chrome,
        electron: () => process.versions.electron
    },
    ping: () => ipcRenderer.invoke('ping'),
    getSchema: (url: DatabaseUrlParsed): Promise<Database> => ipcRenderer.invoke('getSchema', url),
    getQueryHistory: (url: DatabaseUrlParsed): Promise<DatabaseQuery[]> => ipcRenderer.invoke('getQueryHistory', url),
    execute: (url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryResults> => ipcRenderer.invoke('execute', url, query, parameters),
    analyze: (url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryAnalyze> => ipcRenderer.invoke('analyze', url, query, parameters),
    getEntityStats: (url: DatabaseUrlParsed, ref: EntityRef): Promise<ConnectorEntityStats> => ipcRenderer.invoke('getEntityStats', url, ref),
    getAttributeStats: (url: DatabaseUrlParsed, ref: AttributeRef): Promise<ConnectorAttributeStats> => ipcRenderer.invoke('getAttributeStats', url, ref),
} as DesktopBridge)

// window.addEventListener('DOMContentLoaded', () => {
//     // code executed on page load
// })
