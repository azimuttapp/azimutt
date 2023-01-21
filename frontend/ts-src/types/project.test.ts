import {
    Layout,
    parseTableId,
    Project,
    ProjectJson,
    ProjectJsonLegacy,
    ProjectStoredWithId,
    Relation,
    Source,
    Table,
    Type
} from "./project";
import {layout, project, relation, source, table, type} from "../utils/constants.test";

describe('project', () => {
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
        const {organization, id, storage, visibility, createdAt, updatedAt, ...json} = project
        const valid: ProjectJson = {...json, _type: 'json'}
        const res = ProjectJson.parse(valid)
        expect(res).toEqual(valid)
    })
    test('project json legacy', () => {
        const {organization, slug, description, storage, visibility, ...json} = project
        const valid: ProjectJsonLegacy = {...json}
        const res = ProjectJsonLegacy.parse(valid)
        expect(res).toEqual(valid)
    })
    test('project stored with id', () => {
        const {organization, id, storage, visibility, createdAt, updatedAt, ...json} = project
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
                kind: {kind: 'SqlRemoteFile', url: 'https://azimutt.app/elm/samples/basic.sql', size: 1000}
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
    test('parseTableId should work', () => {
        expect(parseTableId('public.users')).toEqual({schema: 'public', table: 'users'})
        expect(parseTableId('.users')).toEqual({schema: '', table: 'users'})
        expect(parseTableId('users')).toEqual({schema: '', table: 'users'})
        expect(parseTableId('')).toEqual({schema: '', table: ''})
        expect(parseTableId('a.b.c')).toEqual({schema: 'a', table: 'b'})
    })
})
