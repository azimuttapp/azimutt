import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {removeEmpty, removeFieldsDeep} from "@azimutt/utils";
import {
    BooleanAst,
    DecimalAst,
    IdentifierAst,
    IntegerAst,
    ListAst,
    LiteralAst,
    NullAst,
    OperatorAst,
    ParameterAst,
    StringAst,
    TokenInfo,
    TokenIssue
} from "./postgresAst";
import {parsePostgresAst, parseRule} from "./postgresParser";

describe('postgresParser', () => {
    // CREATE MATERIALIZED VIEW
    // UPDATE
    // DELETE
    test('empty', () => {
        expect(parsePostgresAst('')).toEqual({result: {statements: []}})
    })
    test('complex', () => {
        const sql = fs.readFileSync('./resources/complex.postgres.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
    })
    test('structure', () => {
        const sql = fs.readFileSync('../../backend/priv/repo/structure.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
    })
    test('full', () => {
        const sql = fs.readFileSync('./resources/full.postgres.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
    })
    describe('alterTableStatement', () => {
        test('full', () => {
            expect(parsePostgresAst('ALTER TABLE IF EXISTS ONLY public.users ADD CONSTRAINT users_pk PRIMARY KEY (id);')).toEqual({result: {statements: [{
                kind: 'AlterTable',
                ifExists: token(12, 20),
                only: token(22, 25),
                schema: identifier('public', 27, 32),
                table: identifier('users', 34, 38),
                action: {kind: 'AddConstraint', ...token(40, 42), constraint: {kind: 'PrimaryKey', constraint: {...token(44, 53), name: identifier('users_pk', 55, 62)}, ...token(64, 74), columns: [identifier('id', 77, 78)]}},
                ...token(0, 80)
            }]}})
        })
        test('add column', () => {
            expect(parsePostgresAst('ALTER TABLE users ADD author int;')).toEqual({result: {statements: [{
                kind: 'AlterTable',
                table: identifier('users', 12, 16),
                action: {kind: 'AddColumn', ...token(18, 20), column: {name: identifier('author', 22, 27), type: {name: {value: 'int', ...token(29, 31)}, ...token(29, 31)}}},
                ...token(0, 32)
            }]}})
        })
        test('drop column', () => {
            expect(parsePostgresAst('ALTER TABLE users DROP author;')).toEqual({result: {statements: [{
                kind: 'AlterTable',
                table: identifier('users', 12, 16),
                action: {kind: 'DropColumn', ...token(18, 21), column: identifier('author', 23, 28)},
                ...token(0, 29)
            }]}})
        })
        test('add primaryKey', () => {
            expect(parsePostgresAst('ALTER TABLE users ADD PRIMARY KEY (id);')).toEqual({result: {statements: [{
                kind: 'AlterTable',
                table: identifier('users', 12, 16),
                action: {kind: 'AddConstraint', ...token(18, 20), constraint: {kind: 'PrimaryKey', ...token(22, 32), columns: [identifier('id', 35, 36)]}},
                ...token(0, 38)
            }]}})
        })
        test('drop primaryKey', () => {
            expect(parsePostgresAst('ALTER TABLE users DROP CONSTRAINT users_pk;')).toEqual({result: {statements: [{
                kind: 'AlterTable',
                table: identifier('users', 12, 16),
                action: {kind: 'DropConstraint', ...token(18, 32), constraint: identifier('users_pk', 34, 41)},
                ...token(0, 42)
            }]}})
        })
    })
    describe('commentStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst("COMMENT ON SCHEMA public IS 'Main schema';")).toEqual({result: {statements: [{
                kind: 'Comment',
                object: {kind: 'Schema', ...token(0, 16)},
                entity: identifier('public', 18, 23),
                comment: string('Main schema', 28, 40),
                ...token(0, 41)
            }]}})
        })
        test('table', () => {
            expect(parsePostgresAst("COMMENT ON TABLE public.users IS 'List users';")).toEqual({result: {statements: [{
                kind: 'Comment',
                object: {kind: 'Table', ...token(0, 15)},
                schema: identifier('public', 17, 22),
                entity: identifier('users', 24, 28),
                comment: string('List users', 33, 44),
                ...token(0, 45)
            }]}})
        })
        test('column', () => {
            expect(parsePostgresAst("COMMENT ON COLUMN public.users.name IS 'user name';")).toEqual({result: {statements: [{
                kind: 'Comment',
                object: {kind: 'Column', ...token(0, 16)},
                schema: identifier('public', 18, 23),
                parent: identifier('users', 25, 29),
                entity: identifier('name', 31, 34),
                comment: string('user name', 39, 49),
                ...token(0, 50)
            }]}})
        })
        test('constraint', () => {
            expect(parsePostgresAst("COMMENT ON CONSTRAINT users_pk ON public.users IS 'users pk';")).toEqual({result: {statements: [{
                kind: 'Comment',
                object: {kind: 'Constraint', ...token(0, 20)},
                entity: identifier('users_pk', 22, 29),
                schema: identifier('public', 34, 39),
                parent: identifier('users', 41, 45),
                comment: string('users pk', 50, 59),
                ...token(0, 60)
            }]}})
        })
    })
    describe('createExtensionStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE EXTENSION citext;')).toEqual({result: {statements: [{
                kind: 'CreateExtension',
                name: identifier('citext', 17, 22),
                ...token(0, 23)
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst("CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public VERSION '1.0' CASCADE;")).toEqual({result: {statements: [{
                kind: 'CreateExtension',
                ifNotExists: token(17, 29),
                name: identifier('citext', 31, 36),
                with: token(38, 41),
                schema: {...token(43, 48), name: identifier('public', 50, 55)},
                version: {...token(57, 63), number: string('1.0', 65, 69)},
                cascade: token(71, 77),
                ...token(0, 78)
            }]}})
        })
    })
    describe('createIndexStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE INDEX ON users (name);')).toEqual({result: {statements: [{
                kind: 'CreateIndex',
                table: identifier('users', 16, 20),
                columns: [{kind: 'Column', column: identifier('name', 23, 26)}],
                ...token(0, 28)
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst('CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS users_name_idx ON ONLY public.users USING btree' +
                ' ((lower(first_name)) COLLATE "de_DE" ASC NULLS LAST)' +
                // TODO: ' INCLUDE (email) NULLS NOT DISTINCT WITH (fastupdate = off) TABLESPACE indexspace WHERE deleted_at IS NULL' +
                ' INCLUDE (email);'
            )).toEqual({result: {statements: [{
                kind: 'CreateIndex',
                unique: token(7, 12),
                concurrently: token(20, 31),
                ifNotExists: token(33, 45),
                index: identifier('users_name_idx', 47, 60),
                only: token(65, 68),
                schema: identifier('public', 70, 75),
                table: identifier('users', 77, 81),
                using: {...token(83, 87), method: identifier('btree', 89, 93)},
                columns: [{
                    kind: 'Group', expression: {kind: 'Function', function: identifier('lower', 97, 101), parameters: [{kind: 'Column', column: identifier('first_name', 103, 112)}]},
                    collation: {...token(116, 122), name: {...identifier('de_DE', 124, 130), quoted: true}},
                    order: {kind: 'Asc', ...token(132, 134)},
                    nulls: {kind: 'Last', ...token(136, 145)}
                }],
                include: {...token(148, 154), columns: [identifier('email', 157, 161)]},
                // where: {...token(0, 0), predicate: {???}}
                ...token(0, 163)
            }]}})
        })
    })
    describe('createTableStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE TABLE users (id int PRIMARY KEY, name VARCHAR);')).toEqual({result: {statements: [{
                kind: 'CreateTable',
                table: identifier('users', 13, 17),
                columns: [
                    {name: identifier('id', 20, 21), type: {name: {value: 'int', ...token(23, 25)}, ...token(23, 25)}, constraints: [{kind: 'PrimaryKey', ...token(27, 37)}]},
                    {name: identifier('name', 40, 43), type: {name: {value: 'VARCHAR', ...token(45, 51)}, ...token(45, 51)}},
                ],
                ...token(0, 53)
            }]}})
        })
        test('with constraints', () => {
            expect(parsePostgresAst('CREATE TABLE users (id int, role VARCHAR, CONSTRAINT users_pk PRIMARY KEY (id), FOREIGN KEY (role) REFERENCES roles (name));')).toEqual({result: {statements: [{
                kind: 'CreateTable',
                table: identifier('users', 13, 17),
                columns: [
                    {name: identifier('id', 20, 21), type: {name: {value: 'int', ...token(23, 25)}, ...token(23, 25)}},
                    {name: identifier('role', 28, 31), type: {name: {value: 'VARCHAR', ...token(33, 39)}, ...token(33, 39)}},
                ],
                constraints: [
                    {kind: 'PrimaryKey', constraint: {...token(42, 51), name: identifier('users_pk', 53, 60)}, ...token(62, 72), columns: [identifier('id', 75, 76)]},
                    {kind: 'ForeignKey', ...token(80, 90), columns: [identifier('role', 93, 96)], ref: {...token(99, 108), table: identifier('roles', 110, 114), columns: [identifier('name', 117, 120)]}}
                ],
                ...token(0, 123)
            }]}})
        })
        // TODO: CREATE TABLE IF NOT EXISTS users (id int);
        // TODO: CREATE UNLOGGED TABLE users (id int);
    })
    describe('createTypeStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE TYPE position;')).toEqual({result: {statements: [{
                kind: 'CreateType',
                type: identifier('position', 12, 19),
                ...token(0, 20)
            }]}})
        })
        test('struct', () => {
            expect(parsePostgresAst('CREATE TYPE layout_position AS (x int, y int COLLATE "fr_FR");')).toEqual({result: {statements: [{
                kind: 'CreateType',
                type: identifier('layout_position', 12, 26),
                struct: {...token(28, 29), attrs: [
                    {name: identifier('x', 32, 32), type: {name: {value: 'int', ...token(34, 36)}, ...token(34, 36)}},
                    {name: identifier('y', 39, 39), type: {name: {value: 'int', ...token(41, 43)}, ...token(41, 43)}, collation: {...token(45, 51), name: {...identifier('fr_FR', 53, 59), quoted: true}}}
                ]},
                ...token(0, 61)
            }]}})
        })
        test('enum', () => {
            expect(parsePostgresAst("CREATE TYPE public.bug_status AS ENUM ('open', 'closed');")).toEqual({result: {statements: [{
                kind: 'CreateType',
                schema: identifier('public', 12, 17),
                type: identifier('bug_status', 19, 28),
                enum: {...token(30, 36), values: [string('open', 39, 44), string('closed', 47, 54)]},
                ...token(0, 56)
            }]}})
        })
        // TODO: range
        test('base', () => {
            expect(parsePostgresAst("CREATE TYPE box (INPUT = my_box_in_function, OUTPUT = my_box_out_function, INTERNALLENGTH = 16);")).toEqual({result: {statements: [{
                kind: 'CreateType',
                type: identifier('box', 12, 14),
                base: [
                    // FIXME: expressions should be different here (identifier instead of column), or better, each parameter should have its own kind of value...
                    {name: identifier('INPUT', 17, 21), value: {kind: 'Column', column: identifier('my_box_in_function', 25, 42)}},
                    {name: identifier('OUTPUT', 45, 50), value: {kind: 'Column', column: identifier('my_box_out_function', 54, 72)}},
                    {name: identifier('INTERNALLENGTH', 75, 88), value: integer(16, 92, 93)},
                ],
                ...token(0, 95)
            }]}})
        })
    })
    describe('createViewStatementRule', () => {
        test('simplest', () => {
            expect(parsePostgresAst("CREATE VIEW admins AS SELECT * FROM users WHERE role = 'admin';")).toEqual({result: {statements: [{
                kind: 'CreateView',
                view: identifier('admins', 12, 17),
                query: {
                    select: {...token(22, 27), columns: [{kind: 'Wildcard', ...token(29, 29)}]},
                    from: {...token(31, 34), table: identifier('users', 36, 40)},
                    where: {...token(42, 46), predicate: {kind: 'Operation', left: {kind: 'Column', column: identifier('role', 48, 51)}, op: {kind: '=', ...token(53, 53)}, right: string('admin', 55, 61)}},
                },
                ...token(0, 62)
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst("CREATE OR REPLACE TEMP RECURSIVE VIEW admins (id, name) AS SELECT * FROM users WHERE role = 'admin';")).toEqual({result: {statements: [{
                kind: 'CreateView',
                replace: token(7, 16),
                temporary: token(18, 21),
                recursive: token(23, 31),
                view: identifier('admins', 38, 43),
                columns: [identifier('id', 46, 47), identifier('name', 50, 53)],
                query: {
                    select: {...token(59, 64), columns: [{kind: 'Wildcard', ...token(66, 66)}]},
                    from: {...token(68, 71), table: identifier('users', 73, 77)},
                    where: {...token(79, 83), predicate: {kind: 'Operation', left: {kind: 'Column', column: identifier('role', 85, 88)}, op: {kind: '=', ...token(90, 90)}, right: string('admin', 92, 98)}},
                },
                ...token(0, 99)
            }]}})
        })
    })
    describe('dropStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('DROP TABLE users;')).toEqual({result: {statements: [{
                kind: 'Drop',
                object: {kind: 'Table', ...token(0, 9)},
                entities: [{name: identifier('users', 11, 15)}],
                ...token(0, 16)
            }]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('DROP INDEX CONCURRENTLY IF EXISTS users_idx, posts_idx CASCADE;')).toEqual({result: {statements: [{
                kind: 'Drop',
                object: {kind: 'Index', ...token(0, 9)},
                concurrently: token(11, 22),
                ifExists: token(24, 32),
                entities: [{name: identifier('users_idx', 34, 42)}, {name: identifier('posts_idx', 45, 53)}],
                mode: {kind: 'Cascade', ...token(55, 61)},
                ...token(0, 62)
            }]}})
        })
        test('kind', () => {
            expect(parsePostgresAst('DROP TABLE users;').errors || []).toEqual([])
            expect(parsePostgresAst('DROP VIEW users;').errors || []).toEqual([])
            expect(parsePostgresAst('DROP MATERIALIZED VIEW users;').errors || []).toEqual([])
            expect(parsePostgresAst('DROP INDEX users_idx;').errors || []).toEqual([])
            expect(parsePostgresAst('DROP TYPE users;').errors || []).toEqual([])
        })
    })
    describe('insertIntoStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst("INSERT INTO users VALUES (1, 'loic');")).toEqual({result: {statements: [{
                kind: 'InsertInto',
                table: identifier('users', 12, 16),
                values: [[integer(1, 26, 26), string('loic', 29, 34)]],
                ...token(0, 36)
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst("INSERT INTO users (id, name) VALUES (1, 'loic'), (DEFAULT, 'lou') RETURNING id;")).toEqual({result: {statements: [{
                kind: 'InsertInto',
                table: identifier('users', 12, 16),
                columns: [identifier('id', 19, 20), identifier('name', 23, 26)],
                values: [[integer(1, 37, 37), string('loic', 40, 45)], [{kind: 'Default', ...token(50, 56)}, string('lou', 59, 63)]],
                returning: {...token(66, 74), columns: [{kind: 'Column', column: identifier('id', 76, 77)}]},
                ...token(0, 78)
            }]}})
        })
        // TODO: `INSERT INTO films SELECT * FROM tmp_films WHERE date_prod < '2004-05-07';`
        // TODO: `ON CONFLICT (did) DO UPDATE SET dname = EXCLUDED.dname`
    })
    describe('selectStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SELECT name FROM users;')).toEqual({result: {statements: [{
                kind: 'Select',
                select: {...token(0, 5), columns: [{kind: 'Column', column: identifier('name', 7, 10)}]},
                from: {...token(12, 15), table: identifier('users', 17, 21)},
                ...token(0, 22)
            }]}})
        })
        test('complex', () => {
            expect(removeTokens(parsePostgresAst('SELECT id, first_name AS name FROM users WHERE id = 1;'))).toEqual({result: {statements: [{
                kind: 'Select',
                select: {columns: [
                    {kind: 'Column', column: {kind: 'Identifier', value: 'id'}},
                    {kind: 'Column', column: {kind: 'Identifier', value: 'first_name'}, alias: {name: {kind: 'Identifier', value: 'name'}}}
                ]},
                from: {table: {kind: 'Identifier', value: 'users'}},
                where: {predicate: {kind: 'Operation', left: {kind: 'Column', column: {kind: 'Identifier', value: 'id'}}, op: {kind: '='}, right: {kind: 'Integer', value: 1}}}
            }]}})
        })
        test('strange', () => {
            expect(parsePostgresAst("SELECT pg_catalog.set_config('search_path', '', false);")).toEqual({result: {statements: [{
                kind: 'Select',
                select: {...token(0, 5), columns: [{
                    kind: 'Function',
                    schema: identifier('pg_catalog', 7, 16),
                    function: identifier('set_config', 18, 27),
                    parameters: [string('search_path', 29, 41), string('', 44, 45), boolean(false, 48, 52)]
                }]},
                ...token(0, 54)
            }]}})
        })
    })
    describe('setStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SET lock_timeout = 0;')).toEqual({result: {statements: [
                {kind: 'Set', ...token(0, 20), parameter: identifier('lock_timeout', 4, 15), equal: {kind: '=', ...token(17, 17)}, value: integer(0, 19, 19)}
            ]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('SET SESSION search_path TO my_schema, public;')).toEqual({result: {statements: [
                {kind: 'Set', ...token(0, 44), scope: {kind: 'Session', ...token(4, 10)}, parameter: identifier('search_path', 12, 22), equal: {kind: 'To', ...token(24, 25)}, value: [identifier('my_schema', 27, 35), identifier('public', 38, 43)]}
            ]}})
        })
        test('on', () => {
            expect(parsePostgresAst('SET standard_conforming_strings = on;')).toEqual({result: {statements: [
                {kind: 'Set', ...token(0, 36), parameter: identifier('standard_conforming_strings', 4, 30), equal: {kind: '=', ...token(32, 32)}, value: identifier('on', 34, 35)}
            ]}})
        })
    })
    describe('clauses', () => {
        describe('selectClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.selectClauseRule(), 'SELECT name')).toEqual({result: {
                    ...token(0, 5),
                    columns: [{kind: 'Column', column: identifier('name', 7, 10)}],
                }})
            })
            test('complex', () => {
                expect(parseRule(p => p.selectClauseRule(), 'SELECT e.*, u.name AS user_name, lower(u.email), "public"."Event"."id"')).toEqual({result: {...token(0, 5), columns: [
                    {kind: 'Wildcard', table: identifier('e', 7, 7), ...token(9, 9)},
                    {kind: 'Column', table: identifier('u', 12, 12), column: identifier('name', 14, 17), alias: {...token(19, 20), name: identifier('user_name', 22, 30)}},
                    {kind: 'Function', function: identifier('lower', 33, 37), parameters: [{kind: 'Column', table: identifier('u', 39, 39), column: identifier('email', 41, 45)}]},
                    {kind: 'Column', schema: {...identifier('public', 49, 56), quoted: true}, table: {...identifier('Event', 58, 64), quoted: true}, column: {...identifier('id', 66, 69), quoted: true}}
                ]}})
            })
            // TODO: SELECT count(*), count(distinct e.created_by) FILTER (WHERE u.created_at + interval '#{period}' < e.created_at) AS not_new_users
        })
        describe('fromClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.fromClauseRule(), 'FROM users')).toEqual({result: {...token(0, 3), table: identifier('users', 5, 9)}})
            })
            test('table', () => {
                expect(parseRule(p => p.fromClauseRule(), 'FROM "users" as u')).toEqual({result: {
                    ...token(0, 3),
                    table: {...identifier('users', 5, 11), quoted: true},
                    alias: {...token(13, 14), name: identifier('u', 16, 16)},
                }})
            })
            // TODO: FROM (SELECT * FROM ...)
        })
        describe('whereClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.whereClauseRule(), 'WHERE id = 1')).toEqual({result: {
                    ...token(0, 4),
                    predicate: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 6, 7)}, op: operator('=', 9, 9), right: integer(1, 11, 11)},
                }})
            })
            test('complex', () => {
                expect(parseRule(p => p.whereClauseRule(), "WHERE \"id\" = $1 OR (email LIKE '%@azimutt.app' AND role = 'admin')")).toEqual({result: {...token(0, 4), predicate: {
                    kind: 'Operation',
                    left: {kind: 'Operation', left: {kind: 'Column', column: {...identifier('id', 6, 9), quoted: true}}, op: operator('=', 11, 11), right: parameter(1, 13, 14)},
                    op: operator('Or', 16, 17),
                    right: {
                        kind: 'Group',
                        expression: {
                            kind: 'Operation',
                            left: {kind: 'Operation', left: {kind: 'Column', column: identifier('email', 20, 24)}, op: operator('Like', 26, 29), right: string('%@azimutt.app', 31, 45)},
                            op: operator('And', 47, 49),
                            right: {kind: 'Operation', left: {kind: 'Column', column: identifier('role', 51, 54)}, op: operator('=', 56, 56), right: string('admin', 58, 64)}
                        }
                    }}}
                })
            })
        })
        describe('tableColumnRule', () => {
            test('simplest', () => {
                expect(parseRule(p => p.tableColumnRule(), 'id int')).toEqual({result: {name: identifier('id', 0, 1), type: {name: {value: 'int', ...token(3, 5)}, ...token(3, 5)}}})
            })
            test('not null & default', () => {
                expect(parseRule(p => p.tableColumnRule(), "role varchar NOT NULL DEFAULT 'guest'")).toEqual({result: {
                    name: identifier('role', 0, 3),
                    type: {name: {value: 'varchar', ...token(5, 11)}, ...token(5, 11)},
                    constraints: [{kind: 'Nullable', value: false, ...token(13, 20)}, {kind: 'Default', ...token(22, 28), expression: string('guest', 30, 36)}],
                }})
                expect(parseRule(p => p.tableColumnRule(), "role int DEFAULT 0 NOT NULL")).toEqual({result: {
                    name: identifier('role', 0, 3),
                    type: {name: {value: 'int', ...token(5, 7)}, ...token(5, 7)},
                    constraints: [{kind: 'Default', ...token(9, 15), expression: integer(0, 17, 17)}, {kind: 'Nullable', value: false, ...token(19, 26)}],
                }})
                expect(parseRule(p => p.tableColumnRule(), "role varchar DEFAULT 'guest'::character varying")).toEqual({result: {
                    name: identifier('role', 0, 3),
                    type: {name: {value: 'varchar', ...token(5, 11)}, ...token(5, 11)},
                    constraints: [{kind: 'Default', ...token(13, 19), expression: {...string('guest', 21, 27), cast: {...token(28, 29), type: {name: {value: 'character varying', ...token(30, 46)}, ...token(30, 46)}}}}],
                }})
            })
            test('primaryKey', () => {
                expect(parseRule(p => p.tableColumnRule(), 'id int PRIMARY KEY')).toEqual({result: {name: identifier('id', 0, 1), type: {name: {value: 'int', ...token(3, 5)}, ...token(3, 5)}, constraints: [
                    {kind: 'PrimaryKey', ...token(7, 17)}
                ]}})
            })
            test('unique', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar UNIQUE")).toEqual({result: {name: identifier('email', 0, 4), type: {name: {value: 'varchar', ...token(6, 12)}, ...token(6, 12)}, constraints: [
                    {kind: 'Unique', ...token(14, 19)}
                ]}})
            })
            test('check', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar CHECK (email LIKE '%@%')")).toEqual({result: {name: identifier('email', 0, 4), type: {name: {value: 'varchar', ...token(6, 12)}, ...token(6, 12)}, constraints: [
                    {kind: 'Check', ...token(14, 18), predicate: {kind: 'Operation', left: {kind: 'Column', column: identifier('email', 21, 25)}, op: operator('Like', 27, 30), right: string('%@%', 32, 36)}}
                ]}})
            })
            test('foreignKey', () => {
                expect(parseRule(p => p.tableColumnRule(), "author uuid REFERENCES users(id) ON DELETE SET NULL (id)")).toEqual({result: {name: identifier('author', 0, 5), type: {name: {value: 'uuid', ...token(7, 10)}, ...token(7, 10)}, constraints: [{
                    kind: 'ForeignKey',
                    ...token(12, 21),
                    table: identifier('users', 23, 27),
                    column: identifier('id', 29, 30),
                    onDelete: {...token(33, 41), action: {kind: 'SetNull', ...token(43, 50)}, columns: [identifier('id', 53, 54)]}
                }]}})
            })
            test('full', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar " +
                    "CONSTRAINT users_email_nn NOT NULL " +
                    "CONSTRAINT users_email_def DEFAULT 'anon@mail.com' " +
                    "CONSTRAINT users_pk PRIMARY KEY " +
                    "CONSTRAINT users_email_uniq UNIQUE " +
                    "CONSTRAINT users_email_chk CHECK (email LIKE '%@%') " +
                    "CONSTRAINT users_email_fk REFERENCES public.emails(id)")).toEqual({result: {
                        name: identifier('email', 0, 4),
                        type: {name: {value: 'varchar', ...token(6, 12)}, ...token(6, 12)},
                        constraints: [
                            {kind: 'Nullable', constraint: {...token(14, 23), name: identifier('users_email_nn', 25, 38)}, ...token(40, 47), value: false},
                            {kind: 'Default', constraint: {...token(49, 58), name: identifier('users_email_def', 60, 74)}, ...token(76, 82), expression: string('anon@mail.com', 84, 98)},
                            {kind: 'PrimaryKey', constraint: {...token(100, 109), name: identifier('users_pk', 111, 118)}, ...token(120, 130)},
                            {kind: 'Unique', constraint: {...token(132, 141), name: identifier('users_email_uniq', 143, 158)}, ...token(160, 165)},
                            {kind: 'Check', constraint: {...token(167, 176), name: identifier('users_email_chk', 178, 192)}, ...token(194, 198), predicate: {kind: 'Operation', left: {kind: 'Column', column: identifier('email', 201, 205)}, op: operator('Like', 207, 210), right: string('%@%', 212, 216)}},
                            {kind: 'ForeignKey', constraint: {...token(219, 228), name: identifier('users_email_fk', 230, 243)}, ...token(245, 254), schema: identifier('public', 256, 261), table: identifier('emails', 263, 268), column: identifier('id', 270, 271)},
                        ]
                    }})
            })
        })
        describe('tableConstraintRule', () => {
            test('primaryKey', () => {
                expect(parseRule(p => p.tableConstraintRule(), 'PRIMARY KEY (id)')).toEqual({result: {kind: 'PrimaryKey', ...token(0, 10), columns: [identifier('id', 13, 14)]}})
            })
            test('unique', () => {
                expect(parseRule(p => p.tableConstraintRule(), 'UNIQUE (first_name, last_name)')).toEqual({result: {kind: 'Unique', ...token(0, 5), columns: [identifier('first_name', 8, 17), identifier('last_name', 20, 28)]}})
            })
            // check is the same as the column
            test('foreignKey', () => {
                expect(parseRule(p => p.tableConstraintRule(), "FOREIGN KEY (author) REFERENCES users(id) ON DELETE SET NULL (author)")).toEqual({result: {
                    kind: 'ForeignKey',
                    ...token(0, 10),
                    columns: [identifier('author', 13, 18)],
                    ref: {
                        ...token(21, 30),
                        table: identifier('users', 32, 36),
                        columns: [identifier('id', 38, 39)],
                    },
                    onDelete: {...token(42, 50), action: {kind: 'SetNull', ...token(52, 59)}, columns: [identifier('author', 62, 67)]}
                }})
            })
        })
    })
    describe('basic parts', () => {
        describe('expressionRule', () => {
            test('literal', () => {
                expect(parseRule(p => p.expressionRule(), "'str'")).toEqual({result: string('str', 0, 4)})
                expect(parseRule(p => p.expressionRule(), '1')).toEqual({result: integer(1, 0, 0)})
                expect(parseRule(p => p.expressionRule(), '1.2')).toEqual({result: decimal(1.2, 0, 2)})
                expect(parseRule(p => p.expressionRule(), 'true')).toEqual({result: boolean(true, 0, 3)})
                expect(parseRule(p => p.expressionRule(), 'null')).toEqual({result: nulll(0, 3)})
            })
            test('column', () => {
                expect(parseRule(p => p.expressionRule(), 'id')).toEqual({result: {kind: 'Column', column: identifier('id', 0, 1)}})
                expect(parseRule(p => p.expressionRule(), 'users.id')).toEqual({result: {kind: 'Column', table: identifier('users', 0, 4), column: identifier('id', 6, 7)}})
                expect(parseRule(p => p.expressionRule(), 'public.users.id')).toEqual({result: {kind: 'Column', schema: identifier('public', 0, 5), table: identifier('users', 7, 11), column: identifier('id', 13, 14)}})
                expect(parseRule(p => p.expressionRule(), "settings->'category'->>'id'")).toEqual({result: {kind: 'Column', column: identifier('settings', 0, 7), json: [
                    {kind: '->', ...token(8, 9), field: string('category', 10, 19)},
                    {kind: '->>', ...token(20, 22), field: string('id', 23, 26)},
                ]}})
            })
            test('wildcard', () => {
                expect(parseRule(p => p.expressionRule(), '*')).toEqual({result: {kind: 'Wildcard', ...token(0, 0)}})
                expect(parseRule(p => p.expressionRule(), 'users.*')).toEqual({result: {kind: 'Wildcard', table: identifier('users', 0, 4), ...token(6, 6)}})
                expect(parseRule(p => p.expressionRule(), 'public.users.*')).toEqual({result: {kind: 'Wildcard', schema: identifier('public', 0, 5), table: identifier('users', 7, 11), ...token(13, 13)}})
            })
            test('function', () => {
                expect(parseRule(p => p.expressionRule(), 'max(price)')).toEqual({result: {kind: 'Function', function: identifier('max', 0, 2), parameters: [{kind: 'Column', column: identifier('price', 4, 8)}]}})
                expect(parseRule(p => p.expressionRule(), "pg_catalog.set_config('search_path', '', false)")).toEqual({result: {
                    kind: 'Function',
                    schema: identifier('pg_catalog', 0, 9),
                    function: identifier('set_config', 11, 20),
                    parameters: [string('search_path', 22, 34), string('', 37, 38), boolean(false, 41, 45)]
                }})
            })
            test('parameter', () => {
                expect(parseRule(p => p.expressionRule(), '?')).toEqual({result: parameter(0, 0, 0)})
                expect(parseRule(p => p.expressionRule(), '$1')).toEqual({result: parameter(1, 0, 1)})
            })
            test('group', () => {
                expect(parseRule(p => p.expressionRule(), '(1)')).toEqual({result: {kind: 'Group', expression: integer(1, 1, 1)}})
            })
            test('operation', () => {
                expect(parseRule(p => p.expressionRule(), '1 + 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('+', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 - 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('-', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 * 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('*', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 / 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('/', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 % 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('%', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 ^ 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('^', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 & 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('&', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 | 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('|', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 # 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('#', 2, 2), right: integer(1, 4, 4)}})
                expect(parseRule(p => p.expressionRule(), '1 << 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('<<', 2, 3), right: integer(1, 5, 5)}})
                expect(parseRule(p => p.expressionRule(), '1 >> 1')).toEqual({result: {kind: 'Operation', left: integer(1, 0, 0), op: operator('>>', 2, 3), right: integer(1, 5, 5)}})
                expect(parseRule(p => p.expressionRule(), 'id = 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('=', 3, 3), right: integer(1, 5, 5)}})
                expect(parseRule(p => p.expressionRule(), 'id < 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('<', 3, 3), right: integer(1, 5, 5)}})
                expect(parseRule(p => p.expressionRule(), 'id > 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('>', 3, 3), right: integer(1, 5, 5)}})
                expect(parseRule(p => p.expressionRule(), 'id <= 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('<=', 3, 4), right: integer(1, 6, 6)}})
                expect(parseRule(p => p.expressionRule(), 'id >= 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('>=', 3, 4), right: integer(1, 6, 6)}})
                expect(parseRule(p => p.expressionRule(), 'id <> 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('<>', 3, 4), right: integer(1, 6, 6)}})
                expect(parseRule(p => p.expressionRule(), 'id != 1')).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('id', 0, 1)}, op: operator('!=', 3, 4), right: integer(1, 6, 6)}})
                expect(parseRule(p => p.expressionRule(), "'a' || 'b'")).toEqual({result: {kind: 'Operation', left: string('a', 0, 2), op: operator('||', 4, 5), right: string('b', 7, 9)}})
                expect(parseRule(p => p.expressionRule(), "'a' ~ 'b'")).toEqual({result: {kind: 'Operation', left: string('a', 0, 2), op: operator('~', 4, 4), right: string('b', 6, 8)}})
                expect(parseRule(p => p.expressionRule(), "'a' ~* 'b'")).toEqual({result: {kind: 'Operation', left: string('a', 0, 2), op: operator('~*', 4, 5), right: string('b', 7, 9)}})
                expect(parseRule(p => p.expressionRule(), "'a' !~ 'b'")).toEqual({result: {kind: 'Operation', left: string('a', 0, 2), op: operator('!~', 4, 5), right: string('b', 7, 9)}})
                expect(parseRule(p => p.expressionRule(), "'a' !~* 'b'")).toEqual({result: {kind: 'Operation', left: string('a', 0, 2), op: operator('!~*', 4, 6), right: string('b', 8, 10)}})
                expect(parseRule(p => p.expressionRule(), "name LIKE 'a_%'")).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('name', 0, 3)}, op: operator('Like', 5, 8), right: string('a_%', 10, 14)}})
                expect(parseRule(p => p.expressionRule(), "name NOT LIKE 'a_%'")).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('name', 0, 3)}, op: operator('NotLike', 5, 12), right: string('a_%', 14, 18)}})
                expect(parseRule(p => p.expressionRule(), "role IN ('author', 'editor')")).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('role', 0, 3)}, op: operator('In', 5, 6), right: list([string('author', 9, 16), string('editor', 19, 26)])}})
                expect(parseRule(p => p.expressionRule(), "role NOT IN ('author', 'editor')")).toEqual({result: {kind: 'Operation', left: {kind: 'Column', column: identifier('role', 0, 3)}, op: operator('NotIn', 5, 10), right: list([string('author', 13, 20), string('editor', 23, 30)])}})
                expect(parseRule(p => p.expressionRule(), 'true OR true')).toEqual({result: {kind: 'Operation', left: boolean(true, 0, 3), op: operator('Or', 5, 6), right: boolean(true, 8, 11)}})
                expect(parseRule(p => p.expressionRule(), 'true AND true')).toEqual({result: {kind: 'Operation', left: boolean(true, 0, 3), op: operator('And', 5, 7), right: boolean(true, 9, 12)}})
                // TODO: and many more... ^^
            })
            /*test('unary operation', () => {
                // TODO
                expect(parseRule(p => p.expressionRule(), '~1')).toEqual({result: {kind: 'UnaryOp', op: operator('~', 0, 0), expression: integer(1, 1, 1)}})
                expect(parseRule(p => p.expressionRule(), 'NOT true')).toEqual({result: {kind: 'UnaryOp', op: operator('Not', 0, 2), expression: boolean(true, 4, 7)}})
                expect(parseRule(p => p.expressionRule(), 'id ISNULL')).toEqual({result: {kind: 'UnaryOp', op: operator('IsNull', 3, 9), expression: {kind: 'Column', column: identifier('id', 0, 1)}}})
                expect(parseRule(p => p.expressionRule(), 'id IS NULL')).toEqual({result: {kind: 'UnaryOp', op: operator('IsNull', 3, 10), expression: {kind: 'Column', column: identifier('id', 0, 1)}}})
                expect(parseRule(p => p.expressionRule(), 'id NOTNULL')).toEqual({result: {kind: 'UnaryOp', op: operator('IsNotNull', 3, 14), expression: {kind: 'Column', column: identifier('id', 0, 1)}}})
                expect(parseRule(p => p.expressionRule(), 'id IS NOT NULL')).toEqual({result: {kind: 'UnaryOp', op: operator('IsNotNull', 3, 10), expression: {kind: 'Column', column: identifier('id', 0, 1)}}})
            })*/
            test('cast', () => {
                expect(parseRule(p => p.expressionRule(), "'owner'::character varying"))
                    .toEqual({result: {...string('owner', 0, 6), cast: {...token(7, 8), type: {name: {value: 'character varying', ...token(9, 25)}, ...token(9, 25)}}}})
            })
            test('complex', () => {
                const id = (value: string) => ({kind: 'Identifier', value})
                const int = (value: number) => ({kind: 'Integer', value})
                const col = (column: string) => ({kind: 'Column', column: id(column)})
                const p = (value: string) => ({kind: 'Parameter', value})
                const op = (left: any, kind: string, right: any) => ({kind: 'Operation', left, op: {kind}, right})
                const g = (expression: any) => ({kind: 'Group', expression})
                expect(removeTokens(parseRule(p => p.expressionRule(), 'id'))).toEqual({result: col('id')})
                expect(removeTokens(parseRule(p => p.expressionRule(), 'id = 0'))).toEqual({result: op(col('id'), '=', int(0))})
                expect(removeTokens(parseRule(p => p.expressionRule(), 'id = 0 OR id = ?'))).toEqual({result: op(op(col('id'), '=', int(0)), 'Or', op(col('id'), '=', p('?')))})
                expect(removeTokens(parseRule(p => p.expressionRule(), '(id = 0) OR (id = ?)'))).toEqual({result: op(g(op(col('id'), '=', int(0))), 'Or', g(op(col('id'), '=', p('?'))))})
            })
        })
        describe('objectNameRule', () => {
            test('object only', () => {
                expect(parseRule(p => p.objectNameRule(), 'users')).toEqual({result: {name: identifier('users', 0, 4)}})
            })
            test('object and schema', () => {
                expect(parseRule(p => p.objectNameRule(), 'public.users')).toEqual({result: {schema: identifier('public', 0, 5), name: identifier('users', 7, 11)}})
            })
        })
        describe('columnTypeRule', () => {
            test('simplest', () => {
                expect(parseRule(p => p.columnTypeRule(), 'int')).toEqual({result: {name: {value: 'int', ...token(0, 2)}, ...token(0, 2)}})
            })
            test('with space', () => {
                expect(parseRule(p => p.columnTypeRule(), 'character varying')).toEqual({result: {name: {value: 'character varying', ...token(0, 16)}, ...token(0, 16)}})
            })
            test('with args', () => {
                expect(parseRule(p => p.columnTypeRule(), 'character(255)')).toEqual({result: {name: {value: 'character(255)', ...token(0, 13)}, args: [integer(255, 10, 12)], ...token(0, 13)}})
                expect(parseRule(p => p.columnTypeRule(), 'NUMERIC(2, -3)')).toEqual({result: {name: {value: 'NUMERIC(2, -3)', ...token(0, 13)}, args: [integer(2, 8, 8), integer(-3, 11, 12)], ...token(0, 13)}})
            })
            test('array', () => {
                expect(parseRule(p => p.columnTypeRule(), 'int[]')).toEqual({result: {name: {value: 'int[]', ...token(0, 4)}, array: token(3, 4), ...token(0, 4)}})
            })
            test('with time zone', () => {
                expect(parseRule(p => p.columnTypeRule(), 'timestamp with time zone')).toEqual({result: {name: {value: 'timestamp with time zone', ...token(0, 23)}, ...token(0, 23)}})
                expect(parseRule(p => p.columnTypeRule(), 'timestamp without time zone')).toEqual({result: {name: {value: 'timestamp without time zone', ...token(0, 26)}, ...token(0, 26)}})
            })
            test('with time zone and args', () => {
                expect(parseRule(p => p.columnTypeRule(), 'timestamp(0) without time zone'))
                    .toEqual({result: {name: {value: 'timestamp(0) without time zone', ...token(0, 29)}, args: [integer(0, 10, 10)], ...token(0, 29)}})
            })
            test('with schema', () => {
                expect(parseRule(p => p.columnTypeRule(), 'public.citext')).toEqual({result: {schema: identifier('public', 0, 5), name: {value: 'citext', ...token(7, 12)}, ...token(0, 12)}})
            })
            // TODO: intervals
        })
        describe('literalRule', () => {
            test('string', () => {
                expect(parseRule(p => p.literalRule(), "'id'")).toEqual({result: {kind: 'String', value: 'id', ...token(0, 3)}})
            })
            test('decimal', () => {
                expect(parseRule(p => p.literalRule(), '3.14')).toEqual({result: {kind: 'Decimal', value: 3.14, ...token(0, 3)}})
                expect(parseRule(p => p.literalRule(), '-3.14')).toEqual({result: {kind: 'Decimal', value: -3.14, ...token(0, 4)}})
            })
            test('integer', () => {
                expect(parseRule(p => p.literalRule(), '3')).toEqual({result: {kind: 'Integer', value: 3, ...token(0, 0)}})
                expect(parseRule(p => p.literalRule(), '-3')).toEqual({result: {kind: 'Integer', value: -3, ...token(0, 1)}})
            })
            test('boolean', () => {
                expect(parseRule(p => p.literalRule(), 'true')).toEqual({result: {kind: 'Boolean', value: true, ...token(0, 3)}})
            })
        })
    })
    describe('elements', () => {
        describe('parameterRule', () => {
            test('anonymous', () => {
                expect(parseRule(p => p.parameterRule(), '?')).toEqual({result: {kind: 'Parameter', value: '?', ...token(0, 0)}})
            })
            test('indexed', () => {
                expect(parseRule(p => p.parameterRule(), '$1')).toEqual({result: {kind: 'Parameter', value: '$1', index: 1, ...token(0, 1)}})
            })
        })
        describe('identifierRule', () => {
            test('basic', () => {
                expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: identifier('id', 0, 1)})
            })
            test('quoted', () => {
                expect(parseRule(p => p.identifierRule(), '"an id"')).toEqual({result: {...identifier('an id', 0, 6), quoted: true}})
            })
            test('with quote', () => {
                expect(parseRule(p => p.identifierRule(), '"an id with \\""')).toEqual({result: {...identifier('an id with "', 0, 14), quoted: true}})
            })
            test('not empty', () => {
                expect(parseRule(p => p.identifierRule(), '""')).toEqual({errors: [
                    {kind: 'LexingError', level: 'error', message: 'unexpected character: ->"<- at offset: 0, skipped 2 characters.', ...token(0, 2)},
                    {kind: 'NoViableAltException', level: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Identifier]\n  2. [Index]\n  3. [Version]\nbut found: ''", ...token(-1, -1, -1, -1, -1, -1)}
                ]})
            })
            test('special', () => {
                expect(parseRule(p => p.identifierRule(), 'version')).toEqual({result: identifier('version', 0, 6)})
            })
        })
        describe('stringRule', () => {
            test('basic', () => {
                expect(parseRule(p => p.stringRule(), "'value'")).toEqual({result: string('value', 0, 6)})
            })
            test('empty', () => {
                expect(parseRule(p => p.stringRule(), "''")).toEqual({result: string('', 0, 1)})
            })
            test('escape quote', () => {
                expect(parseRule(p => p.stringRule(), "'l''id'")).toEqual({result: string("l'id", 0, 6)})
            })
            test('escape quote start & end', () => {
                expect(parseRule(p => p.stringRule(), "'''id'''")).toEqual({result: string("'id'", 0, 7)})
            })
            test('escape quote quote', () => {
                expect(parseRule(p => p.stringRule(), "''''")).toEqual({result: string("'", 0, 3)})
            })
            test('escaped', () => {
                expect(parseRule(p => p.stringRule(), "E'value\\nmulti\\nline'")).toEqual({result: {...string('value\\nmulti\\nline', 0, 20), escaped: true}})
            })
        })
        describe('integerRule', () => {
            test('0', () => {
                expect(parseRule(p => p.integerRule(), '0')).toEqual({result: integer(0, 0, 0)})
            })
            test('number', () => {
                expect(parseRule(p => p.integerRule(), '12')).toEqual({result: integer(12, 0, 1)})
            })
        })
        describe('decimalRule', () => {
            test('0', () => {
                expect(parseRule(p => p.decimalRule(), '0.0')).toEqual({result: decimal(0, 0, 2)})
            })
            test('number', () => {
                expect(parseRule(p => p.decimalRule(), '3.14')).toEqual({result: decimal(3.14, 0, 3)})
            })
        })
        describe('booleanRule', () => {
            test('true', () => {
                expect(parseRule(p => p.booleanRule(), 'true')).toEqual({result: boolean(true, 0, 3)})
            })
            test('false', () => {
                expect(parseRule(p => p.booleanRule(), 'false')).toEqual({result: boolean(false, 0, 4)})
            })
        })
    })
})

