import {LegacyProjectId, LegacyProjectJson} from "@azimutt/models";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'manager'

export interface StorageApi {
    kind: StorageKind
    loadProject: (id: LegacyProjectId) => Promise<LegacyProjectJson>
    createProject: (id: LegacyProjectId, p: LegacyProjectJson) => Promise<LegacyProjectJson>
    updateProject: (id: LegacyProjectId, p: LegacyProjectJson) => Promise<LegacyProjectJson>
    deleteProject: (id: LegacyProjectId) => Promise<void>
}
