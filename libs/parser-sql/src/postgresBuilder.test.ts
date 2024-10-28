import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, parseJsonDatabase, ParserError} from "@azimutt/models";
import {parsePostgresAst} from "./postgresParser";
import {buildPostgresDatabase} from "./postgresBuilder";

describe('postgresBuilder', () => {
    test('empty', () => {
        expect(parse('')).toEqual({db: {extra: {}}, errors: []})
    })
    test('complex', () => {
        const input = `
CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar NOT NULL DEFAULT 'anon' UNIQUE,
  role varchar NOT NULL,
  CHECK ( length(name) >= 4 )
);

CREATE TABLE cms.posts (
  id int PRIMARY KEY,
  title varchar CHECK ( length(title) > 10 ),
  author int REFERENCES users(id)
);

CREATE VIEW admins AS SELECT id, name FROM users WHERE role='admin';
`
        const db: Database = {
            entities: [
                {name: 'users', attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar', default: "'anon'"}, // TODO: anon instead of 'anon'
                    {name: 'role', type: 'varchar'},
                ], pk: {attrs: [['id']]}, indexes: [{attrs: [['name']], unique: true}], checks: [{attrs: [['name']], predicate: 'length(name) >= 4'}]},
                {schema: 'cms', name: 'posts', attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar', null: true},
                    {name: 'author', type: 'int', null: true}
                ], pk: {attrs: [['id']]}, checks: [{attrs: [['title']], predicate: 'length(title) > 10'}]},
                {name: 'admins', kind: 'view', def: "SELECT id, name FROM users WHERE role = 'admin'", attrs: [
                    {name: 'id', type: 'unknown'},
                    {name: 'name', type: 'unknown'},
                ]}
            ],
            relations: [
                {src: {schema: 'cms', entity: 'posts', attrs: [['author']]}, ref: {entity: 'users', attrs: [['id']]}},
            ],
            extra: {}
        }
        expect(parse(input)).toEqual({db, errors: []})
    })
    test.skip('full', () => {
        const json = parseJsonDatabase(fs.readFileSync('../aml/resources/full.json', 'utf8'))
        const db: Database = json.result || {}
        const sql = fs.readFileSync('./resources/full.postgres.sql', 'utf8')
        const parsed = parse(sql)
        expect(parsed.errors).toEqual([])
        expect(parsed.db).toEqual(db)
    })
})

function parse(sql: string): {db: Database, errors: ParserError[]} {
    try {
        return parsePostgresAst(sql)
            .map(ast => buildPostgresDatabase(ast, 0, 0))
            .map(({db: {extra: {source, createdAt, creationTimeMs, parsingTimeMs, formattingTimeMs, ...extra} = {}, ...db}, errors}) =>
                ({db: {...db, extra}, errors})
            ).result || {db: {}, errors: []}
    } catch (e) {
        console.error(e) // print stack trace
        throw new Error(`Can't parse '${sql}'${typeof e === 'object' && e !== null && 'message' in e ? ': ' + e.message : ''}`)
    }
}
