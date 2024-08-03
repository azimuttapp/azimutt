import {describe, expect, test} from "@jest/globals";
import {
    formatSql,
    getEntities,
    getMainEntity,
    parseCondition,
    parseSelectColumn,
    parseSelectTable,
    parseSqlScript,
    parseValue
} from "./sql";

describe('sql', () => {
    test('getMainEntity', () => {
        expect(getMainEntity('bad')).toEqual(undefined)
        expect(getMainEntity('select * from users;')).toEqual({entity: 'users'})
        expect(getMainEntity('SELECT * FROM users;')).toEqual({entity: 'users'})
        expect(getMainEntity('SELECT * FROM public.users;')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM "public"."users";')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity("SELECT * FROM 'public'.'users';")).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM `public`.`users`;')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM [public].[users];')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity("INSERT INTO users (id, name) VALUES (1, 'Loïc');")).toEqual({entity: 'users'})
        expect(getMainEntity("UPDATE users SET name='Loïc' WHERE id=1;")).toEqual({entity: 'users'})
        expect(getMainEntity("DELETE FROM users WHERE id=1;")).toEqual({entity: 'users'})
    })
    test('getEntities', () => {
        expect(getEntities('bad')).toEqual([])
        expect(getEntities('SELECT * FROM users;')).toEqual([{entity: 'users'}])
        expect(getEntities('SELECT * FROM events e JOIN users u ON e.created_by = u.id;')).toEqual([{entity: 'events'}, {entity: 'users'}])
        expect(getEntities(`
            SELECT *
            FROM events e
                     JOIN users u ON e.created_by = u.id
                     JOIN organizations o ON e.organization_id = o.id
            WHERE e.name = 'plan_limit';`)).toEqual([{entity: 'events'}, {entity: 'users'}, {entity: 'organizations'}])
        expect(getEntities("INSERT INTO users (id, name) VALUES (1, 'Loïc');")).toEqual([{entity: 'users'}])
        expect(getEntities("UPDATE users SET name='Loïc' WHERE id=1;")).toEqual([{entity: 'users'}])
        expect(getEntities("DELETE FROM users WHERE id=1;")).toEqual([{entity: 'users'}])
    })
    test('formatSql', () => {
        expect(formatSql('SELECT * FROM users;')).toEqual('SELECT * FROM users;')
        expect(formatSql('SELECT *\nFROM users\nWHERE id=1;')).toEqual('SELECT * FROM users WHERE id=1;')
        expect(formatSql('SELECT id\n     , name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT id,\n       name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT id, name      as n FROM users;')).toEqual('SELECT id, name as n FROM users;')
        expect(formatSql('SELECT id -- the id\n     , name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT e.id as event_id, e.details as event_details, u.email as email FROM events e JOIN users u ON u.id = e.created_by LEFT JOIN organizations o ON o.id = e.organization_id WHERE e.name="plan_limit" AND u.email="loicknuchel@gmail.com";'))
            .toEqual('SELECT e.id as event_id, e.details as event_... FROM events e JOIN users u ON u.id = e.created_by LEFT JOIN organizations o ON o.id = e.organization_id WHERE e.name="plan_limit" AND u.email="loickn...')
    })
    describe('parseSqlScript', () => {
        test('simple', () => {
            expect(parseSqlScript('SELECT * FROM events;'))
                .toEqual([{command: 'SELECT', table: {name: 'events'}, columns: [{name: '*'}]}])
            expect(parseSqlScript('SELECT * FROM public.events;'))
                .toEqual([{command: 'SELECT', table: {name: 'events', schema: 'public'}, columns: [{name: '*'}]}])
            expect(parseSqlScript('SELECT e.* FROM events e;'))
                .toEqual([{command: 'SELECT', table: {name: 'events', alias: 'e'}, columns: [{name: '*', scope: 'e'}]}])

            expect(parseSqlScript('SELECT id FROM events;'))
                .toEqual([{command: 'SELECT', table: {name: 'events'}, columns: [{name: 'id', col: ['id']}]}])
            expect(parseSqlScript('SELECT id AS event_id FROM events;'))
                .toEqual([{command: 'SELECT', table: {name: 'events'}, columns: [{name: 'event_id', col: ['id']}]}])
            expect(parseSqlScript('SELECT events.id FROM events;'))
                .toEqual([{command: 'SELECT', table: {name: 'events'}, columns: [{name: 'id', scope: 'events', col: ['id']}]}])
            expect(parseSqlScript('SELECT e.id FROM events e;'))
                .toEqual([{command: 'SELECT', table: {name: 'events', alias: 'e'}, columns: [{name: 'id', scope: 'e', col: ['id']}]}])
        })
        test('joins', () => {
            expect(parseSqlScript('SELECT u.name, p.name, e.* FROM events e JOIN users u ON e.created_by = u.id AND u.deleted_at IS NOT NULL LEFT JOIN projects p ON e.project_id=p.id;')).toEqual([{
                command: 'SELECT',
                table: {name: 'events', alias: 'e'},
                columns: [{name: 'name', scope: 'u', col: ['name']}, {name: 'name', scope: 'p', col: ['name']}, {name: '*', scope: 'e'}],
                joins: [{table: 'users', alias: 'u', on: {
                    op: 'AND',
                    left: {op: '=', left: {column: 'created_by', scope: 'e'}, right: {column: 'id', scope: 'u'}},
                    right: {op: 'NOT NULL', value: {column: 'deleted_at', scope: 'u'}}
                }}, {table: 'projects', alias: 'p', kind: 'LEFT', on: {op: '=', left: {column: 'project_id', scope: 'e'}, right: {column: 'id', scope: 'p'}}}]
            }])
        })
        test('complex', () => {
            expect(parseSqlScript('SELECT t.EMAIL, count(*) AS COUNT FROM "C##AZIMUTT"."USERS" t WHERE t.EMAIL LIKE \'%@azimutt.app\' GROUP BY t.EMAIL HAVING COUNT > 3 ORDER BY COUNT DESC, EMAIL OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;')).toEqual([{
                command: 'SELECT',
                table: {name: 'USERS', schema: 'C##AZIMUTT', alias: 't'},
                columns: [{name: 'EMAIL', scope: 't', col: ['EMAIL']}, {name: 'COUNT', def: 'count(*)'}],
                where: {op: 'LIKE', left: {column: 'EMAIL', scope: 't'}, right: '%@azimutt.app'},
                groupBy: 't.EMAIL',
                having: {op: '>', left: {column: 'COUNT'}, right: 3},
                orderBy: 'COUNT DESC, EMAIL',
                offset: 10,
                limit: 10,
            }])
            // TODO: queries with sub-queries (fails ^^)
        })
        test('SQL Server specifics', () => {
            expect(parseSqlScript('SELECT TOP 10 * FROM events;'))
                .toEqual([{command: 'SELECT', table: {name: 'events'}, columns: [{name: '*'}]}])
        })
        test('parseSelectColumn', () => {
            expect(parseSelectColumn('*', 1)).toEqual({name: '*'})
            expect(parseSelectColumn('e.*', 1)).toEqual({name: '*', scope: 'e'})
            expect(parseSelectColumn('id', 1)).toEqual({name: 'id', col: ['id']})
            expect(parseSelectColumn('created_by', 1)).toEqual({name: 'created_by', col: ['created_by']})
            expect(parseSelectColumn('"a col"', 1)).toEqual({name: 'a col', col: ['a col']})
            expect(parseSelectColumn('e.id', 1)).toEqual({name: 'id', scope: 'e', col: ['id']})
            // expect(parseSelectColumn("id->>'f'", 1)).toEqual({name: 'id', col: ['id']}) // TODO: json column
            expect(parseSelectColumn('id as user_id', 1)).toEqual({name: 'user_id', col: ['id']})
            expect(parseSelectColumn('e.id as user_id', 1)).toEqual({name: 'user_id', scope: 'e', col: ['id']})
            expect(parseSelectColumn('count(*)', 1)).toEqual({name: 'col_1', def: 'count(*)'})
            expect(parseSelectColumn('count(*) AS count', 1)).toEqual({name: 'count', def: 'count(*)'})
            expect(parseSelectColumn('"id"', 1)).toEqual({name: 'id', col: ['id']})
            expect(parseSelectColumn('"id" as "user_id"', 1)).toEqual({name: 'user_id', col: ['id']})
        })
        test('parseSelectTable', () => {
            expect(parseSelectTable('events')).toEqual({table: {name: 'events'}})
            expect(parseSelectTable('public.events')).toEqual({table: {name: 'events', schema: 'public'}})
            expect(parseSelectTable('events e')).toEqual({table: {name: 'events', alias: 'e'}})
            expect(parseSelectTable('events e JOIN users u ON u.id=e.created_by')).toEqual({table: {name: 'events', alias: 'e'}, joins: [
                {table: 'users', alias: 'u', on: {op: '=', left: {column: 'id', scope: 'u'}, right: {column: 'created_by', scope: 'e'}}}
            ]})
        })
        test('parseCondition', () => {
            expect(parseCondition('u.id=e.created_by')).toEqual({op: '=', left: {column: 'id', scope: 'u'}, right: {column: 'created_by', scope: 'e'}})
            expect(parseCondition('u.status != 0')).toEqual({op: '!=', left: {column: 'status', scope: 'u'}, right: 0})
            expect(parseCondition('u.deleted_at IS NULL')).toEqual({op: 'NULL', value: {column: 'deleted_at', scope: 'u'}})
            expect(parseCondition('u.deleted_at IS NOT NULL')).toEqual({op: 'NOT NULL', value: {column: 'deleted_at', scope: 'u'}})
            expect(parseCondition("u.status IN ('draft', 'published')")).toEqual({op: 'IN', value: {column: 'status', scope: 'u'}, values: ['draft', 'published']})
            expect(parseCondition("u.status NOT IN ('draft', 'published')")).toEqual({op: 'NOT IN', value: {column: 'status', scope: 'u'}, values: ['draft', 'published']})
            expect(parseCondition('u.id=e.created_by AND u.status!=0')).toEqual({
                op: 'AND',
                left: {op: '=', left: {column: 'id', scope: 'u'},  right: {column: 'created_by', scope: 'e'}},
                right: {op: '!=', left: {column: 'status', scope: 'u'}, right: 0}
            })
        })
        test('parseValue', () => {
            expect(parseValue('12')).toEqual(12)
            expect(parseValue("'abc'")).toEqual('abc')
            expect(parseValue('id')).toEqual({column: 'id'})
            expect(parseValue('u.id')).toEqual({column: 'id', scope: 'u'})
            expect(parseValue('"u"."id"')).toEqual({column: 'id', scope: 'u'})
            expect(parseValue('"i d"')).toEqual({column: 'i d'})
            expect(parseValue('i d')).toEqual(undefined)
        })
    })
})
