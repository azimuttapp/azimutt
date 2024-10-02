import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, databaseDiff, parseJsonDatabase} from "@azimutt/models";
import {generatePostgres, generatePostgresDiff} from "./postgresGenerator";

describe('postgresGenerator', () => {
    test('empty', () => {
        expect(generatePostgres({})).toEqual('')
    })
    test('basic', () => {
        const db: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                ],
                pk: {attrs: [['id']]}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'uuid'},
                    {name: 'title', type: 'varchar'},
                    {name: 'content', type: 'text'},
                    {name: 'author', type: 'int'},
                ],
                pk: {attrs: [['id']]}
            }],
            relations: [
                {src: {entity: 'posts', attrs: [['author']]}, ref: {entity: 'users', attrs: [['id']]}}
            ],
        }
        const sql = `DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar NOT NULL
);

CREATE TABLE posts (
  id uuid PRIMARY KEY,
  title varchar NOT NULL,
  content text NOT NULL,
  author int NOT NULL REFERENCES users(id)
);
`
        expect(generatePostgres(db)).toEqual(sql)
    })
    test('full', () => {
        const db: Database = parseJsonDatabase(fs.readFileSync('../aml/resources/full.json', 'utf8')).result || {}
        const sql = fs.readFileSync('./resources/full.postgres.sql', 'utf8')
        // const parsed = parsePostgres(sql)
        // expect(parsed).toEqual({result: db})
        expect(generatePostgres(db)).toEqual(sql)
    })
    describe('diff', () => {
        test('empty', () => {
            expect(generatePostgresDiff({})).toEqual('')
        })
        describe('types', () => {
            test('create type', () => {
                expect(generatePostgresDiff(databaseDiff({}, {types: [{name: 'status', values: ['draft', 'public']}]}))).toEqual(`CREATE TYPE status AS ENUM ('draft', 'public');\n`)
            })
            test('remove type', () => {
                expect(generatePostgresDiff(databaseDiff({types: [{name: 'status', values: ['draft', 'public']}]}, {}))).toEqual(`DROP TYPE IF EXISTS status;\n`)
            })
            test('update alias', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'email', alias: 'varchar'}]},
                    {types: [{name: 'email', alias: 'varchar(150)'}]},
                ))).toEqual(`-- ALTER TYPE email AS varchar(150); -- type alias not supported on PostgreSQL\n`)
            })
            test('other to alias', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'email', values: ['varchar']}]},
                    {types: [{name: 'email', alias: 'varchar'}]},
                ))).toEqual(`DROP TYPE IF EXISTS email;\n-- CREATE TYPE email AS varchar; -- type alias not supported on PostgreSQL\n`)
            })
            test('update enum', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'post_status', values: ['draft', 'published']}]},
                    {types: [{name: 'post_status', values: ['draft', 'public', 'private']}]},
                ))).toEqual(`ALTER TYPE post_status ADD VALUE IF NOT EXISTS 'public';
ALTER TYPE post_status ADD VALUE IF NOT EXISTS 'private';
-- ALTER TYPE post_status DROP VALUE 'published'; -- can't drop enum value in PostgreSQL
`)
            })
            test('other to enum', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'status', alias: 'varchar'}]},
                    {types: [{name: 'status', values: ['draft', 'published']}]},
                ))).toEqual(`DROP TYPE IF EXISTS status;\nCREATE TYPE status AS ENUM ('draft', 'published');\n`)
            })
            test('update struct', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}, {name: 'alt', type: 'bool'}, {name: 'tmp', type: 'varchar'}]}]},
                    {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'bigint'}, {name: 'alt2', type: 'bool'}, {name: 'z', type: 'int'}]}]},
                ))).toEqual(`ALTER TYPE position RENAME ATTRIBUTE alt TO alt2;
ALTER TYPE position ALTER ATTRIBUTE y TYPE bigint;
ALTER TYPE position ADD ATTRIBUTE z int;
ALTER TYPE position DROP ATTRIBUTE IF EXISTS tmp;
`)
            })
            test('other to struct', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'position', alias: 'varchar'}]},
                    {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]}]},
                ))).toEqual(`DROP TYPE IF EXISTS position;\nCREATE TYPE position AS (x int, y int);\n`)
            })
            test('update custom', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'size', definition: 'range(1..10)'}]},
                    {types: [{name: 'size', definition: 'range(1..100)'}]},
                ))).toEqual(`DROP TYPE IF EXISTS size;\nCREATE TYPE size range(1..100);\n`)
            })
            test('other to custom', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'size', alias: 'varchar'}]},
                    {types: [{name: 'size', definition: 'range(1..100)'}]},
                ))).toEqual(`DROP TYPE IF EXISTS size;\nCREATE TYPE size range(1..100);\n`)
            })
            test('create doc', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'email'}]},
                    {types: [{name: 'email', doc: 'basic email'}]},
                ))).toEqual(`COMMENT ON TYPE email IS 'basic email';\n`)
            })
            test('remove doc', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'email', doc: 'basic email'}]},
                    {types: [{name: 'email'}]},
                ))).toEqual(`COMMENT ON TYPE email IS NULL;\n`)
            })
            test('update doc', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'email', doc: 'basic email'}]},
                    {types: [{name: 'email', doc: 'better email'}]},
                ))).toEqual(`COMMENT ON TYPE email IS 'better email';\n`)
            })
        })
    })
})
