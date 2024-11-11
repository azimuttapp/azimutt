import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {removeFieldsDeep} from "@azimutt/utils";
import {Database, Entity, parseJsonDatabase, ParserError, ParserResult} from "@azimutt/models";
import {SelectInnerAst} from "./postgresAst";
import {parsePostgresAst} from "./postgresParser";
import {buildPostgresDatabase, SelectEntities, selectEntities} from "./postgresBuilder";

describe('postgresBuilder', () => {
    test('empty', () => {
        expect(parse('')).toEqual({db: {}, errors: []})
    })
    test('complex', () => {
        const input = `
CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar NOT NULL DEFAULT 'anon' CONSTRAINT users_name_uniq UNIQUE,
  role varchar NOT NULL,
  CHECK ( length(name) >= 4 )
);
CREATE INDEX ON users (role);
ALTER TABLE users ADD COLUMN created_at timestamp NOT NULL DEFAULT now();
ALTER TABLE users DROP CONSTRAINT users_name_uniq;
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'guest';
COMMENT ON TABLE users IS 'List users';
COMMENT ON COLUMN users.name IS 'user name';
COMMENT ON COLUMN users.role IS 'user role';
COMMENT ON COLUMN users.role IS NULL;

CREATE TABLE cms.posts (
  id int PRIMARY KEY,
  title varchar CHECK ( length(title) > 10 ),
  author int CONSTRAINT posts_author_fk REFERENCES users(id),
  created_at timestamp NOT NULL DEFAULT now()
);
ALTER TABLE cms.posts DROP COLUMN created_at;
ALTER TABLE cms.posts ADD UNIQUE (title);
ALTER TABLE cms.posts ALTER COLUMN title SET NOT NULL;
COMMENT ON CONSTRAINT posts_author_fk ON cms.posts IS 'posts fk';

CREATE VIEW admins AS SELECT id, name FROM users WHERE role='admin';

CREATE TYPE bug_status AS ENUM ('open', 'closed');
COMMENT ON TYPE bug_status IS 'bug status';
`
        const db: Database = {
            entities: [
                {
                    name: 'users',
                    attrs: [
                        {name: 'id', type: 'int'},
                        {name: 'name', type: 'varchar', default: 'anon', doc: 'user name'},
                        {name: 'role', type: 'varchar', default: 'guest'},
                        {name: 'created_at', type: 'timestamp', default: '`now()`'},
                    ],
                    pk: {attrs: [['id']]},
                    indexes: [{attrs: [['role']]}],
                    checks: [{attrs: [['name']], predicate: 'length(name) >= 4'}],
                    doc: 'List users'
                },
                {
                    schema: 'cms',
                    name: 'posts',
                    attrs: [
                        {name: 'id', type: 'int'},
                        {name: 'title', type: 'varchar'},
                        {name: 'author', type: 'int', null: true},
                    ],
                    pk: {attrs: [['id']]},
                    indexes: [{attrs: [['title']], unique: true}],
                    checks: [{attrs: [['title']], predicate: 'length(title) > 10'}]
                },
                {
                    name: 'admins',
                    kind: 'view',
                    def: "SELECT id, name FROM users WHERE role = 'admin'",
                    attrs: [
                        {name: 'id', type: 'int'},
                        {name: 'name', type: 'varchar'},
                    ]
                }
            ],
            relations: [
                {name: 'posts_author_fk', src: {schema: 'cms', entity: 'posts', attrs: [['author']]}, ref: {entity: 'users', attrs: [['id']]}, doc: 'posts fk'},
            ],
            types: [
                {name: 'bug_status', values: ['open', 'closed'], doc: 'bug status'},
            ],
        }
        expect(parse(input)).toEqual({db, errors: []})
    })
    test.skip('full', () => { // won't work, some concepts can't be handled in SQL, yet, worth checking the diff ^^
        const json = parseJsonDatabase(fs.readFileSync('../aml/resources/full.json', 'utf8'))
        const db: Database = json.result || {}
        const sql = fs.readFileSync('./resources/full.postgres.sql', 'utf8')
        const parsed = parse(sql)
        expect(parsed.errors).toEqual([])
        expect(removeFieldsDeep(parsed.db, ['extra'])).toEqual(removeFieldsDeep(db, ['extra']))
    })
    test('keep some statements in extra', () => {
        const input = `
INSERT INTO users VALUES (1, 'loic');
SELECT * FROM users;
`
        const res = parseSql(input)
        expect(res.result?.extra?.dml).toEqual([{
            statement: 1,
            kind: 'InsertInto',
            meta: {offset: {start: 1, end: 37}, position: {start: {line: 2, column: 1}, end: {line: 2, column: 37}}},
            table: {kind: 'Identifier', value: 'users'},
            values: [[{kind: 'Integer', value: 1}, {kind: 'String', value: 'loic'}]]
        }])
        expect(res.result?.extra?.dql).toEqual([{
            statement: 2,
            kind: 'Select',
            meta: {offset: {start: 39, end: 58}, position: {start: {line: 3, column: 1}, end: {line: 3, column: 20}}},
            columns: [{kind: 'Wildcard'}],
            from: {kind: 'Table', table: {kind: 'Identifier', value: 'users'}}
        }])
    })
    describe('selectEntities', () => {
        const users: Entity = {schema: 'public', name: 'users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}
        const events: Entity = {schema: 'public', name: 'events', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}, {name: 'created_by', type: 'int'}]}
        test('simple', () => {
            expect(extract('SELECT id, name FROM users;', [])).toEqual({
                columns: [
                    {name: 'id', sources: [{table: 'users', column: 'id'}]},
                    {name: 'name', sources: [{table: 'users', column: 'name'}]}
                ],
                sources: [{name: 'users', from: {kind: 'Table', table: 'users'}}]
            })
            expect(extract('SELECT id, name FROM users;', [users])).toEqual({
                columns: [
                    {name: 'id', type: 'int', sources: [{schema: 'public', table: 'users', column: 'id', type: 'int'}]},
                    {name: 'name', type: 'varchar', sources: [{schema: 'public', table: 'users', column: 'name', type: 'varchar'}]}
                ],
                sources: [{name: 'users', from: {kind: 'Table', schema: 'public', table: 'users', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}}]
            })
        })
        test('wildcard', () => {
            expect(extract('SELECT * FROM users;', [])).toEqual({
                columns: [{name: '*', sources: []}],
                sources: [{name: 'users', from: {kind: 'Table', table: 'users'}}]
            })
            expect(extract('SELECT * FROM users;', [users])).toEqual({
                columns: [
                    {name: 'id', type: 'int', sources: [{schema: 'public', table: 'users', column: 'id', type: 'int'}]},
                    {name: 'name', type: 'varchar', sources: [{schema: 'public', table: 'users', column: 'name', type: 'varchar'}]}
                ],
                sources: [{name: 'users', from: {kind: 'Table', schema: 'public', table: 'users', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}}]
            })
        })
        test('no from', () => {
            expect(extract('SELECT 1;', [])).toEqual({
                columns: [{name: 'col_1', sources: []}],
                sources: []
            })
        })
        test('function', () => {
            expect(extract('SELECT first_name || last_name FROM users;', [])).toEqual({
                columns: [{name: 'col_1', sources: [{table: 'users', column: 'first_name'}, {table: 'users', column: 'last_name'}]}],
                sources: [{name: 'users', from: {kind: 'Table', table: 'users'}}]
            })
            expect(extract('SELECT lower(name) FROM users;', [])).toEqual({
                columns: [{name: 'lower', sources: [{table: 'users', column: 'name'}]}],
                sources: [{name: 'users', from: {kind: 'Table', table: 'users'}}]
            })
            expect(extract('SELECT count(*) FROM users;', [])).toEqual({
                columns: [{name: 'count', sources: []}],
                sources: [{name: 'users', from: {kind: 'Table', table: 'users'}}]
            })
        })
        test('join', () => {
            expect(extract('SELECT u.name, e.* FROM events e JOIN users u ON e.created_by = u.id;', [users, events])).toEqual({
                columns: [
                    {table: 'u', name: 'name', type: 'varchar', sources: [{schema: 'public', table: 'users', column: 'name', type: 'varchar'}]},
                    {table: 'e', name: 'id', type: 'int', sources: [{schema: 'public', table: 'events', column: 'id', type: 'int'}]},
                    {table: 'e', name: 'name', type: 'varchar', sources: [{schema: 'public', table: 'events', column: 'name', type: 'varchar'}]},
                    {table: 'e', name: 'created_by', type: 'int', sources: [{schema: 'public', table: 'events', column: 'created_by', type: 'int'}]},
                ],
                sources: [
                    {name: 'e', from: {kind: 'Table', schema: 'public', table: 'events', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}, {name: 'created_by', type: 'int'}]}},
                    {name: 'u', from: {kind: 'Table', schema: 'public', table: 'users', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}},
                ]
            })
            expect(extract('SELECT u.name, created_by FROM events e JOIN users u ON e.created_by = u.id;', [users, events])).toEqual({
                columns: [
                    {table: 'u', name: 'name', type: 'varchar', sources: [{schema: 'public', table: 'users', column: 'name', type: 'varchar'}]},
                    {name: 'created_by', type: 'int', sources: [{schema: 'public', table: 'events', column: 'created_by', type: 'int'}]},
                ],
                sources: [
                    {name: 'e', from: {kind: 'Table', schema: 'public', table: 'events', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}, {name: 'created_by', type: 'int'}]}},
                    {name: 'u', from: {kind: 'Table', schema: 'public', table: 'users', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}},
                ]
            })
        })
        test('subquery', () => {
            expect(extract("SELECT a.* FROM (SELECT id FROM users WHERE role = 'admin') a;", [])).toEqual({
                columns: [{table: 'a', name: 'id', sources: [{table: 'users', column: 'id'}]}],
                sources: [{name: 'a', from: {
                    kind: 'Select',
                    columns: [{name: 'id', sources: [{table: 'users', column: 'id'}]}],
                    sources: [{name: 'users', from: {kind: 'Table', table: 'users'}}]}
                }]
            })
            expect(extract("SELECT a.* FROM (SELECT id FROM users WHERE role = 'admin') a;", [users])).toEqual({
                columns: [{table: 'a', name: 'id', type: 'int', sources: [{schema: 'public', table: 'users', column: 'id', type: 'int'}]}],
                sources: [{name: 'a', from: {
                    kind: 'Select',
                    columns: [{name: 'id', type: 'int', sources: [{schema: 'public', table: 'users', column: 'id', type: 'int'}]}],
                    sources: [{name: 'users', from: {kind: 'Table', schema: 'public', table: 'users', columns: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}}]}
                }]
            })
        })
    })
})

function parse(input: string): {db: Database, errors: ParserError[]} {
    try {
        const res = parseSql(input).map(({extra: {source, createdAt, creationTimeMs, parsingTimeMs, formattingTimeMs, ...extra} = {}, ...db}) => ({...db, extra}))
        return {db: removeFieldsDeep(res.result || {}, ['extra']), errors: res.errors || []}
    } catch (e) {
        console.error(e) // print stack trace
        throw new Error(`Can't parse '${input}'${typeof e === 'object' && e !== null && 'message' in e ? ': ' + e.message : ''}`)
    }
}

function parseSql(input: string): ParserResult<Database> {
    const start = Date.now()
    return parsePostgresAst(input).flatMap(ast => buildPostgresDatabase(ast, start, Date.now()))
}

function extract(input: string, entities: Entity[]): SelectEntities {
    return removeFieldsDeep(selectEntities(parsePostgresAst(input).result?.statements?.[0] as SelectInnerAst, entities), ['token'])
}
