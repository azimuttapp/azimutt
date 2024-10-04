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
        describe('tables', () => {
            test('create', () => {
                expect(generatePostgresDiff(databaseDiff({}, {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}]})))
                    .toEqual(`CREATE TABLE users (\n  id int NOT NULL,\n  name varchar NOT NULL\n);\n`)
            })
            test('delete', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}]}, {})))
                    .toEqual(`DROP TABLE IF EXISTS users;\n`)
            })
            describe('attributes', () => {
                test('create', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}]}
                    ))).toEqual(`ALTER TABLE users ADD name varchar NOT NULL;\n`)
                })
                test('delete', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}]}]}
                    ))).toEqual(`ALTER TABLE users DROP name;\n`)
                })
                test('rename', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'user_id', type: 'int'}]}]}
                    ))).toEqual(`ALTER TABLE users RENAME id TO user_id;\n`)
                })
                test('update type', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}]}
                    ))).toEqual(`ALTER TABLE users ALTER id TYPE uuid;\n`)
                })
                test('update nullable', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'name', type: 'varchar', null: true}, {name: 'email', type: 'varchar'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'name', type: 'varchar'}, {name: 'email', type: 'varchar', null: true}]}]},
                    ))).toEqual(`ALTER TABLE users ALTER name SET NOT NULL;\nALTER TABLE users ALTER email DROP NOT NULL;\n`)
                })
                test('update default', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'name', type: 'varchar'}, {name: 'role', type: 'varchar', default: 'guest'}, {name: 'cpt', type: 'int'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'name', type: 'varchar', default: 'anonymous'}, {name: 'role', type: 'varchar'}, {name: 'cpt', type: 'int', default: 0}]}]},
                    ))).toEqual(`ALTER TABLE users ALTER name SET DEFAULT 'anonymous';\nALTER TABLE users ALTER role DROP DEFAULT;\nALTER TABLE users ALTER cpt SET DEFAULT 0;\n`)
                })
                test('create doc', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int', doc: 'user id'}]}]}
                    ))).toEqual(`COMMENT ON COLUMN users.id IS 'user id';\n`)
                })
            })
            describe('constraints', () => {
                test.skip('primary key', () => {
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: []}]},
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}], pk: {name: 'users_pk', attrs: [['id']]}}]}
                    ))).toEqual(`ALTER TABLE users ADD id int CONSTRAINT users_pk PRIMARY KEY;\n`)
                    expect(generatePostgresDiff(databaseDiff(
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}]}]},
                        {entities: [{name: 'users', attrs: [{name: 'id', type: 'int'}], pk: {name: 'users_pk', attrs: [['id']]}}]}
                    ))).toEqual(`ALTER TABLE users ADD CONSTRAINT users_pk PRIMARY KEY (id);\n`)
                })
                // TODO: indexes, checks
            })
            test('create doc', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'users'}]}, {entities: [{name: 'users', doc: 'list users'}]}))).toEqual(`COMMENT ON TABLE users IS 'list users';\n`)
            })
            test('delete doc', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'users', doc: 'list users'}]}, {entities: [{name: 'users'}]}))).toEqual(`COMMENT ON TABLE users IS NULL;\n`)
            })
            test('update doc', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'users', doc: 'store users'}]}, {entities: [{name: 'users', doc: 'list users'}]}))).toEqual(`COMMENT ON TABLE users IS 'list users';\n`)
            })
        })
        describe('views', () => {
            test('create', () => {
                expect(generatePostgresDiff(databaseDiff({}, {entities: [{name: 'admins', kind: 'view', def: 'SELECT * FROM users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}]})))
                    .toEqual(`CREATE VIEW admins AS\nSELECT * FROM users;\n`)
            })
            test('delete', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'admins', kind: 'view', def: 'SELECT * FROM users', attrs: [{name: 'id', type: 'int'}, {name: 'name', type: 'varchar'}]}]}, {})))
                    .toEqual(`DROP VIEW IF EXISTS admins;\n`)
            })
            test('create doc', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'admins', kind: 'view'}]}, {entities: [{name: 'admins', kind: 'view', doc: 'list admins'}]},))).toEqual(`COMMENT ON VIEW admins IS 'list admins';\n`)
            })
            test('delete doc', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'admins', kind: 'view', doc: 'list admins'}]}, {entities: [{name: 'admins', kind: 'view'}]},))).toEqual(`COMMENT ON VIEW admins IS NULL;\n`)
            })
            test('update doc', () => {
                expect(generatePostgresDiff(databaseDiff({entities: [{name: 'admins', kind: 'view', doc: 'store admins'}]}, {entities: [{name: 'admins', kind: 'view', doc: 'list admins'}]},))).toEqual(`COMMENT ON VIEW admins IS 'list admins';\n`)
            })
        })
        // TODO: relations
        describe('types', () => {
            test('create', () => {
                expect(generatePostgresDiff(databaseDiff({}, {types: [{name: 'status', values: ['draft', 'public']}]}))).toEqual(`CREATE TYPE status AS ENUM ('draft', 'public');\n`)
            })
            test('delete', () => {
                expect(generatePostgresDiff(databaseDiff({types: [{name: 'status', values: ['draft', 'public']}]}, {}))).toEqual(`DROP TYPE IF EXISTS status;\n`)
            })
            test('update alias', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'email', alias: 'varchar'}]},
                    {types: [{name: 'email', alias: 'varchar(150)'}]},
                ))).toEqual(`-- ALTER TYPE email AS varchar(150); -- type alias not supported on PostgreSQL\n`)
            })
            test('change to alias', () => {
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
            test('change to enum', () => {
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
            test('change to struct', () => {
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
            test('change to custom', () => {
                expect(generatePostgresDiff(databaseDiff(
                    {types: [{name: 'size', alias: 'varchar'}]},
                    {types: [{name: 'size', definition: 'range(1..100)'}]},
                ))).toEqual(`DROP TYPE IF EXISTS size;\nCREATE TYPE size range(1..100);\n`)
            })
            test('create doc', () => {
                expect(generatePostgresDiff(databaseDiff({types: [{name: 'email'}]}, {types: [{name: 'email', doc: 'basic email'}]},))).toEqual(`COMMENT ON TYPE email IS 'basic email';\n`)
            })
            test('delete doc', () => {
                expect(generatePostgresDiff(databaseDiff({types: [{name: 'email', doc: 'basic email'}]}, {types: [{name: 'email'}]},))).toEqual(`COMMENT ON TYPE email IS NULL;\n`)
            })
            test('update doc', () => {
                expect(generatePostgresDiff(databaseDiff({types: [{name: 'email', doc: 'basic email'}]}, {types: [{name: 'email', doc: 'better email'}]},))).toEqual(`COMMENT ON TYPE email IS 'better email';\n`)
            })
        })
    })
})
