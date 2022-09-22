import {
    Layout,
    Origin,
    Project,
    ProjectJson,
    ProjectJsonLegacy,
    ProjectStorage,
    ProjectStoredWithId,
    Relation,
    Source,
    Table,
    Type
} from "./project";
import {Organization, OrganizationPlan} from "./organization";
import {Timestamp} from "./basics";

describe('project', () => {
    const uuid = '84547c71-bec5-433b-87c7-685f1c9353b2'
    const now: Timestamp = 1663789596755
    const organization: Organization = {
        id: uuid,
        slug: 'valid',
        name: 'Valid',
        activePlan: OrganizationPlan.enum.free,
        logo: 'https://azimutt.app/logo.png',
        location: 'Paris',
        description: 'bla bla bla'
    }
    const origins: Origin[] = [{id: uuid, lines: [1, 2]}]
    const table: Table = {
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
    const relation: Relation = {
        name: 'group_user_id',
        src: {table: 'public.groups', column: 'user_id'},
        ref: {table: 'public.users', column: 'id'},
        origins
    }
    const type: Type = {
        schema: 'public',
        name: 'user_role',
        value: {enum: ['guest', 'admin']},
        origins
    }
    const source: Source = {
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
    const layout: Layout = {
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
    const project: Project = {
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
    test('zod full', () => {
        const res: Project = Project.parse(project) // make sure parser result is aligned with TS type!
        expect(res).toEqual(project)
    })
    test('zod empty', () => {
        const {description, notes, settings, ...valid}: Project = {...project}
        const res: Project = Project.parse(valid)
        expect(res).toEqual(valid)
    })
    test('project json', () => {
        const {organization, id, storage, createdAt, updatedAt, ...json} = project
        const valid: ProjectJson = {...json, _type: 'json'}
        const res = ProjectJson.parse(valid)
        expect(res).toEqual(valid)
    })
    test('project json legacy', () => {
        const {organization, slug, description, storage, ...json} = project
        const valid: ProjectJsonLegacy = {...json}
        const res = ProjectJsonLegacy.parse(valid)
        expect(res).toEqual(valid)
    })
    test('project stored with id', () => {
        const {organization, id, storage, createdAt, updatedAt, ...json} = project
        const valid: ProjectStoredWithId = [project.id, {...json, _type: 'json'}]
        const res = ProjectStoredWithId.parse(valid)
        expect(res).toEqual(valid)
    })
    test('zod full', () => {
        const res: Table = Table.parse(table) // make sure parser result is aligned with TS type!
        expect(res).toEqual(table)
    })
    describe('table', () => {
        test('zod full', () => {
            const res: Table = Table.parse(table) // make sure parser result is aligned with TS type!
            expect(res).toEqual(table)
        })
        test('zod empty', () => {
            const {view, primaryKey, uniques, indexes, checks, comment, ...valid}: Table = {...table}
            const res: Table = Table.parse(valid)
            expect(res).toEqual(valid)
        })
        test('zod invalid', () => {
            const {columns, ...invalid} = table
            const res = Table.safeParse(invalid)
            expect(res.success).toEqual(false)
        })
    })
    describe('relation', () => {
        test('zod full', () => {
            const res: Relation = Relation.parse(relation) // make sure parser result is aligned with TS type!
            expect(res).toEqual(relation)
        })
        test('zod invalid', () => {
            const {name, ...invalid} = relation
            const res = Relation.safeParse(invalid)
            expect(res.success).toEqual(false)
        })
    })
    describe('type', () => {
        test('zod full', () => {
            const res: Type = Type.parse(type) // make sure parser result is aligned with TS type!
            expect(res).toEqual(type)
        })
        test('zod value definition', () => {
            const valid: Type = {...type, value: {definition: 'my type'}}
            const res: Type = Type.parse(valid)
            expect(res).toEqual(valid)
        })
        test('zod invalid', () => {
            const {name, ...invalid} = type
            const res = Type.safeParse(invalid)
            expect(res.success).toEqual(false)
        })
    })
    describe('source', () => {
        test('zod full', () => {
            const res: Source = Source.parse(source) // make sure parser result is aligned with TS type!
            expect(res).toEqual(source)
        })
        test('zod empty', () => {
            const {types, enabled, ...valid}: Source = {...source}
            const res: Source = Source.parse(valid)
            expect(res).toEqual(valid)
        })
        test('zod remote source', () => {
            const valid: Source = {
                ...source,
                kind: {kind: 'SqlRemoteFile', url: 'https://azimutt.app/samples/gospeak.sql', size: 1000}
            }
            const res: Source = Source.parse(valid)
            expect(res).toEqual(valid)
        })
        test('zod user source', () => {
            const valid: Source = {...source, kind: {kind: 'AmlEditor'}}
            const res: Source = Source.parse(valid)
            expect(res).toEqual(valid)
        })
        test('zod invalid', () => {
            const {kind, ...invalid} = source
            const res = Source.safeParse(invalid)
            expect(res.success).toEqual(false)
        })
    })
    describe('layout', () => {
        test('zod full', () => {
            const res: Layout = Layout.parse(layout) // make sure parser result is aligned with TS type!
            expect(res).toEqual(layout)
        })
        test('zod invalid', () => {
            const {canvas, ...invalid} = layout
            const res = Layout.safeParse(invalid)
            expect(res.success).toEqual(false)
        })
    })
})
