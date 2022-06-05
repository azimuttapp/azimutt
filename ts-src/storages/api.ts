import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage, Source} from "../types/project";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'supabase' | 'manager'

export interface StorageApi {
    kind: StorageKind
    listProjects: () => Promise<ProjectInfoNoStorage[]>
    loadProject: (id: ProjectId) => Promise<ProjectNoStorage>
    createProject: (p: ProjectNoStorage) => Promise<ProjectNoStorage>
    updateProject: (p: ProjectNoStorage) => Promise<ProjectNoStorage>
    dropProject: (p: ProjectId) => Promise<void>
}

export function projectToInfo(p: ProjectNoStorage): ProjectInfoNoStorage {
    return {
        id: p.id,
        name: p.name,
        tables: computeTables(p.sources),
        relations: computeRelations(p.sources),
        layouts: Object.keys(p.layouts).length,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt
    }
}

export function computeTables(sources: Source[]): number {
    const tableIds = sources.reduce((acc, source) => acc.concat(source.tables.map(t => `${t.schema}.${t.table}`)), [] as string[])
    return new Set(tableIds).size
}

export function computeRelations(sources: Source[]): number {
    return sources.reduce((acc, source) => acc + source.relations.length, 0)
}
