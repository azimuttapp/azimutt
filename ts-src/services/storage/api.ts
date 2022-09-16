import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../../types/project";
import * as Array from "../../utils/array";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'manager'

export interface StorageApi {
    kind: StorageKind
    listProjects: () => Promise<ProjectInfoNoStorage[]>
    loadProject: (id: ProjectId) => Promise<ProjectNoStorage>
    createProject: (id: ProjectId, p: ProjectNoStorage) => Promise<ProjectNoStorage>
    updateProject: (id: ProjectId, p: ProjectNoStorage) => Promise<ProjectNoStorage>
    deleteProject: (id: ProjectId) => Promise<void>
}

export function projectToInfo(id: ProjectId, p: ProjectNoStorage): ProjectInfoNoStorage {
    const stats = computeStats(p)
    return {
        id: id,
        name: p.name,
        tables: stats.nb_tables,
        relations: stats.nb_relations,
        layouts: stats.nb_layouts,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt
    }
}

export interface ProjectStats {
    nb_sources: number
    nb_tables: number
    nb_columns: number
    nb_relations: number
    nb_types: number
    nb_comments: number
    nb_notes: number
    nb_layouts: number
}

export function computeStats(p: ProjectNoStorage): ProjectStats {
    const tables = Array.groupBy(p.sources.flatMap(s => s.tables), t => `${t.schema}.${t.table}`)
    const types = Array.groupBy(p.sources.flatMap(s => s.types || []), t => `${t.schema}.${t.name}`)

    return {
        nb_sources: p.sources.length,
        nb_tables: Object.keys(tables).length,
        nb_columns: Object.values(tables).map(same => Math.max(...same.map(t => t.columns.length))).reduce((acc, cols) => acc + cols, 0),
        nb_relations: p.sources.reduce((acc, source) => acc + source.relations.length, 0),
        nb_types: Object.keys(types).length,
        nb_comments: p.sources.flatMap(s => s.tables.flatMap(t => [t.comment].concat(t.columns.map(c => c.comment)).filter(c => !!c))).length,
        nb_notes: Object.keys(p.notes || {}).length,
        nb_layouts: Object.keys(p.layouts).length
    }
}
