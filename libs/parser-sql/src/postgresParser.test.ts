import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {removeEmpty, removeFieldsDeep} from "@azimutt/utils";
import {
    BooleanAst,
    DecimalAst,
    IdentifierAst,
    IntegerAst,
    OperatorAst,
    StringAst,
    TokenInfo,
    TokenIssue
} from "./postgresAst";
import {parsePostgresAst, parseRule} from "./postgresParser";

describe('postgresParser', () => {
    test('empty', () => {
        expect(parsePostgresAst('')).toEqual({result: {statements: []}})
    })
    test('complex', () => {
        const sql = fs.readFileSync('./resources/complex.postgres.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
    })
    test.skip('full', () => {
        const sql = fs.readFileSync('./resources/full.postgres.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
    })
    test.skip('structure', () => {
        const sql = fs.readFileSync('../../backend/priv/repo/structure.sql', 'utf8')
        const parsed = parsePostgresAst(sql, {strict: true})
        expect(parsed.errors || []).toEqual([])
    })
    // CREATE TABLE/VIEW/MATERIALIZED VIEW/INDEX/TYPE
    // INSERT INTO
    // UPDATE
    // DELETE
    // COMMENT ON
    describe('selectStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SELECT name FROM users;')).toEqual({result: {statements: [{
                statement: 'Select',
                select: {...token(0, 5), expressions: [{column: identifier('name', 7, 10)}]},
                from: {...token(12, 15), table: identifier('users', 17, 21)},
                ...token(0, 22)
            }]}})
        })
        test('complex', () => {
            expect(removeTokens(parsePostgresAst('SELECT id, first_name AS name FROM users WHERE id = 1;'))).toEqual({result: {statements: [{
                statement: 'Select',
                select: {expressions: [
                    {column: {kind: 'Identifier', value: 'id'}},
                    {column: {kind: 'Identifier', value: 'first_name'}, alias: {name: {kind: 'Identifier', value: 'name'}}}
                ]},
                from: {table: {kind: 'Identifier', value: 'users'}},
                where: {condition: {left: {column: {kind: 'Identifier', value: 'id'}}, operator: {kind: '='}, right: {kind: 'Integer', value: 1}}}
            }]}})
        })
    })
    describe('createTableStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('CREATE TABLE users (id int PRIMARY KEY, name VARCHAR);')).toEqual({result: {statements: [{
                statement: 'CreateTable',
                name: {table: identifier('users', 13, 17)},
                columns: [
                    {name: identifier('id', 20, 21), type: identifier('int', 23, 25), constraints: [{kind: 'PrimaryKey', ...token(27, 37)}]},
                    {name: identifier('name', 40, 43), type: identifier('VARCHAR', 45, 51)},
                ],
                ...token(0, 53)
            }]}})
        })
        test('with constraints', () => {
            expect(parsePostgresAst('CREATE TABLE users (id int, role VARCHAR, CONSTRAINT users_pk PRIMARY KEY (id), FOREIGN KEY (role) REFERENCES roles (name));')).toEqual({result: {statements: [{
                statement: 'CreateTable',
                name: {table: identifier('users', 13, 17)},
                columns: [
                    {name: identifier('id', 20, 21), type: identifier('int', 23, 25)},
                    {name: identifier('role', 28, 31), type: identifier('VARCHAR', 33, 39)},
                ],
                constraints: [
                    {kind: 'PrimaryKey', constraint: {...token(42, 51), name: identifier('users_pk', 53, 60)}, ...token(62, 72), columns: [identifier('id', 75, 76)]},
                    {kind: 'ForeignKey', ...token(80, 90), columns: [identifier('role', 93, 96)], ref: {...token(99, 108), table: identifier('roles', 110, 114), columns: [identifier('name', 117, 120)]}}
                ],
                ...token(0, 123)
            }]}})
        })
        // CREATE TABLE IF NOT EXISTS users (id int);
        // CREATE UNLOGGED TABLE users (id int);
    })
    describe('dropStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('DROP TABLE users;')).toEqual({result: {statements: [{
                statement: 'Drop',
                kind: {kind: 'Table', ...token(0, 9)},
                entities: [{table: identifier('users', 11, 15)}],
                ...token(0, 16)
            }]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('DROP INDEX CONCURRENTLY IF EXISTS users_idx, posts_idx CASCADE;')).toEqual({result: {statements: [{
                statement: 'Drop',
                kind: {kind: 'Index', ...token(0, 9)},
                concurrently: token(11, 22),
                ifExists: token(24, 32),
                entities: [{table: identifier('users_idx', 34, 42)}, {table: identifier('posts_idx', 45, 53)}],
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
    describe('setStatement', () => {
        test('simplest', () => {
            expect(parsePostgresAst('SET lock_timeout = 0;')).toEqual({result: {statements: [
                {statement: 'Set', ...token(0, 20), parameter: identifier('lock_timeout', 4, 15), equal: {kind: '=', ...token(17, 17)}, value: integer(0, 19, 19)}
            ]}})
        })
        test('complex', () => {
            expect(parsePostgresAst('SET SESSION search_path TO my_schema, public;')).toEqual({result: {statements: [
                {statement: 'Set', ...token(0, 44), scope: {kind: 'Session', ...token(4, 10)}, parameter: identifier('search_path', 12, 22), equal: {kind: 'To', ...token(24, 25)}, value: [identifier('my_schema', 27, 35), identifier('public', 38, 43)]}
            ]}})
        })
    })
    describe('clauses', () => {
        describe('selectClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.selectClauseRule(), 'SELECT name')).toEqual({result: {
                    ...token(0, 5),
                    expressions: [{column: identifier('name', 7, 10)}],
                }})
            })
            // SELECT e.*, u.name AS user_name, lower(u.email), "public"."Event"."id"
            // SELECT count(*)
            // SELECT count(distinct e.created_by) FILTER (WHERE u.created_at + interval '#{period}' < e.created_at) AS not_new_users
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
            // FROM (SELECT * FROM ...)
        })
        describe('whereClause', () => {
            test('simplest', () => {
                expect(parseRule(p => p.whereClauseRule(), 'WHERE id = 1')).toEqual({result: {
                    ...token(0, 4),
                    condition: {left: {column: identifier('id', 6, 7)}, operator: operator('=', 9, 9), right: integer(1, 11, 11)},
                }})
            })
            // WHERE "id" = $1 OR (email LIKE '%@azimutt.app' AND role = 'admin')
        })
        describe('tableColumnRule', () => {
            test('simplest', () => {
                expect(parseRule(p => p.tableColumnRule(), 'id int')).toEqual({result: {name: identifier('id', 0, 1), type: identifier('int', 3, 5),}})
            })
            test('not null & default', () => {
                expect(parseRule(p => p.tableColumnRule(), "role varchar NOT NULL DEFAULT 'guest'")).toEqual({result: {
                    name: identifier('role', 0, 3),
                    type: identifier('varchar', 5, 11),
                    constraints: [{kind: 'Nullable', value: false, ...token(13, 20)}, {kind: 'Default', ...token(22, 28), expression: string('guest', 30, 36)}],
                }})
                // TODO: `DEFAULT 'owner'::character varying`
            })
            test('primaryKey', () => {
                expect(parseRule(p => p.tableColumnRule(), 'id int PRIMARY KEY')).toEqual({result: {name: identifier('id', 0, 1), type: identifier('int', 3, 5), constraints: [
                    {kind: 'PrimaryKey', ...token(7, 17)}
                ]}})
            })
            test('unique', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar UNIQUE")).toEqual({result: {name: identifier('email', 0, 4), type: identifier('varchar', 6, 12), constraints: [
                    {kind: 'Unique', ...token(14, 19)}
                ]}})
            })
            test('check', () => {
                expect(parseRule(p => p.tableColumnRule(), "email varchar CHECK (email LIKE '%@%')")).toEqual({result: {name: identifier('email', 0, 4), type: identifier('varchar', 6, 12), constraints: [
                    {kind: 'Check', ...token(14, 18), predicate: {left: {column: identifier('email', 21, 25)}, operator: operator('Like', 27, 30), right: string('%@%', 32, 36)}}
                ]}})
            })
            test('foreignKey', () => {
                expect(parseRule(p => p.tableColumnRule(), "author uuid REFERENCES users(id) ON DELETE SET NULL (id)")).toEqual({result: {name: identifier('author', 0, 5), type: identifier('uuid', 7, 10), constraints: [{
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
                        type: identifier('varchar', 6, 12),
                        constraints: [
                            {kind: 'Nullable', constraint: {...token(14, 23), name: identifier('users_email_nn', 25, 38)}, ...token(40, 47), value: false},
                            {kind: 'Default', constraint: {...token(49, 58), name: identifier('users_email_def', 60, 74)}, ...token(76, 82), expression: string('anon@mail.com', 84, 98)},
                            {kind: 'PrimaryKey', constraint: {...token(100, 109), name: identifier('users_pk', 111, 118)}, ...token(120, 130)},
                            {kind: 'Unique', constraint: {...token(132, 141), name: identifier('users_email_uniq', 143, 158)}, ...token(160, 165)},
                            {kind: 'Check', constraint: {...token(167, 176), name: identifier('users_email_chk', 178, 192)}, ...token(194, 198), predicate: {left: {column: identifier('email', 201, 205)}, operator: operator('Like', 207, 210), right: string('%@%', 212, 216)}},
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
        describe('conditionRule', () => {
            test('simplest', () => {
                expect(parseRule(p => p.conditionRule(), 'id = 1')).toEqual({result: {left: {column: identifier('id', 0, 1)}, operator: operator('=', 3, 3), right: integer(1, 5, 5)}})
            })
            // title <> ''
            // role IN ('author', 'editor')
        })
        describe('expressionRule', () => {
            test('literal', () => {
                expect(parseRule(p => p.expressionRule(), '1')).toEqual({result: integer(1, 0, 0)})
            })
            test('column', () => {
                expect(parseRule(p => p.expressionRule(), 'id')).toEqual({result: {column: identifier('id', 0, 1)}})
            })
        })
        describe('tableRule', () => {
            test('table only', () => {
                expect(parseRule(p => p.tableRule(), 'users')).toEqual({result: {table: identifier('users', 0, 4)}})
            })
            test('table and schema', () => {
                expect(parseRule(p => p.tableRule(), 'public.users')).toEqual({result: {schema: identifier('public', 0, 5), table: identifier('users', 7, 11)}})
            })
        })
        describe('columnRule', () => {
            test('column only', () => {
                expect(parseRule(p => p.columnRule(), 'id')).toEqual({result: {column: identifier('id', 0, 1)}})
            })
            test('column and table', () => {
                expect(parseRule(p => p.columnRule(), 'users.id')).toEqual({result: {table: identifier('users', 0, 4), column: identifier('id', 6, 7)}})
            })
            test('column, table and schema', () => {
                expect(parseRule(p => p.columnRule(), 'public.users.id')).toEqual({result: {schema: identifier('public', 0, 5), table: identifier('users', 7, 11), column: identifier('id', 13, 14)}})
            })
        })
        describe('literalRule', () => {
            test('string', () => {
                expect(parseRule(p => p.literalRule(), "'id'")).toEqual({result: {kind: 'String', value: 'id', ...token(0, 3)}})
            })
            test('decimal', () => {
                expect(parseRule(p => p.literalRule(), "3.14")).toEqual({result: {kind: 'Decimal', value: 3.14, ...token(0, 3)}})
            })
            test('integer', () => {
                expect(parseRule(p => p.literalRule(), "3")).toEqual({result: {kind: 'Integer', value: 3, ...token(0, 0)}})
            })
            test('boolean', () => {
                expect(parseRule(p => p.literalRule(), "true")).toEqual({result: {kind: 'Boolean', value: true, ...token(0, 3)}})
            })
        })
    })
    describe('elements', () => {
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
                    {kind: 'MismatchedTokenException', level: 'error', message: "Expecting token of type --> Identifier <-- but found --> '' <--", ...token(-1, -1, -1, -1, -1, -1)}
                ]})
            })
        })
        describe('stringRule', () => {
            test('basic', () => {
                expect(parseRule(p => p.stringRule(), "'value'")).toEqual({result: string('value', 0, 6)})
            })
            test('escape quote', () => {
                expect(parseRule(p => p.stringRule(), "'l''id'")).toEqual({result: string("l'id", 0, 6)})
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