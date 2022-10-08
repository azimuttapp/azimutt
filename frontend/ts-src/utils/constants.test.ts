import {Organization, Plan, PlanId, PlanName} from "../types/organization";
import {Timestamp} from "../types/basics";
import {Layout, Origin, Project, ProjectStorage, Relation, Source, Table, Type} from "../types/project";

export const uuid = '84547c71-bec5-433b-87c7-685f1c9353b2'
export const now: Timestamp = 1663789596755
export const plan: Plan = {
    id: PlanId.enum.free,
    name: PlanName.enum.free,
    layouts: 3,
    colors: false,
    db_analysis: false,
    db_access: false
}
export const organization: Organization = {
    id: uuid,
    slug: 'valid',
    name: 'Valid',
    plan: plan,
    logo: 'https://azimutt.app/logo.png',
    location: 'Paris',
    description: 'bla bla bla'
}
export const origins: Origin[] = [{id: uuid, lines: [1, 2]}]
export const table: Table = {
    schema: 'public',
    table: 'users',
    view: false,
    columns: [{
        name: 'id',
        type: 'uuid',
        nullable: false,
        default: 'uuid()',
        comment: {text: 'user id', origins},
        origins
    }],
    primaryKey: {name: 'users_pk', columns: ['id'], origins},
    uniques: [{name: 'users_id_unique', columns: ['id'], definition: 'unique id', origins}],
    indexes: [{name: 'user_id_index', columns: ['id'], definition: 'index id', origins}],
    checks: [{name: 'user_id_check', columns: ['id'], predicate: 'id NOT NULL', origins}],
    comment: {text: 'users', origins},
    origins
}
export const relation: Relation = {
    name: 'group_user_id',
    src: {table: 'public.groups', column: 'user_id'},
    ref: {table: 'public.users', column: 'id'},
    origins
}
export const type: Type = {
    schema: 'public',
    name: 'user_role',
    value: {enum: ['guest', 'admin']},
    origins
}
export const source: Source = {
    id: uuid,
    name: 'Source',
    kind: {
        kind: 'SqlLocalFile',
        name: 'structure.sql',
        size: 1000,
        modified: now
    },
    content: ['content line'],
    tables: [table],
    relations: [relation],
    types: [type],
    enabled: true,
    createdAt: now,
    updatedAt: now
}
export const layout: Layout = {
    canvas: {position: {left: 0, top: 0}, zoom: 1},
    tables: [{
        id: 'public.users',
        position: {left: 0, top: 0},
        size: {width: 0, height: 0},
        color: 'red',
        columns: ['id'],
        selected: false,
        collapsed: false
    }],
    createdAt: now,
    updatedAt: now
}
export const project: Project = {
    organization,
    id: uuid,
    slug: 'project',
    name: 'Project',
    description: 'a description',
    sources: [source],
    notes: {'public.users': 'users notes'},
    usedLayout: 'init',
    layouts: {init: layout},
    settings: {removedTables: 'logs'},
    storage: ProjectStorage.enum.local,
    createdAt: now,
    updatedAt: now,
    version: 1
}

describe('constants', () => {
    test('dummy', () => {
    })
})
