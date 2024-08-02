import {describe, expect, test} from "@jest/globals";
import {
    AttributeName,
    ConnectorSchemaOpts,
    Database,
    DatabaseUrlParsed,
    EntityId,
    parseDatabaseUrl,
    ValueSchema,
    zodParse
} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {
    buildDatabase,
    getColumns,
    getConstraintColumns,
    getSchema,
    getTables,
    RawColumn,
    RawConstraintColumn,
    RawTable
} from "./mysql";
import {application, logger} from "./constants.test";

describe('mysql', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mysql://azimutt:azimutt@localhost:3306/mysql_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT name, slug FROM users WHERE slug = ?;", ['ghost']), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(7)
    })
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
        expect(tables.length).toEqual(7)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
        expect(columns.length).toEqual(124)
    })
    test.skip('getConstraintColumns', async () => {
        const constraints = await connect(application, url, getConstraintColumns(opts), opts)
        console.log(`${constraints.length} constraints`, constraints)
        expect(constraints.length).toEqual(64)
    })
    test('buildDatabase', () => {
        const date = Date.now()

        const emptyDb = buildDatabase([], {}, {}, {}, {}, {}, {}, [], undefined, date, date)
        expect(zodParse(Database)(emptyDb).getOrThrow()).toEqual({
            stats: {
                kind: 'mysql',
                extractedAt: new Date(date).toISOString(),
                extractionDuration: 0,
            }
        })

        const usersTable: RawTable = {
            table_schema: 'public',
            table_name: 'users',
            table_kind: 'BASE TABLE',
            table_engine: 'InnoDB',
            table_comment: 'List of users',
            table_rows: 12,
            table_size: 156,
            index_size: 35,
            row_size: 42,
            auto_increment_next: null,
            table_options: null,
            table_created_at: null,
            definition: null
        }
        const usersColumns: RawColumn[] = [
            {table_schema: 'public', table_name: 'users', column_index: 1, column_name: 'id', column_type: 'uuid', column_nullable: 'NO', column_default: null, column_comment: 'user id', column_extra: ''},
            {table_schema: 'public', table_name: 'users', column_index: 2, column_name: 'name', column_type: 'varchar', column_nullable: 'NO', column_default: null, column_comment: '', column_extra: ''},
            {table_schema: 'public', table_name: 'users', column_index: 3, column_name: 'role', column_type: 'varchar', column_nullable: 'NO', column_default: 'guest', column_comment: '', column_extra: ''},
        ]
        const eventsTable: RawTable = {
            table_schema: 'public',
            table_name: 'events',
            table_kind: 'BASE TABLE',
            table_engine: 'InnoDB',
            table_comment: '',
            table_rows: null,
            table_size: null,
            index_size: null,
            row_size: null,
            auto_increment_next: null,
            table_options: null,
            table_created_at: null,
            definition: null
        }
        const eventsColumns: RawColumn[] = [
            {table_schema: 'public', table_name: 'events', column_index: 1, column_name: 'id', column_type: 'uuid', column_nullable: 'NO', column_default: null, column_comment: '', column_extra: ''},
            {table_schema: 'public', table_name: 'events', column_index: 2, column_name: 'name', column_type: 'varchar', column_nullable: 'NO', column_default: null, column_comment: '', column_extra: ''},
            {table_schema: 'public', table_name: 'events', column_index: 3, column_name: 'item_id', column_type: 'uuid', column_nullable: 'YES', column_default: null, column_comment: '', column_extra: ''},
            {table_schema: 'public', table_name: 'events', column_index: 4, column_name: 'item_kind', column_type: 'varchar', column_nullable: 'YES', column_default: null, column_comment: '', column_extra: ''},
            {table_schema: 'public', table_name: 'events', column_index: 5, column_name: 'details', column_type: 'json', column_nullable: 'YES', column_default: null, column_comment: '', column_extra: ''},
            {table_schema: 'public', table_name: 'events', column_index: 6, column_name: 'created_by', column_type: 'uuid', column_nullable: 'NO', column_default: null, column_comment: '', column_extra: ''},
        ]
        const eventsCreatedByFK: RawConstraintColumn[] = [
            {constraint_name: '', constraint_type: 'FOREIGN KEY', table_schema: 'public', table_name: 'events', column_index: 6, column_name: 'created_by', column_expr: null, ref_schema: 'public', ref_table: 'users', ref_column: 'id'}
        ]
        const primaryKeys: Record<EntityId, RawConstraintColumn[]> = {
            'public.users': [{constraint_name: 'PRIMARY', constraint_type: 'PRIMARY KEY', table_schema: 'public', table_name: 'users', column_index: 1, column_name: 'id', column_expr: null, ref_schema: null, ref_table: null, ref_column: null}],
            'public.events': [{constraint_name: 'events_pk', constraint_type: 'PRIMARY KEY', table_schema: 'public', table_name: 'events', column_index: 1, column_name: 'id', column_expr: null, ref_schema: null, ref_table: null, ref_column: null}],
        }
        const uniques: Record<EntityId, RawConstraintColumn[]> = {
            'public.users': [{constraint_name: '', constraint_type: 'UNIQUE', table_schema: 'public', table_name: 'users', column_index: 2, column_name: 'name', column_expr: null, ref_schema: null, ref_table: null, ref_column: null}],
        }
        const indexes: Record<EntityId, RawConstraintColumn[]> = {
            'public.events': [{constraint_name: '', constraint_type: 'INDEX', table_schema: 'public', table_name: 'events', column_index: 2, column_name: 'name', column_expr: null, ref_schema: null, ref_table: null, ref_column: null}],
        }
        const jsonColumns: Record<EntityId, Record<AttributeName, ValueSchema>> = {'public.events': {'details': {type: 'object', values: [{nb_projects: 1}], nested: {nb_projects: {type: 'number', values: [1]}}}}}
        const polyColumns: Record<EntityId, Record<AttributeName, string[]>> = {'public.events': {'item_kind': ['project', 'organization']}}
        const db = buildDatabase([usersTable, eventsTable], {'public.users': usersColumns, 'public.events': eventsColumns}, primaryKeys, uniques, indexes, jsonColumns, polyColumns, [eventsCreatedByFK], 'azimutt_dev', date, date)
        expect(zodParse(Database)(db).getOrThrow()).toEqual({
            entities: [{
                schema: 'public',
                name: 'users',
                attrs: [
                    {name: 'id', type: 'uuid', doc: 'user id'},
                    {name: 'name', type: 'varchar'},
                    {name: 'role', type: 'varchar', default: 'guest'}
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['name']], unique: true}],
                doc: 'List of users',
                stats: {rows: 12, size: 156, sizeIdx: 35}
            }, {
                schema: 'public',
                name: 'events',
                attrs: [
                    {name: 'id', type: 'uuid'},
                    {name: 'name', type: 'varchar'},
                    {name: 'item_id', type: 'uuid', null: true},
                    {name: 'item_kind', type: 'varchar', null: true, stats: {distinctValues: ['project', 'organization']}},
                    {name: 'details', type: 'json', null: true, attrs: [{name: 'nb_projects', type: 'number'}]},
                    {name: 'created_by', type: 'uuid'}
                ],
                pk: {name: 'events_pk', attrs: [['id']]},
                indexes: [{attrs: [['name']]}],
            }],
            relations: [
                {src: {schema: 'public', entity: 'events'}, ref: {schema: 'public', entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]}
            ],
            stats: {
                name: 'azimutt_dev',
                kind: 'mysql',
                extractedAt: new Date(date).toISOString(),
                extractionDuration: 0,
            }
        })
    })
})
