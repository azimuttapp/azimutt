import {describe, expect, test} from "@jest/globals";
import {
    Database,
    databaseFromLegacy,
    databaseToLegacy,
    Entity,
    LegacyDatabase,
    LegacyRelation,
    LegacyTable,
    Relation
} from "../index";

describe('legacyDatabase', () => {
    describe('migrate', () => {
        test('empty', () => {
            const db: Database = {}
            const ldb: LegacyDatabase = {tables: [], relations: []}
            expect(databaseToLegacy(db)).toEqual(ldb)
            expect(databaseFromLegacy(ldb)).toEqual(db)
        })
        test('basic', () => {
            const db: Database = {
                entities: [
                    {schema: 'public', name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                    {schema: 'public', name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'status', type: 'post_status'}, {name: 'author', type: 'uuid'}]},
                ],
                relations: [
                    {name: 'posts_author', src: {schema: 'public', entity: 'posts'}, ref: {schema: 'public', entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
                ],
                types: [
                    {schema: 'public', name: 'post_status', values: ['draft', 'published', 'archived']},
                    {schema: 'public', name: 'position', definition: '{x: int, y: int}}'},
                ]
            }
            const ldb: LegacyDatabase = {
                tables: [
                    {schema: 'public', table: 'users', columns: [{name: 'id', type: 'uuid'}]},
                    {schema: 'public', table: 'posts', columns: [{name: 'id', type: 'uuid'}, {name: 'status', type: 'post_status'}, {name: 'author', type: 'uuid'}]},
                ],
                relations: [
                    {name: 'posts_author', src: {schema: 'public', table: 'posts', column: 'author'}, ref: {schema: 'public', table: 'users', column: 'id'}},
                ],
                types: [
                    {schema: 'public', name: 'post_status', values: ['draft', 'published', 'archived']},
                    {schema: 'public', name: 'position', definition: '{x: int, y: int}}'},
                ]
            }
            expect(databaseToLegacy(db)).toEqual(ldb)
            expect(databaseFromLegacy(ldb)).toEqual(db)
        })
        test('complex', () => {
            const usersEntity: Entity = {schema: 'public', name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
            const usersTable: LegacyTable = {schema: 'public', table: 'users', columns: [{name: 'id', type: 'uuid'}]}
            const projectsEntity: Entity = {schema: 'public', name: 'projects', attrs: [{name: 'id', type: 'uuid'}, {name: 'created_by', type: 'uuid'}]}
            const projectsTable: LegacyTable = {schema: 'public', table: 'projects', columns: [{name: 'id', type: 'uuid'}, {name: 'created_by', type: 'uuid'}]}
            const eventsEntity: Entity = {
                name: 'events',
                attrs: [
                    {name: 'id', type: 'uuid', default: 'uuid()'},
                    {name: 'name', type: 'varchar', stats: {distinctValues: ['open_app', 'close_app']}},
                    {name: 'created_at', type: 'timestamp', doc: 'in millis'},
                    {name: 'created_by', type: 'uuid', null: true},
                    {name: 'details', type: 'json', attrs: [
                        {name: 'project_id', type: 'uuid'},
                    ]},
                ],
                pk: {name: 'events_pk', attrs: [['id']]},
                indexes: [{name: 'events_no_dup', unique: true, attrs: [['created_at'], ['created_by']]}, {attrs: [['created_at']]}],
                checks: [{attrs: [['name']], predicate: 'len(name) > 3'}],
                doc: 'store user events'
            }
            const eventsTable: LegacyTable = {
                schema: '',
                table: 'events',
                columns: [
                    {name: 'id', type: 'uuid', default: 'uuid()'},
                    {name: 'name', type: 'varchar', values: ['open_app', 'close_app']},
                    {name: 'created_at', type: 'timestamp', comment: 'in millis'},
                    {name: 'created_by', type: 'uuid', nullable: true},
                    {name: 'details', type: 'json', columns: [
                        {name: 'project_id', type: 'uuid'},
                    ]},
                ],
                primaryKey: {name: 'events_pk', columns: ['id']},
                uniques: [{name: 'events_no_dup', columns: ['created_at', 'created_by']}],
                indexes: [{columns: ['created_at']}],
                checks: [{columns: ['name'], predicate: 'len(name) > 3'}],
                comment: 'store user events'
            }
            const userEventsEntity: Entity = {
                name: 'user_events',
                kind: 'view',
                attrs: [
                    {name: 'id', type: 'uuid'},
                ]
            }
            const userEventsTable: LegacyTable = {
                schema: '',
                table: 'user_events',
                view: true,
                columns: [
                    {name: 'id', type: 'uuid'},
                ]
            }
            const projectsCreatorRel: Relation = {name: 'projects_created_by', src: {schema: 'public', entity: 'projects'}, ref: {schema: 'public', entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]}
            const projectsCreatorFk: LegacyRelation = {name: 'projects_created_by', src: {schema: 'public', table: 'projects', column: 'created_by'}, ref: {schema: 'public', table: 'users', column: 'id'}}
            const eventsProjectRel: Relation = {src: {schema: 'public', entity: 'events'}, ref: {schema: 'public', entity: 'projects'}, attrs: [{src: ['details', 'project_id'], ref: ['id']}]}
            const eventsProjectFk: LegacyRelation = {name: '', src: {schema: 'public', table: 'events', column: 'details:project_id'}, ref: {schema: 'public', table: 'projects', column: 'id'}}
            const db: Database = {
                entities: [usersEntity, projectsEntity, eventsEntity, userEventsEntity],
                relations: [projectsCreatorRel, eventsProjectRel]
            }
            const ldb: LegacyDatabase = {
                tables: [usersTable, projectsTable, eventsTable, userEventsTable],
                relations: [projectsCreatorFk, eventsProjectFk]
            }
            expect(databaseToLegacy(db)).toEqual(ldb)
            expect(databaseFromLegacy(ldb)).toEqual(db)
        })
        test('with stats', () => {
            const db: Database = {
                entities: [{
                    schema: 'public',
                    name: 'users',
                    kind: 'view',
                    def: 'SELECT * FROM users',
                    attrs: [
                        {name: 'id', type: 'uuid'},
                        {name: 'role', type: 'varchar', stats: {nulls: 0, bytesAvg: 5.2, cardinality: 3, commonValues: [{value: 'guest', freq: 0.7}, {value: 'member', freq: 0.2}, {value: 'admin', freq: 0.1}], histogram: ['guest', 'admin']}},
                    ],
                    stats: {rows: 42, size: 1337, sizeIdx: 42000, scanSeq: 1234, scanIdx: 54934}
                }]
            }
            const ldb: LegacyDatabase = {
                tables: [{
                    schema: 'public',
                    table: 'users',
                    view: true,
                    definition: 'SELECT * FROM users',
                    columns: [
                        {name: 'id', type: 'uuid'},
                        {name: 'role', type: 'varchar', stats: {nulls: 0, bytesAvg: 5.2, cardinality: 3, commonValues: [{value: 'guest', freq: 0.7}, {value: 'member', freq: 0.2}, {value: 'admin', freq: 0.1}], histogram: ['guest', 'admin']}},
                    ],
                    stats: {rows: 42, size: 1337, sizeIdx: 42000, scanSeq: 1234, scanIdx: 54934}
                }],
                relations: []
            }
            expect(databaseToLegacy(db)).toEqual(ldb)
            expect(databaseFromLegacy(ldb)).toEqual(db)
        })
    })
})
