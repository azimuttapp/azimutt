import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {removeEmpty, removeFieldsDeep, removeUndefined} from "@azimutt/utils";
import {
    AliasAst,
    BooleanAst,
    ColumnAst,
    DecimalAst,
    ExpressionAst,
    FunctionAst,
    GroupAst,
    IdentifierAst,
    IntegerAst,
    ListAst,
    LiteralAst,
    NullAst,
    OperationAst,
    OperationLeftAst,
    OperationRightAst,
    Operator,
    OperatorAst,
    OperatorLeft,
    OperatorLeftAst,
    OperatorRight,
    OperatorRightAst,
    ParameterAst,
    StringAst,
    TokenInfo,
    TokenIssue,
    WildcardAst
} from "./postgresAst";
import {parsePostgresAst, parseRule} from "./postgresParser";

describe('postgresParser', () => {
    // TODO: CREATE FUNCTION
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
    test.skip('statements', () => {
        const sql = fs.readFileSync('./resources/pg_statements.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
        // medium:
        // TODO:1362 `(u0."created_at" > $3::timestamp + (-($4)::numeric * interval $5))`
        // TODO:2155 `ARRAY(SELECT a.atttypid)`
        // TODO:1639 `SELECT CASE con.confupdtype WHEN $3 THEN $4 ELSE $15 END AS UPDATE_RULE`
        // TODO:2010 `SELECT CASE n.nspname ~ $2 OR n.nspname = $3 WHEN $4 THEN CASE ELSE $51 END AS TABLE_TYPE`
        // TODO:1862 `SELECT ("public"."Event"."details" #>> array [$1]::text[])::text AS "details → source"` (also: 1962)
        // TODO:1415 `SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` (also: 1934)
        // TODO:321  `SHOW TRANSACTION ISOLATION LEVEL;` (also: 1694)
        // hard:
        // TODO:12   `(information_schema._pg_expandarray(i.indkey)).n`
        // TODO:847  `select (current_schemas($3))[s.r] as nspname` (also: 1057)
        // TODO:326  `SELECT ... FROM (VALUES ($2, ($3)::text), ($4, ($5)::text)) as v(key, val)` (also: 1169)
    })
    test.skip('plausible', () => {
        const sql = fs.readFileSync('./resources/plausible.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
        // TODO:73  `CREATE FUNCTION`
        // TODO:246 `features character varying(255)[] DEFAULT ARRAY['props'::character varying, 'stats_api'::character varying] NOT NULL`
        // TODO:542 `recipients public.citext[] DEFAULT ARRAY[]::public.citext[] NOT NULL`
        // TODO:575 `errors jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,`
    })
    test.skip('other structures', async () => {
        const structures = ['https://raw.githubusercontent.com/plausible/analytics/refs/heads/master/priv/repo/structure.sql']
        await Promise.all(structures.map(async url => {
            const sql = await fetch(url).then(res => res.text())
            const parsed = parsePostgresAst(sql, {strict: true})
            if ((parsed.errors || []).length > 0) {
                console.log(`Error in ${url}`)
                expect(parsed.errors || []).toEqual([])
            }
        }))
    })
    describe('alterSequence', () => {
        test('simplest', () => {
            expect(parsePostgresAst('ALTER SEQUENCE users_id_seq OWNED BY users.id;')).toEqual({result: {statements: [{
                ...stmt('AlterSequence', 0, 13, 45),
                name: identifier('users_id_seq', 15),
                ownedBy: {token: token(28, 35), owner: {kind: 'Column', table: identifier('users', 37), column: identifier('id', 43)}}
            }]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('ALTER SEQUENCE IF EXISTS public.users_id_seq AS integer START WITH 1 INCREMENT BY 1 MINVALUE 1 NO MAXVALUE CACHE 1 OWNED BY users.id;')).toEqual({result: {statements: [{
                ...stmt('AlterSequence', 0, 13, 132),
                ifExists: token(15, 23),
                schema: identifier('public', 25),
                name: identifier('users_id_seq', 32),
                as: {token: token(45, 46), type: identifier('integer', 48)},
                start: {token: token(56, 65), value: integer(1, 67)},
                increment: {token: token(69, 80), value: integer(1, 82)},
                minValue: {token: token(84, 91), value: integer(1, 93)},
                maxValue: {token: token(95, 105)},
                cache: {token: token(107, 111), value: integer(1, 113)},
                ownedBy: {token: token(115, 122), owner: {kind: 'Column', table: identifier('users', 124), column: identifier('id', 130)}}
            }]}})
        })
    })
    describe('alterTable', () => {
        test('full', () => {
            expect(parsePostgresAst('ALTER TABLE IF EXISTS ONLY public.users ADD CONSTRAINT users_pk PRIMARY KEY (id);')).toEqual({result: {statements: [{
                ...stmt('AlterTable', 0, 10, 80),
                ifExists: token(12, 20),
                only: token(22, 25),
                schema: identifier('public', 27),
                table: identifier('users', 34),
                action: {...kind('AddConstraint', 40, 42), constraint: {constraint: {token: token(44, 53), name: identifier('users_pk', 55)}, ...kind('PrimaryKey', 64, 74), columns: [identifier('id', 77)]}},
            }]}})
        })
        test('add column', () => {
            expect(parsePostgresAst('ALTER TABLE users ADD author int;')).toEqual({result: {statements: [{
                ...stmt('AlterTable', 0, 10, 32),
                table: identifier('users', 12),
                action: {...kind('AddColumn', 18, 20), column: {name: identifier('author', 22), type: {name: {value: 'int', token: token(29, 31)}, token: token(29, 31)}}},
            }]}})
        })
        test('drop column', () => {
            expect(parsePostgresAst('ALTER TABLE users DROP author;')).toEqual({result: {statements: [{
                ...stmt('AlterTable', 0, 10, 29),
                table: identifier('users', 12),
                action: {...kind('DropColumn', 18, 21), column: identifier('author', 23)},
            }]}})
        })
        test('add primaryKey', () => {
            expect(parsePostgresAst('ALTER TABLE users ADD PRIMARY KEY (id);')).toEqual({result: {statements: [{
                ...stmt('AlterTable', 0, 10, 38),
                table: identifier('users', 12),
                action: {...kind('AddConstraint', 18, 20), constraint: {...kind('PrimaryKey', 22, 32), columns: [identifier('id', 35)]}},
            }]}})
        })
        test('drop primaryKey', () => {
            expect(parsePostgresAst('ALTER TABLE users DROP CONSTRAINT users_pk;')).toEqual({result: {statements: [{
                ...stmt('AlterTable', 0, 10, 42),
                table: identifier('users', 12),
                action: {...kind('DropConstraint', 18, 32), constraint: identifier('users_pk', 34)},
            }]}})
        })
    })
    describe('begin', () => {
        test('simplest', () => {
            expect(parsePostgresAst("BEGIN;")).toEqual({result: {statements: [stmt('Begin', 0, 4, 5)]}})
        })
        test('complex', () => {
            expect(parsePostgresAst("BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED, READ ONLY, NOT DEFERRABLE;")).toEqual({result: {statements: [{
                ...stmt('Begin', 0, 4, 75),
                object: kind('Transaction', 6),
                modes: [
                    {...kind('IsolationLevel', 18, 32), level: kind('ReadCommitted', 34, 47)},
                    kind('ReadOnly', 50, 58),
                    {not: token(61, 63), ...kind('Deferrable', 65, 74)},
                ]
            }]}})
        })
    })
    describe('commentOn', () => {
        test('simplest', () => {
            expect(parsePostgresAst("COMMENT ON SCHEMA public IS 'Main schema';")).toEqual({result: {statements: [{
                ...stmt('CommentOn', 0, 9, 41),
                object: kind('Schema', 11),
                entity: identifier('public', 18),
                comment: string('Main schema', 28),
            }]}})
        })
        test('table', () => {
            expect(parsePostgresAst("COMMENT ON TABLE public.users IS 'List users';")).toEqual({result: {statements: [{
                ...stmt('CommentOn', 0, 9, 45),
                object: kind('Table', 11),
                schema: identifier('public', 17),
                entity: identifier('users', 24),
                comment: string('List users', 33),
            }]}})
        })
        test('column', () => {
            expect(parsePostgresAst("COMMENT ON COLUMN public.users.name IS 'user name';")).toEqual({result: {statements: [{
                ...stmt('CommentOn', 0, 9, 50),
                object: kind('Column', 11),
                schema: identifier('public', 18),
                parent: identifier('users', 25),
                entity: identifier('name', 31),
                comment: string('user name', 39),
            }]}})
        })
        test('constraint', () => {
            expect(parsePostgresAst("COMMENT ON CONSTRAINT users_pk ON public.users IS 'users pk';")).toEqual({result: {statements: [{
                ...stmt('CommentOn', 0, 9, 60),
                object: kind('Constraint', 11),
                entity: identifier('users_pk', 22),
                schema: identifier('public', 34),
                parent: identifier('users', 41),
                comment: string('users pk', 50),
            }]}})
        })
    })
    describe('commit', () => {
        test('simplest', () => {
            expect(parsePostgresAst("COMMIT;")).toEqual({result: {statements: [stmt('Commit', 0, 5, 6)]}})
        })
        test('complex', () => {
            expect(parsePostgresAst("COMMIT WORK AND NO CHAIN;")).toEqual({result: {statements: [{
                ...stmt('Commit', 0, 5, 24),
                object: kind('Work', 7),
                chain: {token: token(12, 23), no: token(16, 17)},
            }]}})
        })
    })
    describe('createExtension', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE EXTENSION citext;')).toEqual({result: {statements: [{
                ...stmt('CreateExtension', 0, 15, 23),
                name: identifier('citext', 17),
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst("CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public VERSION '1.0' CASCADE;")).toEqual({result: {statements: [{
                ...stmt('CreateExtension', 0, 15, 78),
                ifNotExists: token(17, 29),
                name: identifier('citext', 31),
                with: token(38, 41),
                schema: {token: token(43, 48), name: identifier('public', 50)},
                version: {token: token(57, 63), number: string('1.0', 65)},
                cascade: token(71, 77),
            }]}})
        })
    })
    describe.skip('createFunction', () => {
        test('using SQL query', () => {
            expect(parsePostgresAst("CREATE FUNCTION add(integer, integer) RETURNS integer AS 'select $1 + $2;' LANGUAGE SQL IMMUTABLE RETURNS NULL ON NULL INPUT;")).toEqual({result: {statements: [{
                ...stmt('CreateFunction', 0, 11, 28),
                table: identifier('users', 16),
                columns: [column('name', 23)],
            }]}})
        })
        test('using SQL', () => {
            expect(parsePostgresAst('CREATE FUNCTION add(a integer, b integer) RETURNS integer LANGUAGE SQL IMMUTABLE RETURNS NULL ON NULL INPUT RETURN a + b;')).toEqual({result: {statements: [{
                ...stmt('CreateFunction', 0, 11, 28),
                table: identifier('users', 16),
                columns: [column('name', 23)],
            }]}})
        })
        test('using plSQL', () => {
            expect(parsePostgresAst('CREATE OR REPLACE FUNCTION increment(i integer) RETURNS integer AS $$ BEGIN RETURN i + 1; END; $$ LANGUAGE plpgsql;')).toEqual({result: {statements: [{
                ...stmt('CreateFunction', 0, 11, 28),
                table: identifier('users', 16),
                columns: [column('name', 23)],
            }]}})
        })
    })
    describe('createIndex', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE INDEX ON users (name);')).toEqual({result: {statements: [{
                ...stmt('CreateIndex', 0, 11, 28),
                table: identifier('users', 16),
                columns: [column('name', 23)],
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst('CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS users_name_idx ON ONLY public.users USING btree' +
                ' ((lower(first_name)) COLLATE "de_DE" ASC NULLS LAST)' +
                // TODO: ' INCLUDE (email) NULLS NOT DISTINCT WITH (fastupdate = off) TABLESPACE indexspace WHERE deleted_at IS NULL' +
                ' INCLUDE (email);'
            )).toEqual({result: {statements: [{
                ...stmt('CreateIndex', 0, 18, 163),
                unique: token(7, 12),
                concurrently: token(20, 31),
                ifNotExists: token(33, 45),
                index: identifier('users_name_idx', 47),
                only: token(65, 68),
                schema: identifier('public', 70),
                table: identifier('users', 77),
                using: {token: token(83, 87), method: identifier('btree', 89)},
                columns: [{
                    kind: 'Group',
                    expression: function_('lower', 97, [column('first_name', 103)]),
                    collation: {token: token(116, 122), name: {...identifier('de_DE', 124, 130), quoted: true}},
                    order: kind('Asc', 132),
                    nulls: kind('Last', 136, 145)
                }],
                include: {token: token(148, 154), columns: [identifier('email', 157)]},
                // where: {token: token(0, 0), predicate: {???}}
            }]}})
        })
    })
    describe('createMaterializedView', () => {
        test('simplest', () => {
            expect(parsePostgresAst("CREATE MATERIALIZED VIEW admins AS SELECT * FROM users WHERE role='admin';")).toEqual({result: {statements: [{
                ...stmt('CreateMaterializedView', 0, 23, 73),
                name: identifier('admins', 25),
                query: {
                    token: token(35, 40),
                    columns: [wildcard(42)],
                    from: {...kind('Table', 44, 47), table: identifier('users', 49)},
                    where: {token: token(55, 59), predicate: operation(column('role', 61), op('=', 65), string('admin',  66))},
                }
            }]}})
        })
    })
    describe('createSequence', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE SEQUENCE users_id_seq;')).toEqual({result: {statements: [{
                ...stmt('CreateSequence', 0, 14, 28),
                name: identifier('users_id_seq', 16)
            }]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('CREATE UNLOGGED SEQUENCE IF NOT EXISTS public.users_id_seq AS integer START WITH 1 INCREMENT BY 1 MINVALUE 1 NO MAXVALUE CACHE 1 OWNED BY users.id;')).toEqual({result: {statements: [{
                ...stmt('CreateSequence', 0, 23, 146),
                mode: kind('Unlogged', 7),
                ifNotExists: token(25, 37),
                schema: identifier('public', 39),
                name: identifier('users_id_seq', 46),
                as: {token: token(59, 60), type: identifier('integer', 62)},
                start: {token: token(70, 79), value: integer(1, 81)},
                increment: {token: token(83, 94), value: integer(1, 96)},
                minValue: {token: token(98, 105), value: integer(1, 107)},
                maxValue: {token: token(109, 119)},
                cache: {token: token(121, 125), value: integer(1, 127)},
                ownedBy: {token: token(129, 136), owner: {kind: 'Column', table: identifier('users', 138), column: identifier('id', 144)}}
            }]}})
        })
    })
    describe('createTable', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE TABLE users (id int PRIMARY KEY, name VARCHAR);')).toEqual({result: {statements: [{
                ...stmt('CreateTable', 0, 11, 53),
                name: identifier('users', 13),
                columns: [
                    {name: identifier('id', 20), type: {name: {value: 'int', token: token(23, 25)}, token: token(23, 25)}, constraints: [kind('PrimaryKey', 27, 37)]},
                    {name: identifier('name', 40), type: {name: {value: 'VARCHAR', token: token(45, 51)}, token: token(45, 51)}},
                ],
            }]}})
        })
        test('with constraints', () => {
            expect(parsePostgresAst('CREATE TABLE users (id int, role VARCHAR, CONSTRAINT users_pk PRIMARY KEY (id), FOREIGN KEY (role) REFERENCES roles (name));')).toEqual({result: {statements: [{
                ...stmt('CreateTable', 0, 11, 123),
                name: identifier('users', 13),
                columns: [
                    {name: identifier('id', 20), type: {name: {value: 'int', token: token(23, 25)}, token: token(23, 25)}},
                    {name: identifier('role', 28), type: {name: {value: 'VARCHAR', token: token(33, 39)}, token: token(33, 39)}},
                ],
                constraints: [
                    {constraint: {token: token(42, 51), name: identifier('users_pk', 53)}, ...kind('PrimaryKey', 62, 72), columns: [identifier('id', 75)]},
                    {...kind('ForeignKey', 80, 90), columns: [identifier('role', 93)], ref: {token: token(99, 108), table: identifier('roles', 110), columns: [identifier('name', 117)]}}
                ],
            }]}})
        })
        // TODO: CREATE TABLE IF NOT EXISTS users (id int);
        // TODO: CREATE UNLOGGED TABLE users (id int);
    })
    describe('createType', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE TYPE position;')).toEqual({result: {statements: [{
                ...stmt('CreateType', 0, 10, 20),
                name: identifier('position', 12),
            }]}})
        })
        test('struct', () => {
            expect(parsePostgresAst('CREATE TYPE layout_position AS (x int, y int COLLATE "fr_FR");')).toEqual({result: {statements: [{
                ...stmt('CreateType', 0, 10, 61),
                name: identifier('layout_position', 12),
                struct: {token: token(28, 29), attrs: [
                    {name: identifier('x', 32), type: {name: {value: 'int', token: token(34, 36)}, token: token(34, 36)}},
                    {name: identifier('y', 39), type: {name: {value: 'int', token: token(41, 43)}, token: token(41, 43)}, collation: {token: token(45, 51), name: {...identifier('fr_FR', 53, 59), quoted: true}}}
                ]},
            }]}})
        })
        test('enum', () => {
            expect(parsePostgresAst("CREATE TYPE public.bug_status AS ENUM ('open', 'closed');")).toEqual({result: {statements: [{
                ...stmt('CreateType', 0, 10, 56),
                schema: identifier('public', 12),
                name: identifier('bug_status', 19),
                enum: {token: token(30, 36), values: [string('open', 39), string('closed', 47)]},
            }]}})
        })
        // TODO: range
        test('base', () => {
            expect(parsePostgresAst("CREATE TYPE box (INPUT = my_box_in_function, OUTPUT = my_box_out_function, INTERNALLENGTH = 16);")).toEqual({result: {statements: [{
                ...stmt('CreateType', 0, 10, 95),
                name: identifier('box', 12),
                base: [
                    // FIXME: expressions should be different here (identifier instead of column), or better, each parameter should have its own kind of value...
                    {name: identifier('INPUT', 17), value: column('my_box_in_function', 25)},
                    {name: identifier('OUTPUT', 45), value: column('my_box_out_function', 54)},
                    {name: identifier('INTERNALLENGTH', 75), value: integer(16, 92)},
                ],
            }]}})
        })
    })
    describe('createView', () => {
        test('simplest', () => {
            expect(parsePostgresAst("CREATE VIEW admins AS SELECT * FROM users WHERE role = 'admin';")).toEqual({result: {statements: [{
                ...stmt('CreateView', 0, 10, 62),
                name: identifier('admins', 12),
                query: {
                    token: token(22, 27),
                    columns: [wildcard(29)],
                    from: {token: token(31, 34), kind: 'Table', table: identifier('users', 36)},
                    where: {token: token(42, 46), predicate: operation(column('role', 48), op('=', 53), string('admin', 55))},
                },
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst("CREATE OR REPLACE TEMP RECURSIVE VIEW admins (id, name) AS SELECT * FROM users WHERE role = 'admin';")).toEqual({result: {statements: [{
                ...stmt('CreateView', 0, 36, 99),
                replace: token(7, 16),
                temporary: token(18, 21),
                recursive: token(23, 31),
                name: identifier('admins', 38),
                columns: [identifier('id', 46), identifier('name', 50)],
                query: {
                    token: token(59, 64),
                    columns: [wildcard(66)],
                    from: {token: token(68, 71), kind: 'Table', table: identifier('users', 73)},
                    where: {token: token(79, 83), predicate: operation(column('role', 85), op('=', 90), string('admin', 92))},
                },
            }]}})
        })
    })
    describe('delete', () => {
        test('simplest', () => {
            expect(parsePostgresAst('DELETE FROM films;')).toEqual({result: {statements: [{
                ...stmt('Delete', 0, 10, 17),
                table: identifier('films', 12),
            }]}})
        })
        test('complex', () => {
            expect(parsePostgresAst("DELETE FROM ONLY public.tasks * t WHERE t.status = 'DONE' RETURNING *;")).toEqual({result: {statements: [{
                ...stmt('Delete', 0, 10, 69),
                only: token(12, 15),
                schema: identifier('public', 17),
                table: identifier('tasks', 24),
                descendants: token(30, 30),
                alias: alias('t', 32),
                where: {token: token(34, 38), predicate: operation(column('status', 40, 't'), op('=', 49), string('DONE', 51))},
                returning: {token: token(58, 66), columns: [wildcard(68)]}
            }]}})
        })
        test('using', () => {
            expect(parsePostgresAst("DELETE FROM films USING producers WHERE producer_id = producers.id AND producers.name = 'foo';")).toEqual({result: {statements: [{
                ...stmt('Delete', 0, 10, 93),
                table: identifier('films', 12),
                using: {token: token(18, 22), kind: 'Table', table: identifier('producers', 24)},
                where: {token: token(34, 38), predicate: operation(
                    operation(column('producer_id', 40), op('=', 52), column('id', 54, 'producers')),
                    op('And', 67),
                    operation(column('name', 71, 'producers'), op('=', 86), string('foo', 88))
                )}
            }]}})
        })
    })
    describe('drop', () => {
        test('simplest', () => {
            expect(parsePostgresAst('DROP TABLE users;')).toEqual({result: {statements: [{
                ...stmt('Drop', 0, 9, 16),
                object: 'Table',
                entities: [{name: identifier('users', 11)}],
            }]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('DROP INDEX CONCURRENTLY IF EXISTS users_idx, posts_idx CASCADE;')).toEqual({result: {statements: [{
                ...stmt('Drop', 0, 9, 62),
                object: 'Index',
                concurrently: token(11, 22),
                ifExists: token(24, 32),
                entities: [{name: identifier('users_idx', 34)}, {name: identifier('posts_idx', 45)}],
                mode: kind('Cascade', 55),
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
    describe('insertInto', () => {
        test('simplest', () => {
            expect(parsePostgresAst("INSERT INTO users VALUES (1, 'loic');")).toEqual({result: {statements: [{
                ...stmt('InsertInto', 0, 10, 36),
                table: identifier('users', 12),
                values: [[integer(1, 26), string('loic', 29)]],
            }]}})
        })
        test('full', () => {
            expect(parsePostgresAst("INSERT INTO users (id, name) VALUES (1, 'loic'), (DEFAULT, 'lou') RETURNING id;")).toEqual({result: {statements: [{
                ...stmt('InsertInto', 0, 10, 78),
                table: identifier('users', 12),
                columns: [identifier('id', 19), identifier('name', 23)],
                values: [[integer(1, 37), string('loic', 40)], [kind('Default', 50), string('lou', 59)]],
                returning: {token: token(66, 74), columns: [column('id', 76)]},
            }]}})
        })
        test('conflict', () => {
            expect(parsePostgresAst("INSERT INTO users VALUES (1, 'loic') ON CONFLICT DO NOTHING;")).toEqual({result: {statements: [{
                ...stmt('InsertInto', 0, 10, 59),
                table: identifier('users', 12),
                values: [[integer(1, 26), string('loic', 29)]],
                onConflict: {token: token(37, 47), action: kind('Nothing', 49, 58)}
            }]}})
            expect(parsePostgresAst("INSERT INTO users VALUES (1, 'loic') ON CONFLICT (id) WHERE id > 10 DO UPDATE SET name = EXCLUDED.name WHERE users.role='guest';")).toEqual({result: {statements: [{
                ...stmt('InsertInto', 0, 10, 127),
                table: identifier('users', 12),
                values: [[integer(1, 26), string('loic', 29)]],
                onConflict: {
                    token: token(37, 47),
                    target: {
                        kind: 'Columns',
                        columns: [identifier('id', 50)],
                        where: {token: token(54, 58), predicate: operation(column('id', 60), op('>', 63), integer(10, 65))}
                    },
                    action: {
                        ...kind('Update', 68, 76),
                        columns: [{column: identifier('name', 82), value: column('name', 89, 'EXCLUDED')}],
                        where: {token: token(103, 107), predicate: operation(column('role', 109, 'users'), op('=', 119), string('guest', 120))}
                    }
                }
            }]}})
        })
        // TODO: `INSERT INTO films SELECT * FROM tmp_films WHERE date_prod < '2004-05-07';`
    })
    describe('select', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SELECT name FROM users;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 22),
                columns: [column('name', 7)],
                from: {token: token(12, 15), kind: 'Table', table: identifier('users', 17)},
            }]}})
        })
        test('complex', () => {
            const id = (value: string) => ({kind: 'Identifier', value})
            const int = (value: number) => ({kind: 'Integer', value})
            const op = (left: any, op: Operator, right: any) => ({kind: 'Operation', left, op: {kind: op}, right})
            expect(removeTokens(parsePostgresAst('SELECT u.id, first_name AS name FROM public.users u WHERE u.id = 1 LIMIT 10 OFFSET 20;'))).toEqual({result: {statements: [{
                kind: 'Select',
                columns: [
                    {kind: 'Column', table: id('u'), column: id('id')},
                    {kind: 'Column', column: id('first_name'), alias: {name: id('name')}}
                ],
                from: {kind: 'Table', schema: id('public'), table: id('users'), alias: {name: id('u')}},
                where: {predicate: op({kind: 'Column', table: id('u'), column: id('id')}, '=', int(1))},
                limit: {value: int(10)},
                offset: {value: int(20)},
            }]}})
        })
        test('select only', () => {
            expect(parsePostgresAst("SELECT pg_catalog.set_config('search_path', '', false);")).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 54),
                columns: [function_('set_config', 7, [string('search_path', 29), string('', 44), boolean(false, 48)], 'pg_catalog')],
            }]}})
        })
        test('join', () => {
            expect(parsePostgresAst(
                'SELECT * FROM events e JOIN users u ON e.created_by=u.id' +
                ' LEFT OUTER JOIN public.projects AS p USING (project_id) AS jp' +
                ' NATURAL CROSS JOIN demo;'
            )).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 142),
                columns: [wildcard(7)],
                from: {token: token(9, 12), kind: 'Table', table: identifier('events', 14), alias: alias('e', 21), joins: [{
                    ...kind('Inner', 23, 26),
                    from: {kind: 'Table', table: identifier('users', 28), alias: alias('u', 34)},
                    on: {...kind('On', 36), predicate: operation(column('created_by', 39, 'e'), op('=', 51), column('id', 52, 'u'))}
                }, {
                    ...kind('Left', 57, 71),
                    from: {kind: 'Table', schema: identifier('public', 73), table: identifier('projects', 80), alias: alias('p', 92, 89)},
                    on: {...kind('Using', 94), columns: [identifier('project_id', 101)]},
                    alias: alias('jp', 116, 113)
                }, {
                    ...kind('Cross', 127, 136),
                    from: {kind: 'Table', table: identifier('demo', 138)},
                    on: kind('Natural', 119)
                }]}
            }]}})
        })
        test('group by', () => {
            // TODO interval: expect(parsePostgresAst("SELECT kind, sum(len) AS total FROM films GROUP BY kind HAVING sum(len) < interval '5 hours' ORDER BY kind;")).toEqual({result: {statements: [{
            expect(parsePostgresAst("SELECT kind, sum(len) AS total FROM films GROUP BY kind HAVING sum(len) <          '5 hours' ORDER BY kind DESC;")).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 111),
                columns: [column('kind', 7), {...function_('sum', 13, [column('len', 17)]), alias: alias('total', 25, 22)}],
                from: {token: token(31, 34), kind: 'Table', table: identifier('films', 36)},
                groupBy: {token: token(42, 49), expressions: [column('kind', 51)]},
                having: {token: token(56, 61), predicate: operation(function_('sum', 63, [column('len', 67)]), op('<', 72), string('5 hours', 83))},
                orderBy: {token: token(93, 100), expressions: [{...column('kind', 102), order: kind('Desc', 107)}]}
            }]}})
        })
        test('distinct', () => {
            expect(parsePostgresAst('SELECT DISTINCT name, email FROM users;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 38),
                distinct: {token: token(7, 14)},
                columns: [column('name', 16), column('email', 22)],
                from: {token: token(28, 31), kind: 'Table', table: identifier('users', 33)}
            }]}})
            expect(parsePostgresAst('SELECT DISTINCT ON (email) name, email FROM users;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 49),
                distinct: {token: token(7, 14), on: {token: token(16, 17), columns: [column('email', 20)]}},
                columns: [column('name', 27), column('email', 33)],
                from: {token: token(39, 42), kind: 'Table', table: identifier('users', 44)}
            }]}})
        })
        test('from select', () => {
            expect(parsePostgresAst('SELECT * FROM (SELECT * FROM users) u WHERE id = 1;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 50),
                columns: [wildcard(7)],
                from: {
                    token: token(9, 12),
                    kind: 'Select',
                    select: {
                        token: token(15, 20),
                        columns: [wildcard(22)],
                        from: {token: token(24, 27), kind: 'Table', table: identifier('users', 29)},
                    },
                    alias: alias('u', 36)
                },
                where: {token: token(38, 42), predicate: operation(column('id', 44), op('=', 47), integer(1, 49))}
            }]}})
        })
        test('union', () => {
            expect(parsePostgresAst('SELECT name FROM users UNION ALL SELECT name FROM organizations;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 63),
                columns: [column('name', 7)],
                from: {token: token(12, 15), kind: 'Table', table: identifier('users', 17)},
                union: {...kind('Union', 23), mode: kind('All', 29), select: {
                    token: token(33, 38),
                    columns: [column('name', 40)],
                    from: {token: token(45, 48), kind: 'Table', table: identifier('organizations', 50)},
                }}
            }]}})
        })
        test('filter', () => {
            expect(parsePostgresAst('SELECT count(*) AS user_count, count(*) FILTER (WHERE spend > 5000) AS top_user_count FROM users;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 96),
                columns: [{...function_('count', 7, [wildcard(13)]), alias: alias('user_count', 19, 16)}, {
                    ...function_('count', 31, [wildcard(37)]),
                    filter: {token: token(40, 45), where: {token: token(48, 52), predicate: operation(column('spend', 54), op('>', 60), integer(5000, 62))}},
                    alias: alias('top_user_count', 71, 68)
                }],
                from: {token: token(86, 89), kind: 'Table', table: identifier('users', 91)}
            }]}})
        })
        test('window', () => {
            expect(parsePostgresAst('SELECT org, salary, avg(salary) OVER (PARTITION BY org ORDER BY salary DESC) FROM users;')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 87),
                columns: [column('org', 7), column('salary', 12), {...function_('avg', 20, [column('salary', 24)]), over: {
                    token: token(32, 35),
                    partitionBy: {token: token(38, 49), columns: [column('org', 51)]},
                    orderBy: {token: token(55, 62), expressions: [{...column('salary', 64), order: kind('Desc', 71)}]}
                }}],
                from: {token: token(77, 80), kind: 'Table', table: identifier('users', 82)}
            }]}})
            expect(parsePostgresAst('SELECT org, salary, avg(salary) OVER org_window FROM users WINDOW org_window AS (PARTITION BY org ORDER BY salary DESC);')).toEqual({result: {statements: [{
                ...stmt('Select', 0, 5, 119),
                columns: [column('org', 7), column('salary', 12), {...function_('avg', 20, [column('salary', 24)]), over: {token: token(32, 35), name: identifier('org_window', 37)}}],
                from: {token: token(48, 51), kind: 'Table', table: identifier('users', 53)},
                window: [{
                    token: token(59, 64),
                    name: identifier('org_window', 66),
                    partitionBy: {token: token(81, 92), columns: [column('org', 94)]},
                    orderBy: {token: token(98, 105), expressions: [{...column('salary', 107), order: kind('Desc', 114)}]}
                }]
            }]}})
        })
        test('flexible parenthesis', () => {
            expect(parsePostgresAst('(SELECT * FROM ((SELECT name FROM users) UNION (SELECT name FROM organizations)));')).toEqual({result: {statements: [{
                ...stmt('Select', 1, 6, 81),
                columns: [wildcard(8)],
                from: {token: token(10, 13), kind: 'Select', select: {
                    token: token(17, 22),
                    columns: [column('name', 24)],
                    from: {token: token(29, 32), kind: 'Table', table: identifier('users', 34)},
                    union: {...kind('Union', 41), select: {
                        token: token(48, 53),
                        columns: [column('name', 55)],
                        from: {token: token(60, 63), kind: 'Table', table: identifier('organizations', 65)},
                    }}
                }}
            }]}})
            expect(parsePostgresAst('(SELECT * FROM ((SELECT name FROM users LIMIT 1) UNION (SELECT name FROM organizations LIMIT 1)));').errors).toEqual(undefined)
            expect(parsePostgresAst('(SELECT * FROM users WHERE role=0 ORDER BY id LIMIT 1 OFFSET 0 FETCH FIRST 1 ROW ONLY);').errors).toEqual(undefined)
            // expect(parsePostgresAst('(SELECT * FROM users WHERE role=0 ORDER BY id LIMIT 1 OFFSET 0) FETCH FIRST 1 ROW ONLY;').errors).toEqual(undefined)
            // expect(parsePostgresAst('(SELECT * FROM users WHERE role=0 ORDER BY id LIMIT 1) OFFSET 0 FETCH FIRST 1 ROW ONLY;').errors).toEqual(undefined)
            // expect(parsePostgresAst('(SELECT * FROM users WHERE role=0 ORDER BY id) LIMIT 1 OFFSET 0 FETCH FIRST 1 ROW ONLY;').errors).toEqual(undefined)
            // expect(parsePostgresAst('(SELECT * FROM users WHERE role=0) ORDER BY id LIMIT 1 OFFSET 0 FETCH FIRST 1 ROW ONLY;').errors).toEqual(undefined)
        })
        test.skip('common table expression', () => {
            expect(parsePostgresAst('WITH t AS (SELECT random() as x FROM generate_series(1, 3)) SELECT * FROM t UNION ALL SELECT * FROM t;')).toEqual({result: {statements: []}})
            expect(removeTokens(parsePostgresAst("WITH RECURSIVE employee_recursive(distance, employee_name, manager_name) AS (\n" +
                "    SELECT 1, employee_name, manager_name FROM employee WHERE manager_name = 'Mary'\n" +
                "  UNION ALL\n" +
                "    SELECT er.distance + 1, e.employee_name, e.manager_name FROM employee_recursive er, employee e WHERE er.employee_name = e.manager_name\n" +
                ")\n" +
                "SELECT distance, employee_name FROM employee_recursive;"))).toEqual({result: {statements: []}})
        })
    })
    describe('set', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SET lock_timeout = 0;')).toEqual({result: {statements: [
                {...stmt('Set', 0, 2, 20), parameter: identifier('lock_timeout', 4), equal: kind('=', 17), value: integer(0, 19)}
            ]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('SET SESSION search_path TO my_schema, public;')).toEqual({result: {statements: [
                {...stmt('Set', 0, 2, 44), scope: kind('Session', 4), parameter: identifier('search_path', 12), equal: kind('To', 24), value: [identifier('my_schema', 27), identifier('public', 38)]}
            ]}})
        })
        test('no equal', () => {
            expect(parsePostgresAst("SET ROLE 'admin';")).toEqual({result: {statements: [
                {...stmt('Set', 0, 2, 16), parameter: identifier('ROLE', 4), value: string('admin', 9)}
            ]}})
        })
        test('on', () => {
            expect(parsePostgresAst('SET standard_conforming_strings = on;')).toEqual({result: {statements: [
                {...stmt('Set', 0, 2, 36), parameter: identifier('standard_conforming_strings', 4), equal: kind('=', 32), value: identifier('on', 34)}
            ]}})
        })
    })
    describe('show', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SHOW block_size;')).toEqual({result: {statements: [{
                ...stmt('Show', 0, 3, 15),
                name: identifier('block_size', 5)
            }]}})
        })
        test.skip('complex', () => {
            expect(parsePostgresAst('SHOW TRANSACTION ISOLATION LEVEL;')).toEqual({result: {statements: [{
                ...stmt('Show', 0, 3, 32),
                name: identifier('TRANSACTION ISOLATION LEVEL', 5)
            }]}})
        })
    })
    describe('update', () => {
        test('simplest', () => {
            expect(parsePostgresAst("UPDATE films SET kind = 'Dramatic' WHERE kind = 'Drama';")).toEqual({result: {statements: [{
                ...stmt('Update', 0, 5, 55),
                table: identifier('films', 7),
                columns: [ { column: identifier('kind', 17), value: string('Dramatic', 24) } ],
                where: {token: token(35, 39), predicate: {kind: 'Operation', left: column('kind', 41), op: op('=', 46), right: string('Drama', 48)}}
            }]}})
            // UPDATE weather SET temp_lo = temp_lo + 1, prcp = DEFAULT WHERE city = 'San Francisco' RETURNING temp_lo;
            // UPDATE weather SET (temp_lo, prcp) = (temp_lo+1, DEFAULT) WHERE city = 'San Francisco';
            // UPDATE employees SET sales_count = sales_count + 1 FROM accounts WHERE accounts.name = 'Acme' AND employees.id = accounts.sales_person;
            // UPDATE employees SET sales_count = sales_count + 1 WHERE id = (SELECT sales_person FROM accounts WHERE name = 'Acme');
            // UPDATE accounts SET (first_name, last_name) = (SELECT first_name, last_name FROM employees WHERE employees.id = accounts.sales_person);
        })
    })
    describe('clauses', () => {
        describe('selectClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.selectClauseRule(), 'SELECT name')).toEqual({result: {
                    token: token(0, 5),
                    columns: [column('name', 7)],
                }})
            })
            test('complex', () => {
                expect(parseRule(p => p.selectClauseRule(), 'SELECT e.*, u.name AS user_name, lower(u.email), "public"."Event"."id"')).toEqual({result: {token: token(0, 5), columns: [
                    {table: identifier('e', 7), ...wildcard(9)},
                    {...column('name', 12, 'u'), alias: alias('user_name', 22, 19)},
                    function_('lower', 33, [column('email', 39, 'u')]),
                    {kind: 'Column', schema: {...identifier('public', 49, 56), quoted: true}, table: {...identifier('Event', 58, 64), quoted: true}, column: {...identifier('id', 66, 69), quoted: true}}
                ]}})
            })
            // TODO: SELECT count(*), count(distinct e.created_by) FILTER (WHERE u.created_at + interval '#{period}' < e.created_at) AS not_new_users
        })
        describe('fromClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.fromClauseRule(), 'FROM users')).toEqual({result: {token: token(0, 3), kind: 'Table', table: identifier('users', 5)}})
            })
            test('table', () => {
                expect(parseRule(p => p.fromClauseRule(), 'FROM "users" as u')).toEqual({result: {
                    token: token(0, 3),
                    kind: 'Table',
                    table: {...identifier('users', 5, 11), quoted: true},
                    alias: alias('u', 16, 13),
                }})
            })
            // TODO: FROM (SELECT * FROM ...)
        })
        describe('whereClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.whereClauseRule(), 'WHERE id = 1')).toEqual({result: {
                    token: token(0, 4),
                    predicate: operation(column('id', 6), op('=', 9), integer(1, 11)),
                }})
            })
            test('complex', () => {
                expect(parseRule(p => p.whereClauseRule(), "WHERE \"id\" = $1 OR (email LIKE '%@azimutt.app' AND role = 'admin')")).toEqual({result: {token: token(0, 4), predicate: operation(
                    operation({kind: 'Column', column: {...identifier('id', 6, 9), quoted: true}}, op('=', 11), parameter(1, 13)),
                    op('Or', 16),
                    group(operation(
                        operation(column('email', 20), op('Like', 26), string('%@azimutt.app', 31)),
                        op('And', 47),
                        operation(column('role', 51), op('=', 56), string('admin', 58))
                    ))
                )}})
            })
        })
        describe('tableColumnRule', () => {
            test('simplest', () => {
                expect(parseRule(p => p.tableColumnRule(), 'id int')).toEqual({result: {name: identifier('id', 0), type: {name: {value: 'int', token: token(3, 5)}, token: token(3, 5)}}})
            })
            test('not null & default', () => {
                expect(parseRule(p => p.tableColumnRule(), "role varchar NOT NULL DEFAULT 'guest'")).toEqual({result: {
                    name: identifier('role', 0),
                    type: {name: {value: 'varchar', token: token(5, 11)}, token: token(5, 11)},
                    constraints: [{...kind('Nullable', 13, 20), value: false}, {...kind('Default', 22), expression: string('guest', 30)}],
                }})
                expect(parseRule(p => p.tableColumnRule(), "role int DEFAULT 0 NOT NULL")).toEqual({result: {
                    name: identifier('role', 0),
                    type: {name: {value: 'int', token: token(5, 7)}, token: token(5, 7)},
                    constraints: [{...kind('Default', 9), expression: integer(0, 17)}, {...kind('Nullable', 19, 26), value: false}],
                }})
                expect(parseRule(p => p.tableColumnRule(), "role varchar DEFAULT 'guest'::character varying")).toEqual({result: {
                    name: identifier('role', 0),
                    type: {name: {value: 'varchar', token: token(5, 11)}, token: token(5, 11)},
                    constraints: [{...kind('Default', 13), expression: {...string('guest', 21), cast: {token: token(28, 29), type: {name: {value: 'character varying', token: token(30, 46)}, token: token(30, 46)}}}}],
                }})
            })
            test('primaryKey', () => {
                expect(parseRule(p => p.tableColumnRule(), 'id int PRIMARY KEY')).toEqual({result: {name: identifier('id', 0), type: {name: {value: 'int', token: token(3, 5)}, token: token(3, 5)}, constraints: [
                    kind('PrimaryKey', 7, 17)
                ]}})
            })
            test('unique', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar UNIQUE")).toEqual({result: {name: identifier('email', 0), type: {name: {value: 'varchar', token: token(6, 12)}, token: token(6, 12)}, constraints: [
                    kind('Unique', 14)
                ]}})
            })
            test('check', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar CHECK (email LIKE '%@%')")).toEqual({result: {name: identifier('email', 0), type: {name: {value: 'varchar', token: token(6, 12)}, token: token(6, 12)}, constraints: [
                    {...kind('Check', 14), predicate: operation(column('email', 21), op('Like', 27), string('%@%', 32))}
                ]}})
            })
            test('foreignKey', () => {
                expect(parseRule(p => p.tableColumnRule(), "author uuid REFERENCES users(id) ON DELETE SET NULL (id)")).toEqual({result: {name: identifier('author', 0), type: {name: {value: 'uuid', token: token(7, 10)}, token: token(7, 10)}, constraints: [{
                    ...kind('ForeignKey', 12, 21),
                    table: identifier('users', 23),
                    column: identifier('id', 29),
                    onDelete: {token: token(33, 41), action: kind('SetNull', 43, 50), columns: [identifier('id', 53)]}
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
                        name: identifier('email', 0),
                        type: {name: {value: 'varchar', token: token(6, 12)}, token: token(6, 12)},
                        constraints: [
                            {constraint: {token: token(14, 23), name: identifier('users_email_nn', 25)}, ...kind('Nullable', 40, 47), value: false},
                            {constraint: {token: token(49, 58), name: identifier('users_email_def', 60)}, ...kind('Default', 76), expression: string('anon@mail.com', 84)},
                            {constraint: {token: token(100, 109), name: identifier('users_pk', 111)}, ...kind('PrimaryKey', 120, 130)},
                            {constraint: {token: token(132, 141), name: identifier('users_email_uniq', 143)}, ...kind('Unique', 160, 165)},
                            {constraint: {token: token(167, 176), name: identifier('users_email_chk', 178)}, ...kind('Check', 194), predicate: operation(column('email', 201), op('Like', 207), string('%@%', 212))},
                            {constraint: {token: token(219, 228), name: identifier('users_email_fk', 230)}, ...kind('ForeignKey', 245, 254), schema: identifier('public', 256), table: identifier('emails', 263), column: identifier('id', 270)},
                        ]
                    }})
            })
        })
        describe('tableConstraintRule', () => {
            test('primaryKey', () => {
                expect(parseRule(p => p.tableConstraintRule(), 'PRIMARY KEY (id)')).toEqual({result: {...kind('PrimaryKey', 0, 10), columns: [identifier('id', 13)]}})
            })
            test('unique', () => {
                expect(parseRule(p => p.tableConstraintRule(), 'UNIQUE (first_name, last_name)')).toEqual({result: {...kind('Unique', 0), columns: [identifier('first_name', 8), identifier('last_name', 20)]}})
            })
            // check is the same as the column
            test('foreignKey', () => {
                expect(parseRule(p => p.tableConstraintRule(), "FOREIGN KEY (author) REFERENCES users(id) ON DELETE SET NULL (author)")).toEqual({result: {
                    ...kind('ForeignKey', 0, 10),
                    columns: [identifier('author', 13)],
                    ref: {
                        token: token(21, 30),
                        table: identifier('users', 32),
                        columns: [identifier('id', 38)],
                    },
                    onDelete: {token: token(42, 50), action: kind('SetNull', 52, 59), columns: [identifier('author', 62)]}
                }})
            })
        })
    })
    describe('basic parts', () => {
        describe('expressionRule', () => {
            test('literal', () => {
                expect(parseRule(p => p.expressionRule(), "'str'")).toEqual({result: string('str', 0)})
                expect(parseRule(p => p.expressionRule(), '1')).toEqual({result: integer(1, 0)})
                expect(parseRule(p => p.expressionRule(), '1.2')).toEqual({result: decimal(1.2, 0)})
                expect(parseRule(p => p.expressionRule(), 'true')).toEqual({result: boolean(true, 0)})
                expect(parseRule(p => p.expressionRule(), 'null')).toEqual({result: null_(0)})
            })
            test('column', () => {
                expect(parseRule(p => p.expressionRule(), 'id')).toEqual({result: column('id', 0)})
                expect(parseRule(p => p.expressionRule(), 'users.id')).toEqual({result: column('id', 0, 'users')})
                expect(parseRule(p => p.expressionRule(), 'public.users.id')).toEqual({result: column('id', 0, 'users', 'public')})
                expect(parseRule(p => p.expressionRule(), "settings->'category'->>'id'")).toEqual({result: {...column('settings', 0), json: [
                    {...kind('->', 8), field: string('category', 10)},
                    {...kind('->>', 20), field: string('id', 23)},
                ]}})
            })
            test('wildcard', () => {
                expect(parseRule(p => p.expressionRule(), '*')).toEqual({result: wildcard(0)})
                expect(parseRule(p => p.expressionRule(), 'users.*')).toEqual({result: {table: identifier('users', 0), ...wildcard(6)}})
                expect(parseRule(p => p.expressionRule(), 'public.users.*')).toEqual({result: {schema: identifier('public', 0), table: identifier('users', 7), ...wildcard(13)}})
            })
            test('function', () => {
                expect(parseRule(p => p.expressionRule(), 'max(price)')).toEqual({result: function_('max', 0, [column('price', 4)])})
                expect(parseRule(p => p.expressionRule(), "pg_catalog.set_config('search_path', '', false)"))
                    .toEqual({result: function_('set_config', 0, [string('search_path', 22), string('', 37), boolean(false, 41)], 'pg_catalog')})
            })
            test('parameter', () => {
                expect(parseRule(p => p.expressionRule(), '?')).toEqual({result: parameter(0, 0)})
                expect(parseRule(p => p.expressionRule(), '$1')).toEqual({result: parameter(1, 0)})
            })
            test('group', () => {
                expect(parseRule(p => p.expressionRule(), '(1)')).toEqual({result: group(integer(1, 1))})
            })
            test('operation', () => {
                expect(parseRule(p => p.expressionRule(), '1 + 1')).toEqual({result: operation(integer(1, 0), op('+', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 - 1')).toEqual({result: operation(integer(1, 0), op('-', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 * 1')).toEqual({result: operation(integer(1, 0), op('*', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 / 1')).toEqual({result: operation(integer(1, 0), op('/', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 % 1')).toEqual({result: operation(integer(1, 0), op('%', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 ^ 1')).toEqual({result: operation(integer(1, 0), op('^', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 & 1')).toEqual({result: operation(integer(1, 0), op('&', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 | 1')).toEqual({result: operation(integer(1, 0), op('|', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 # 1')).toEqual({result: operation(integer(1, 0), op('#', 2), integer(1, 4))})
                expect(parseRule(p => p.expressionRule(), '1 << 1')).toEqual({result: operation(integer(1, 0), op('<<', 2), integer(1, 5))})
                expect(parseRule(p => p.expressionRule(), '1 >> 1')).toEqual({result: operation(integer(1, 0), op('>>', 2), integer(1, 5))})
                expect(parseRule(p => p.expressionRule(), 'id = 1')).toEqual({result: operation(column('id', 0), op('=', 3), integer(1, 5))})
                expect(parseRule(p => p.expressionRule(), 'id < 1')).toEqual({result: operation(column('id', 0), op('<', 3), integer(1, 5))})
                expect(parseRule(p => p.expressionRule(), 'id > 1')).toEqual({result: operation(column('id', 0), op('>', 3), integer(1, 5))})
                expect(parseRule(p => p.expressionRule(), 'id <= 1')).toEqual({result: operation(column('id', 0), op('<=', 3), integer(1, 6))})
                expect(parseRule(p => p.expressionRule(), 'id >= 1')).toEqual({result: operation(column('id', 0), op('>=', 3), integer(1, 6))})
                expect(parseRule(p => p.expressionRule(), 'id <> 1')).toEqual({result: operation(column('id', 0), op('<>', 3), integer(1, 6))})
                expect(parseRule(p => p.expressionRule(), 'id != 1')).toEqual({result: operation(column('id', 0), op('!=', 3), integer(1, 6))})
                expect(parseRule(p => p.expressionRule(), "'a' || 'b'")).toEqual({result: operation(string('a', 0), op('||', 4), string('b', 7))})
                expect(parseRule(p => p.expressionRule(), "'a' ~ 'b'")).toEqual({result: operation(string('a', 0), op('~', 4), string('b', 6))})
                expect(parseRule(p => p.expressionRule(), "'a' ~* 'b'")).toEqual({result: operation(string('a', 0), op('~*', 4), string('b', 7))})
                expect(parseRule(p => p.expressionRule(), "'a' !~ 'b'")).toEqual({result: operation(string('a', 0), op('!~', 4), string('b', 7))})
                expect(parseRule(p => p.expressionRule(), "'a' !~* 'b'")).toEqual({result: operation(string('a', 0), op('!~*', 4), string('b', 8))})
                expect(parseRule(p => p.expressionRule(), "name IS NULL")).toEqual({result: operation(column('name', 0), op('Is', 5), null_(8))})
                expect(parseRule(p => p.expressionRule(), "name LIKE 'a_%'")).toEqual({result: operation(column('name', 0), op('Like', 5), string('a_%', 10))})
                expect(parseRule(p => p.expressionRule(), "name NOT LIKE 'a_%'")).toEqual({result: operation(column('name', 0), op('NotLike', 5, 12), string('a_%', 14))})
                expect(parseRule(p => p.expressionRule(), "role IN ('author', 'editor')")).toEqual({result: operation(column('role', 0), op('In', 5), list([string('author', 9), string('editor', 19)]))})
                expect(parseRule(p => p.expressionRule(), "role NOT IN ('author', 'editor')")).toEqual({result: operation(column('role', 0), op('NotIn', 5, 10), list([string('author', 13), string('editor', 23)]))})
                // TODO: expect(parseRule(p => p.expressionRule(), "role IN (SELECT id FROM roles)")).toEqual({result: operation(column('role', 0), op('In', 5), list([string('author', 9), string('editor', 19)]))})
                expect(parseRule(p => p.expressionRule(), 'true OR true')).toEqual({result: operation(boolean(true, 0), op('Or', 5), boolean(true, 8))})
                expect(parseRule(p => p.expressionRule(), 'true AND true')).toEqual({result: operation(boolean(true, 0), op('And', 5), boolean(true, 9))})
                // TODO: and many more... ^^
            })
            test('left operation', () => {
                expect(parseRule(p => p.expressionRule(), 'NOT NULL')).toEqual({result: operationLeft(opLeft('Not', 0), null_(4))})
                expect(parseRule(p => p.expressionRule(), '~1')).toEqual({result: operationLeft(opLeft('~', 0), integer(1, 1))})
            })
            test('right operation', () => {
                expect(parseRule(p => p.expressionRule(), 'id ISNULL')).toEqual({result: operationRight(column('id', 0), opRight('IsNull', 3))})
                expect(parseRule(p => p.expressionRule(), 'id NOTNULL')).toEqual({result: operationRight(column('id', 0), opRight('NotNull', 3))})
            })
            test('mixed operation', () => {
                expect(parseRule(p => p.expressionRule(), 'name IS NOT NULL')).toEqual({result: operation(column('name', 0), op('Is', 5), operationLeft(opLeft('Not', 8), null_(12)))})
            })
            test('cast', () => {
                expect(parseRule(p => p.expressionRule(), "'owner'::character varying"))
                    .toEqual({result: {...string('owner', 0), cast: {token: token(7, 8), type: {name: {value: 'character varying', token: token(9, 25)}, token: token(9, 25)}}}})
            })
            test('complex', () => {
                const i = (value: string) => ({kind: 'Identifier', value})
                const n = (value: number) => ({kind: 'Integer', value})
                const c = (column: string, table?: string) => removeUndefined({kind: 'Column', table: table ? i(table) : undefined, column: i(column)})
                const f = (name: string, parameters: any[]) => ({kind: 'Function', function: i(name), parameters})
                const p = (value: string) => ({kind: 'Parameter', value, index: value === '?' ? undefined : parseInt(value.slice(1))})
                const o = (left: any, kind: string, right: any) => ({kind: 'Operation', left, op: {kind}, right})
                const u = (kind: string, right: any) => ({kind: 'OperationLeft', op: {kind}, right})
                const g = (expression: any) => ({kind: 'Group', expression})
                const l = (items: any) => ({kind: 'List', items})
                const parse = (input: string) => removeTokens(parseRule(p => p.expressionRule(), input))
                expect(parse('id')).toEqual({result: c('id')})
                expect(parse('id = 0')).toEqual({result: o(c('id'), '=', n(0))})
                expect(parse('id = 0 OR id = ?')).toEqual({result: o(o(c('id'), '=', n(0)), 'Or', o(c('id'), '=', p('?')))})
                expect(parse('(id = 0) OR (id = ?)')).toEqual({result: o(g(o(c('id'), '=', n(0))), 'Or', g(o(c('id'), '=', p('?'))))})
                expect(parse('type IN ($2, $3) AND name NOT IN ($4, $5)')).toEqual({result: o(o(c('type'), 'In', l([p('$2'), p('$3')])), 'And', o(c('name'), 'NotIn', l([p('$4'), p('$5')])))})
                expect(parse('split_part(details ->> $1, $2, $3)')).toEqual({result: f('split_part', [{...c('details'), json: [{kind: '->>', field: p('$1')}]}, p('$2'), p('$3')])})
                expect(parse('$1 || queryid')).toEqual({result: o(p('$1'), '||', c('queryid'))})
                expect(parse('$1 || queryid ~ $2')).toEqual({result: o(o(p('$1'), '||', c('queryid')), '~', p('$2'))})
                expect(parse('count(distinct to_char(e.created_at, $2))')).toEqual({result: {...f('count', [f('to_char', [c('created_at', 'e'), p('$2')])]), distinct: {}}})
                expect(parse('e.created_at > NOW() - INTERVAL $3')).toEqual({result: o(o(c('created_at', 'e'), '>', f('NOW', [])), '-', u('Interval', p('$3')))})
            })
        })
        describe('objectNameRule', () => {
            test('object only', () => {
                expect(parseRule(p => p.objectNameRule(), 'users')).toEqual({result: {name: identifier('users', 0)}})
            })
            test('object and schema', () => {
                expect(parseRule(p => p.objectNameRule(), 'public.users')).toEqual({result: {schema: identifier('public', 0), name: identifier('users', 7)}})
            })
        })
        describe('columnTypeRule', () => {
            test('simplest', () => {
                expect(parseRule(p => p.columnTypeRule(), 'int')).toEqual({result: {name: {value: 'int', token: token(0, 2)}, token: token(0, 2)}})
            })
            test('with space', () => {
                expect(parseRule(p => p.columnTypeRule(), 'character varying')).toEqual({result: {name: {value: 'character varying', token: token(0, 16)}, token: token(0, 16)}})
            })
            test('with args', () => {
                expect(parseRule(p => p.columnTypeRule(), 'character(255)')).toEqual({result: {name: {value: 'character(255)', token: token(0, 13)}, args: [integer(255, 10)], token: token(0, 13)}})
                expect(parseRule(p => p.columnTypeRule(), 'NUMERIC(2, -3)')).toEqual({result: {name: {value: 'NUMERIC(2, -3)', token: token(0, 13)}, args: [integer(2, 8), integer(-3, 11)], token: token(0, 13)}})
            })
            test('array', () => {
                expect(parseRule(p => p.columnTypeRule(), 'int[]')).toEqual({result: {name: {value: 'int[]', token: token(0, 4)}, array: token(3, 4), token: token(0, 4)}})
            })
            test('with time zone', () => {
                expect(parseRule(p => p.columnTypeRule(), 'timestamp with time zone')).toEqual({result: {name: {value: 'timestamp with time zone', token: token(0, 23)}, token: token(0, 23)}})
                expect(parseRule(p => p.columnTypeRule(), 'timestamp without time zone')).toEqual({result: {name: {value: 'timestamp without time zone', token: token(0, 26)}, token: token(0, 26)}})
            })
            test('with time zone and args', () => {
                expect(parseRule(p => p.columnTypeRule(), 'timestamp(0) without time zone'))
                    .toEqual({result: {name: {value: 'timestamp(0) without time zone', token: token(0, 29)}, args: [integer(0, 10)], token: token(0, 29)}})
            })
            test('with schema', () => {
                expect(parseRule(p => p.columnTypeRule(), 'public.citext')).toEqual({result: {schema: identifier('public', 0), name: {value: 'citext', token: token(7, 12)}, token: token(0, 12)}})
            })
            // TODO: intervals
        })
        describe('literalRule', () => {
            test('string', () => {
                expect(parseRule(p => p.literalRule(), "'id'")).toEqual({result: {...kind('String', 0, 3), value: 'id'}})
            })
            test('decimal', () => {
                expect(parseRule(p => p.literalRule(), '3.14')).toEqual({result: {...kind('Decimal', 0, 3), value: 3.14}})
                expect(parseRule(p => p.literalRule(), '-3.14')).toEqual({result: {...kind('Decimal', 0, 4), value: -3.14}})
            })
            test('integer', () => {
                expect(parseRule(p => p.literalRule(), '3')).toEqual({result: {...kind('Integer', 0, 0), value: 3}})
                expect(parseRule(p => p.literalRule(), '-3')).toEqual({result: {...kind('Integer', 0, 1), value: -3}})
            })
            test('boolean', () => {
                expect(parseRule(p => p.literalRule(), 'true')).toEqual({result: {...kind('Boolean', 0, 3), value: true}})
            })
        })
    })
    describe('elements', () => {
        describe('parameterRule', () => {
            test('anonymous', () => {
                expect(parseRule(p => p.parameterRule(), '?')).toEqual({result: {...kind('Parameter', 0, 0), value: '?'}})
            })
            test('indexed', () => {
                expect(parseRule(p => p.parameterRule(), '$1')).toEqual({result: {...kind('Parameter', 0, 1), value: '$1', index: 1}})
            })
        })
        describe('identifierRule', () => {
            test('basic', () => {
                expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: identifier('id', 0)})
            })
            test('quoted', () => {
                expect(parseRule(p => p.identifierRule(), '"an id"')).toEqual({result: {...identifier('an id', 0, 6), quoted: true}})
            })
            test('with quote', () => {
                expect(parseRule(p => p.identifierRule(), '"an id with \\""')).toEqual({result: {...identifier('an id with "', 0, 14), quoted: true}})
            })
            test('not empty', () => {
                const specials = ['Data', 'Database', 'Deferrable', 'Index', 'Nulls', 'Rows', 'Schema', 'Type', 'Version']
                expect(parseRule(p => p.identifierRule(), '""')).toEqual({errors: [
                    {kind: 'LexingError', level: 'error', message: 'unexpected character: ->"<- at offset: 0, skipped 2 characters.', ...token(0, 2)},
                    {kind: 'NoViableAltException', level: 'error', message: `Expecting: one of these possible Token sequences:\n  1. [Identifier]${specials.map((n, i) => `\n  ${i + 2}. [${n}]`).join('')}\nbut found: ''`, offset: {start: -1, end: -1}, position: {start: {line: -1, column: -1}, end: {line: -1, column: -1}}}
                ]})
            })
            test('special', () => {
                expect(parseRule(p => p.identifierRule(), 'database')).toEqual({result: identifier('database', 0)})
                expect(parseRule(p => p.identifierRule(), 'index')).toEqual({result: identifier('index', 0)})
                expect(parseRule(p => p.identifierRule(), 'nulls')).toEqual({result: identifier('nulls', 0)})
                expect(parseRule(p => p.identifierRule(), 'rows')).toEqual({result: identifier('rows', 0)})
                expect(parseRule(p => p.identifierRule(), 'schema')).toEqual({result: identifier('schema', 0)})
                expect(parseRule(p => p.identifierRule(), 'type')).toEqual({result: identifier('type', 0)})
                expect(parseRule(p => p.identifierRule(), 'version')).toEqual({result: identifier('version', 0)})
            })
        })
        describe('stringRule', () => {
            test('basic', () => {
                expect(parseRule(p => p.stringRule(), "'value'")).toEqual({result: string('value', 0)})
            })
            test('empty', () => {
                expect(parseRule(p => p.stringRule(), "''")).toEqual({result: string('', 0)})
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
                expect(parseRule(p => p.integerRule(), '0')).toEqual({result: integer(0, 0)})
            })
            test('number', () => {
                expect(parseRule(p => p.integerRule(), '12')).toEqual({result: integer(12, 0)})
            })
        })
        describe('decimalRule', () => {
            test('0', () => {
                expect(parseRule(p => p.decimalRule(), '0.0')).toEqual({result: decimal(0, 0, 2)})
            })
            test('number', () => {
                expect(parseRule(p => p.decimalRule(), '3.14')).toEqual({result: decimal(3.14, 0)})
            })
        })
        describe('booleanRule', () => {
            test('true', () => {
                expect(parseRule(p => p.booleanRule(), 'true')).toEqual({result: boolean(true, 0)})
            })
            test('false', () => {
                expect(parseRule(p => p.booleanRule(), 'false')).toEqual({result: boolean(false, 0)})
            })
        })
    })
})

function op(kind: Operator, start: number, end?: number): OperatorAst {
    return {kind, token: token(start, end === undefined ? start + kind.length - 1 : end)}
}

function operation(left: ExpressionAst, op: OperatorAst, right: ExpressionAst): OperationAst {
    return {kind: 'Operation', left, op, right}
}

function opLeft(kind: OperatorLeft, start: number, end?: number): OperatorLeftAst {
    return {kind, token: token(start, end === undefined ? start + kind.length - 1 : end)}
}

function operationLeft(op: OperatorLeftAst, right: ExpressionAst): OperationLeftAst {
    return {kind: 'OperationLeft', op, right}
}

function opRight(kind: OperatorRight, start: number, end?: number): OperatorRightAst {
    return {kind, token: token(start, end === undefined ? start + kind.length - 1 : end)}
}

function operationRight(left: ExpressionAst, op: OperatorRightAst): OperationRightAst {
    return {kind: 'OperationRight', left, op}
}

function group(expression: ExpressionAst): GroupAst {
    return {kind: 'Group', expression}
}

function wildcard(start: number): WildcardAst {
    return {kind: 'Wildcard', token: token(start, start)}
}

function column(name: string, start: number, table?: string, schema?: string): ColumnAst {
    if (schema && table) {
        return {kind: 'Column', schema: identifier(schema, start), table: identifier(table, start + schema.length + 1), column: identifier(name, start + schema.length + table.length + 2)}
    } else if (table) {
        return {kind: 'Column', table: identifier(table, start), column: identifier(name, start + table.length + 1)}
    } else {
        return {kind: 'Column', column: identifier(name, start)}
    }
}

function function_(name: string, start: number, parameters: ExpressionAst[], schema?: string): FunctionAst {
    if (schema) {
        return {kind: 'Function', schema: identifier(schema, start), function: identifier(name, start + schema.length + 1), parameters}
    } else {
        return {kind: 'Function', function: identifier(name, start), parameters}
    }
}

function alias(name: string, start: number, tokenStart?: number): AliasAst {
    return tokenStart ? {token: token(tokenStart, tokenStart + 1), name: identifier(name, start)} : {name: identifier(name, start)}
}

function identifier(value: string, start: number, end?: number): IdentifierAst { // needs `end` for quoted identifiers: `"id"`
    return {kind: 'Identifier', value, token: token(start, end === undefined ? start + value.length - 1 : end)}
}

function string(value: string, start: number, end?: number): StringAst { // needs `end` for escaped strings: `E'str'`
    return {kind: 'String', value, token: token(start, end === undefined ? start + value.length + 1 : end)}
}

function integer(value: number, start: number): IntegerAst {
    return {kind: 'Integer', value, token: token(start, start + value.toString().length - 1)}
}

function decimal(value: number, start: number, end?: number): DecimalAst { // needs `end` for 0 decimal: `0.0`
    return {kind: 'Decimal', value, token: token(start, end == undefined ? start + value.toString().length - 1 : end)}
}

function boolean(value: boolean, start: number): BooleanAst {
    return {kind: 'Boolean', value, token: token(start, start + value.toString().length - 1)}
}

function null_(start: number): NullAst {
    return {kind: 'Null', token: token(start, start + 3)}
}

function parameter(index: number, start: number): ParameterAst {
    return {kind: 'Parameter', value: index ? `$${index}` : '?', index: index ? index : undefined, token: token(start, index ? start + index.toString().length : start)}
}

function list(items: LiteralAst[]): ListAst {
    return {kind: 'List', items}
}

function stmt(kind: string, start: number, tokenEnd: number, statementEnd: number): {kind: string, meta: TokenInfo, token: TokenInfo} {
    return {kind, meta: token(start, statementEnd), token: token(start, tokenEnd)}
}

function kind(kind: string, start: number, end?: number): {kind: string, token: TokenInfo} {
    return {kind, token: token(start, end === undefined ? start + kind.length - 1 : end)}
}

function token(start: number, end: number, issues?: TokenIssue[]): TokenInfo {
    return removeEmpty({offset: {start, end}, position: {start: {line: 1, column: start + 1}, end: {line: 1, column: end + 1}}, issues})
}

function removeTokens<T>(ast: T): T {
    return removeFieldsDeep(ast, ['meta', 'token'])
}
