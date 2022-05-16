import {Project} from "../types/project";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'supabase' | 'manager'

export interface StorageApi {
    kind: StorageKind
    loadProjects: () => Promise<Project[]>
    saveProject: (p: Project) => Promise<void>
    dropProject: (p: Project) => Promise<void>
}