function identifier(value: string, start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): IdentifierAst {
    return {kind: 'Identifier', value, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function string(value: string, start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): StringAst {
    return {kind: 'String', value, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function integer(value: number, start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): IntegerAst {
    return {kind: 'Integer', value, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function decimal(value: number, start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): DecimalAst {
    return {kind: 'Decimal', value, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function boolean(value: boolean, start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): BooleanAst {
    return {kind: 'Boolean', value, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function nulll(start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): NullAst {
    return {kind: 'Null', ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function parameter(index: number, start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): ParameterAst {
    return {kind: 'Parameter', value: index ? `$${index}` : '?', index: index ? index : undefined, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function list(items: LiteralAst[]): ListAst {
    return {kind: 'List', items}
}

function operator(kind: OperatorAst['kind'], start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number): OperatorAst {
    return {kind, ...token(start, end, startLine, startColumn, endLine, endColumn)}
}

function token(start: number, end: number, startLine?: number, startColumn?: number, endLine?: number, endColumn?: number, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({
        offset: {start, end},
        position: {
            start: {line: startLine === undefined ? 1 : startLine, column: startColumn === undefined ? start + 1 : startColumn},
            end: {line: endLine === undefined ? 1 : endLine, column: endColumn === undefined ? end + 1 : endColumn}},
        issues
    })
}

function removeTokens<T>(ast: T): T {
    return removeFieldsDeep(ast, ['offset', 'position'])
}
