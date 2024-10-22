import {describe, expect, test} from "@jest/globals";
import {removeEmpty, removeFieldsDeep} from "@azimutt/utils";
import {tokenPosition} from "@azimutt/models";
import {
    AttributeRelationAst,
    BooleanAst,
    CommentAst,
    DecimalAst,
    DocAst,
    ExpressionAst,
    IdentifierAst,
    IntegerAst,
    NullAst,
    TokenInfo,
    TokenIssue
} from "./amlAst";
import {nestAttributes, parseAmlAst, parseRule} from "./amlParser";
import {badIndent, legacy} from "./errors";

describe('amlParser', () => {
    test('empty', () => {
        expect(parseAmlAst('', {strict: false})).toEqual({result: []})
    })
    test('simple entity', () => {
        const input = `
users
  id uuid pk
  name varchar
`
        const ast = [{kind: 'Empty'}, {
            kind: 'Entity',
            name: identifier('users', 1, 5, 2, 2, 1, 5),
            attrs: [{
                path: [identifier('id', 9, 10, 3, 3, 3, 4)],
                type: identifier('uuid', 12, 15, 3, 3, 6, 9),
                primaryKey: {token: tokenPosition(17, 18, 3, 11, 3, 12)},
            }, {
                path: [identifier('name', 22, 25, 4, 4, 3, 6)],
                type: identifier('varchar', 27, 33, 4, 4, 8, 14),
            }]
        }]
        expect(parseAmlAst(input, {strict: false})).toEqual({result: ast})
    })
    test('multiple entities', () => {
        const input = `
users
posts
comments
`
        const ast = [
            {kind: 'Empty'},
            {kind: 'Entity', name: identifier('users', 1, 5, 2, 2, 1, 5)},
            {kind: 'Entity', name: identifier('posts', 7, 11, 3, 3, 1, 5)},
            {kind: 'Entity', name: identifier('comments', 13, 20, 4, 4, 1, 8)},
        ]
        expect(parseAmlAst(input, {strict: false})).toEqual({result: ast})
    })
    describe('namespaceStatementRule', () => {
        test('schema', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                schema: identifier('public', 10, 15, 1, 1, 11, 16),
            }})
        })
        test('catalog', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace core.public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                catalog: identifier('core', 10, 13, 1, 1, 11, 14),
                schema: identifier('public', 15, 20, 1, 1, 16, 21),
            }})
        })
        test('database', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace analytics.core.public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                database: identifier('analytics', 10, 18, 1, 1, 11, 19),
                catalog: identifier('core', 20, 23, 1, 1, 21, 24),
                schema: identifier('public', 25, 30, 1, 1, 26, 31),
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace public | a note # and a comment\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                schema: identifier('public', 10, 15, 1, 1, 11, 16),
                doc: doc('a note', 17, 25, 1, 1, 18, 26),
                comment: comment('and a comment', 26, 40, 1, 1, 27, 41),
            }})
        })
        test('empty catalog', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace analytics..public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                database: identifier('analytics', 10, 18, 1, 1, 11, 19),
                schema: identifier('public', 21, 26, 1, 1, 22, 27),
            }})
        })
    })
    describe('entityRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.entityRule(), 'users\n')).toEqual({result: {kind: 'Entity', name: identifier('users', 0, 4, 1, 1, 1, 5)}})
        })
        test('namespace', () => {
            expect(parseRule(p => p.entityRule(), 'public.users\n')).toEqual({result: {
                kind: 'Entity',
                schema: identifier('public', 0, 5, 1, 1, 1, 6),
                name: identifier('users', 7, 11, 1, 1, 8, 12),
            }})
            expect(parseRule(p => p.entityRule(), 'core.public.users\n')).toEqual({result: {
                kind: 'Entity',
                catalog: identifier('core', 0, 3, 1, 1, 1, 4),
                schema: identifier('public', 5, 10, 1, 1, 6, 11),
                name: identifier('users', 12, 16, 1, 1, 13, 17),
            }})
            expect(parseRule(p => p.entityRule(), 'ax.core.public.users\n')).toEqual({result: {
                kind: 'Entity',
                database: identifier('ax', 0, 1, 1, 1, 1, 2),
                catalog: identifier('core', 3, 6, 1, 1, 4, 7),
                schema: identifier('public', 8, 13, 1, 1, 9, 14),
                name: identifier('users', 15, 19, 1, 1, 16, 20),
            }})
        })
        test('view', () => {
            expect(parseRule(p => p.entityRule(), 'users*\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0, 4, 1, 1, 1, 5),
                view: tokenPosition(5, 5, 1, 6, 1, 6)
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.entityRule(), 'users as u\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0, 4, 1, 1, 1, 5),
                alias: identifier('u', 9, 9, 1, 1, 10, 10),
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.entityRule(), 'users {domain: auth} | list users # sample comment\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0, 4, 1, 1, 1, 5),
                properties: [{
                    key: identifier('domain', 7, 12, 1, 1, 8, 13),
                    sep: tokenPosition(13, 13, 1, 14, 1, 14),
                    value: identifier('auth', 15, 18, 1, 1, 16, 19),
                }],
                doc: doc('list users', 21, 33, 1, 1, 22, 34),
                comment: comment('sample comment', 34, 49, 1, 1, 35, 50),
            }})
        })
        test('attributes', () => {
            expect(parseRule(p => p.entityRule(), 'users\n  id uuid pk\n  name varchar\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0, 4, 1, 1, 1, 5),
                attrs: [{
                    path: [identifier('id', 8, 9, 2, 2, 3, 4)],
                    type: identifier('uuid', 11, 14, 2, 2, 6, 9),
                    primaryKey: {token: tokenPosition(16, 17, 2, 11, 2, 12)},
                }, {
                    path: [identifier('name', 21, 24, 3, 3, 3, 6)],
                    type: identifier('varchar', 26, 32, 3, 3, 8, 14),
                }],
            }})
            expect(parseRule(p => p.entityRule(), 'users\n  id uuid pk\n  name json\n      first string\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0, 4, 1, 1, 1, 5),
                attrs: [{
                    path: [identifier('id', 8, 9, 2, 2, 3, 4)],
                    type: identifier('uuid', 11, 14, 2, 2, 6, 9),
                    primaryKey: {token: tokenPosition(16, 17, 2, 11, 2, 12)},
                }, {
                    path: [identifier('name', 21, 24, 3, 3, 3, 6)],
                    type: identifier('json', 26, 29, 3, 3, 8, 11),
                    attrs: [{
                        path: [identifier('name', 21, 24, 3, 3, 3, 6), identifier('first', 37, 41, 4, 4, 7, 11)],
                        type: identifier('string', 43, 48, 4, 4, 13, 18),
                        warning: {issues: [badIndent(1, 2)], ...tokenPosition(31, 36, 4, 1, 4, 6)}
                    }]
                }],
            }})
        })
        describe('attributeRule', () => {
            test('name', () => {
                expect(parseRule(p => p.attributeRule(), '  id\n')).toEqual({result: {nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)}, name: identifier('id', 2, 3, 1, 1, 3, 4)}})
                expect(parseRule(p => p.attributeRule(), '  "index"\n')).toEqual({result: {nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)}, name: {...identifier('index', 2, 8, 1, 1, 3, 9), quoted: true}}})
                expect(parseRule(p => p.attributeRule(), '  fk_col\n')).toEqual({result: {nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)}, name: identifier('fk_col', 2, 7, 1, 1, 3, 8)}})
            })
            test('type', () => {
                expect(parseRule(p => p.attributeRule(), '  id uuid\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    type: identifier('uuid', 5, 8, 1, 1, 6, 9),
                }})
                expect(parseRule(p => p.attributeRule(), '  name "varchar(12)"\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('name', 2, 5, 1, 1, 3, 6),
                    type: {...identifier('varchar(12)', 7, 19, 1, 1, 8, 20), quoted: true},
                }})
                expect(parseRule(p => p.attributeRule(), '  bio "character varying"\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('bio', 2, 4, 1, 1, 3, 5),
                    type: {...identifier('character varying', 6, 24, 1, 1, 7, 25), quoted: true},
                }})
                expect(parseRule(p => p.attributeRule(), '  id "type"\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    type: {...identifier('type', 5, 10, 1, 1, 6, 11), quoted: true},
                }})
            })
            test('enum', () => {
                expect(parseRule(p => p.attributeRule(), '  status post_status(draft, published, archived)\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('status', 2, 7, 1, 1, 3, 8),
                    type: identifier('post_status', 9, 19, 1, 1, 10, 20),
                    enumValues: [
                        identifier('draft', 21, 25, 1, 1, 22, 26),
                        identifier('published', 28, 36, 1, 1, 29, 37),
                        identifier('archived', 39, 46, 1, 1, 40, 47),
                    ],
                }})
            })
            test('default', () => {
                expect(parseRule(p => p.attributeRule(), '  id int=0\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    type: identifier('int', 5, 7, 1, 1, 6, 8),
                    defaultValue: integer(0, 9, 9, 1, 1, 10, 10),
                }})
                expect(parseRule(p => p.attributeRule(), '  price decimal=41.9\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('price', 2, 6, 1, 1, 3, 7),
                    type: identifier('decimal', 8, 14, 1, 1, 9, 15),
                    defaultValue: decimal(41.9, 16, 19, 1, 1, 17, 20),
                }})
                expect(parseRule(p => p.attributeRule(), '  role varchar=guest\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('role', 2, 5, 1, 1, 3, 6),
                    type: identifier('varchar', 7, 13, 1, 1, 8, 14),
                    defaultValue: identifier('guest', 15, 19, 1, 1, 16, 20),
                }})
                expect(parseRule(p => p.attributeRule(), '  is_admin boolean=false\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('is_admin', 2, 9, 1, 1, 3, 10),
                    type: identifier('boolean', 11, 17, 1, 1, 12, 18),
                    defaultValue: boolean(false, 19, 23, 1, 1, 20, 24),
                }})
                expect(parseRule(p => p.attributeRule(), '  created_at timestamp=`now()`\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('created_at', 2, 11, 1, 1, 3, 12),
                    type: identifier('timestamp', 13, 21, 1, 1, 14, 22),
                    defaultValue: expression('now()', 23, 29, 1, 1, 24, 30),
                }})
                expect(parseRule(p => p.attributeRule(), '  source varchar=null\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('source', 2, 7, 1, 1, 3, 8),
                    type: identifier('varchar', 9, 15, 1, 1, 10, 16),
                    defaultValue: null_(17, 20, 1, 1, 18, 21),
                }})
                // TODO: handle `[]` default value? Ex: '  tags varchar[]=[]\n' instead of '  tags varchar[]="[]"\n'
                // TODO: handle `{}` default value? Ex: '  details json={}\n' instead of '  details json="{}"\n'
            })
            test('nullable', () => {
                expect(parseRule(p => p.attributeRule(), '  id nullable\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    nullable: tokenPosition(5, 12, 1, 6, 1, 13),
                }})
                expect(parseRule(p => p.attributeRule(), '  id int nullable\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    type: identifier('int', 5, 7, 1, 1, 6, 8),
                    nullable: tokenPosition(9, 16, 1, 10, 1, 17),
                }})
            })
            test('pk', () => {
                expect(parseRule(p => p.attributeRule(), '  id pk\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    primaryKey: {token: tokenPosition(5, 6, 1, 6, 1, 7)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id int pk\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    type: identifier('int', 5, 7, 1, 1, 6, 8),
                    primaryKey: {token: tokenPosition(9, 10, 1, 10, 1, 11)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id int pk=pk_name\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    type: identifier('int', 5, 7, 1, 1, 6, 8),
                    primaryKey: {token: tokenPosition(9, 10, 1, 10, 1, 11), name: identifier('pk_name', 12, 18, 1, 1, 13, 19)},
                }})
            })
            test('index', () => {
                expect(parseRule(p => p.attributeRule(), '  id index\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    index: {token: tokenPosition(5, 9, 1, 6, 1, 10)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id index=id_idx\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    index: {token: tokenPosition(5, 9, 1, 6, 1, 10), name: identifier('id_idx', 11, 16, 1, 1, 12, 17)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id index = "idx \\" id"\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    index: {token: tokenPosition(5, 9, 1, 6, 1, 10), name: {...identifier('idx " id', 13, 23, 1, 1, 14, 24), quoted: true}},
                }})
            })
            test('unique', () => {
                expect(parseRule(p => p.attributeRule(), '  id unique\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    unique: {token: tokenPosition(5, 10, 1, 6, 1, 11)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id unique=id_uniq\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    unique: {token: tokenPosition(5, 10, 1, 6, 1, 11), name: identifier('id_uniq', 12, 18, 1, 1, 13, 19)},
                }})
            })
            test('check', () => {
                expect(parseRule(p => p.attributeRule(), '  id check\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    check: {token: tokenPosition(5, 9, 1, 6, 1, 10)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id check=id_chk\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    check: {token: tokenPosition(5, 9, 1, 6, 1, 10), name: identifier('id_chk', 11, 16, 1, 1, 12, 17)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id check(`id > 0`)\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    check: {token: tokenPosition(5, 9, 1, 6, 1, 10), predicate: expression('id > 0', 11, 18, 1, 1, 12, 19)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id check(`id > 0`)=id_chk\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    check: {
                        token: tokenPosition(5, 9, 1, 6, 1, 10),
                        predicate: expression('id > 0', 11, 18, 1, 1, 12, 19),
                        name: identifier('id_chk', 21, 26, 1, 1, 22, 27)
                    },
                }})
            })
            test('relation', () => {
                expect(parseRule(p => p.attributeRule(), '  user_id -> users(id)\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('user_id', 2, 8, 1, 1, 3, 9),
                    relation: {srcCardinality: 'n', refCardinality: '1', ref: {
                        entity: identifier('users', 13, 17, 1, 1, 14, 18),
                        attrs: [identifier('id', 19, 20, 1, 1, 20, 21)],
                    }}
                }})
                expect(parseRule(p => p.attributeRule(), '  user_id -> users\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('user_id', 2, 8, 1, 1, 3, 9),
                    relation: {srcCardinality: 'n', refCardinality: '1', ref: {
                        entity: identifier('users', 13, 17, 1, 1, 14, 18),
                        attrs: [],
                    }}
                }})
            })
            test('properties', () => {
                expect(parseRule(p => p.attributeRule(), '  id {tag: pii}\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    properties: [{key: identifier('tag', 6, 8, 1, 1, 7, 9), sep: tokenPosition(9, 9, 1, 10, 1, 10), value: identifier('pii', 11, 13, 1, 1, 12, 14)}],
                }})
            })
            test('note', () => {
                expect(parseRule(p => p.attributeRule(), '  id | some note\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    doc: doc('some note', 5, 15, 1, 1, 6, 16),
                }})
            })
            test('comment', () => {
                expect(parseRule(p => p.attributeRule(), '  id # a comment\n')).toEqual({result: {
                    nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                    name: identifier('id', 2, 3, 1, 1, 3, 4),
                    comment: comment('a comment', 5, 15, 1, 1, 6, 16),
                }})
            })
            test('all', () => {
                expect(parseRule(p => p.attributeRule(), '    id int(8, 9, 10)=8 nullable pk unique index=idx check(`id > 0`) -kind=users> public.users(id) { tag : pii , owner:PANDA} | some note # comment\n')).toEqual({result: {
                    nesting: {depth: 1, token: tokenPosition(0, 3, 1, 1, 1, 4)},
                    name: identifier('id', 4, 5, 1, 1, 5, 6),
                    type: identifier('int', 7, 9, 1, 1, 8, 10),
                    enumValues: [integer(8, 11, 11, 1, 1, 12, 12), integer(9, 14, 14, 1, 1, 15, 15), integer(10, 17, 18, 1, 1, 18, 19)],
                    defaultValue: integer(8, 21, 21, 1, 1, 22, 22),
                    nullable: tokenPosition(23, 30, 1, 24, 1, 31),
                    primaryKey: {token: tokenPosition(32, 33, 1, 33, 1, 34)},
                    index: {token: tokenPosition(42, 46, 1, 43, 1, 47), name: identifier('idx', 48, 50, 1, 1, 49, 51)},
                    unique: {token: tokenPosition(35, 40, 1, 36, 1, 41)},
                    check: {token: tokenPosition(52, 56, 1, 53, 1, 57), predicate: expression('id > 0', 58, 65, 1, 1, 59, 66)},
                    relation: {
                        srcCardinality: 'n',
                        refCardinality: '1',
                        ref: {schema: identifier('public', 81, 86, 1, 1, 82, 87), entity: identifier('users', 88, 92, 1, 1, 89, 93), attrs: [identifier('id', 94, 95, 1, 1, 95, 96)]},
                        polymorphic: {attr: identifier('kind', 69, 72, 1, 1, 70, 73), value: identifier('users', 74, 78, 1, 1, 75, 79)}
                    },
                    properties: [
                        {key: identifier('tag', 100, 102, 1, 1, 101, 103), sep: tokenPosition(104, 104, 1, 105, 1, 105), value: identifier('pii', 106, 108, 1, 1, 107, 109)},
                        {key: identifier('owner', 112, 116, 1, 1, 113, 117), sep: tokenPosition(117, 117, 1, 118, 1, 118), value: identifier('PANDA', 118, 122, 1, 1, 119, 123)},
                    ],
                    doc: doc('some note', 125, 136, 1, 1, 126, 137),
                    comment: comment('comment', 137, 145, 1, 1, 138, 146),
                }})
            })
            test('error', () => {
                expect(parseRule(p => p.attributeRule(), '  12\n')).toEqual({result: {nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)}}, errors: [{message: "Expecting token of type --> Identifier <-- but found --> '12' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(2, 3, 1, 3, 1, 4)}]})
            })
        })
    })
    describe('relationRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id)\n')).toEqual({result: {
                kind: 'Relation',
                srcCardinality: 'n',
                refCardinality: '1',
                src: {
                    entity: identifier('groups', 4, 9, 1, 1, 5, 10),
                    attrs: [identifier('owner', 11, 15, 1, 1, 12, 16)],
                },
                ref: {
                    entity: identifier('users', 21, 25, 1, 1, 22, 26),
                    attrs: [identifier('id', 27, 28, 1, 1, 28, 29)],
                },
            }})
        })
        test('one-to-one', () => {
            expect(parseRule(p => p.relationRule(), 'rel profiles(id) -- users(id)\n')).toEqual({result: {
                kind: 'Relation',
                srcCardinality: '1',
                refCardinality: '1',
                src: {
                    entity: identifier('profiles', 4, 11, 1, 1, 5, 12),
                    attrs: [identifier('id', 13, 14, 1, 1, 14, 15)],
                },
                ref: {
                    entity: identifier('users', 20, 24, 1, 1, 21, 25),
                    attrs: [identifier('id', 26, 27, 1, 1, 27, 28)],
                },
            }})
        })
        test('many-to-many', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(id) <> users(id)\n')).toEqual({result: {
                kind: 'Relation',
                srcCardinality: 'n',
                refCardinality: 'n',
                src: {
                    entity: identifier('groups', 4, 9, 1, 1, 5, 10),
                    attrs: [identifier('id', 11, 12, 1, 1, 12, 13)],
                },
                ref: {
                    entity: identifier('users', 18, 22, 1, 1, 19, 23),
                    attrs: [identifier('id', 24, 25, 1, 1, 25, 26)],
                },
            }})
        })
        test('composite', () => {
            expect(parseRule(p => p.relationRule(), 'rel audit(user_id, role_id) -> user_roles(user_id, role_id)\n')).toEqual({result: {
                kind: 'Relation',
                srcCardinality: 'n',
                refCardinality: '1',
                src: {
                    entity: identifier('audit', 4, 8, 1, 1, 5, 9),
                    attrs: [
                        identifier('user_id', 10, 16, 1, 1, 11, 17),
                        identifier('role_id', 19, 25, 1, 1, 20, 26),
                    ],
                },
                ref: {
                    entity: identifier('user_roles', 31, 40, 1, 1, 32, 41),
                    attrs: [
                        identifier('user_id', 42, 48, 1, 1, 43, 49),
                        identifier('role_id', 51, 57, 1, 1, 52, 58),
                    ],
                },
            }})
        })
        test('polymorphic', () => {
            expect(parseRule(p => p.relationRule(), 'rel events(item_id) -item_kind=User> users(id)\n')).toEqual({result: {
                kind: 'Relation',
                srcCardinality: 'n',
                refCardinality: '1',
                src: {
                    entity: identifier('events', 4, 9, 1, 1, 5, 10),
                    attrs: [identifier('item_id', 11, 17, 1, 1, 12, 18)],
                },
                ref: {
                    entity: identifier('users', 37, 41, 1, 1, 38, 42),
                    attrs: [identifier('id', 43, 44, 1, 1, 44, 45)],
                },
                polymorphic: {
                    attr: identifier('item_kind', 21, 29, 1, 1, 22, 30),
                    value: identifier('User', 31, 34, 1, 1, 32, 35),
                }
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id) {color: red} | a note # a comment\n')).toEqual({result: {
                kind: 'Relation',
                srcCardinality: 'n',
                refCardinality: '1',
                src: {
                    entity: identifier('groups', 4, 9, 1, 1, 5, 10),
                    attrs: [identifier('owner', 11, 15, 1, 1, 12, 16)],
                },
                ref: {
                    entity: identifier('users', 21, 25, 1, 1, 22, 26),
                    attrs: [identifier('id', 27, 28, 1, 1, 28, 29)],
                },
                properties: [{
                    key: identifier('color', 32, 36, 1, 1, 33, 37),
                    sep: tokenPosition(37, 37, 1, 38, 1, 38),
                    value: identifier('red', 39, 41, 1, 1, 40, 42)
                }],
                doc: doc('a note', 44, 52, 1, 1, 45, 53),
                comment: comment('a comment', 53, 63, 1, 1, 54, 64),
            }})
        })
        test('bad', () => {
            expect(parseRule(p => p.relationRule(), 'bad')).toEqual({errors: [{message: "Expecting: one of these possible Token sequences:\n  1. [Relation]\n  2. [ForeignKey]\nbut found: 'bad'", kind: 'NoViableAltException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
    })
    describe('typeRule', () => {
        test('empty', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status varchar\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
                content: {kind: 'alias', name: identifier('varchar', 16, 22, 1, 1, 17, 23)},
            }})
        })
        test('enum', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status (new, "in progress", done)\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
                content: {kind: 'enum', values: [
                    identifier('new', 17, 19, 1, 1, 18, 20),
                    {...identifier('in progress', 22, 34, 1, 1, 23, 35), quoted: true},
                    identifier('done', 37, 40, 1, 1, 38, 41),
                ]}
            }})
        })
        test('struct', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status {internal varchar, public varchar}\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
                content: {kind: 'struct', attrs: [{
                    path: [identifier('internal', 17, 24, 1, 1, 18, 25)],
                    type: identifier('varchar', 26, 32, 1, 1, 27, 33),
                }, {
                    path: [identifier('public', 35, 40, 1, 1, 36, 41)],
                    type: identifier('varchar', 42, 48, 1, 1, 43, 49),
                }]}
            }})
            // FIXME: would be nice to have this alternative but the $.MANY fails, see `typeRule`
            /*expect(parseRule(p => p.typeRule(), 'type bug_status\n  internal varchar\n  public varchar\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
                content: {kind: 'struct', attrs: [{
                    path: [identifier('internal', 18, 25, 2, 2, 3, 10)],
                    type: identifier('varchar', 27, 33, 2, 2, 12, 18),
                }, {
                    path: [identifier('public', 37, 42, 3, 3, 3, 8)],
                    type: identifier('varchar', 44, 50, 3, 3, 10, 16),
                }]}
            }})*/
        })
        test('custom', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status `range(subtype = float8, subtype_diff = float8mi)`\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
                content: {kind: 'custom', definition: expression('range(subtype = float8, subtype_diff = float8mi)', 16, 65, 1, 1, 17, 66)}
            }})
        })
        test('namespace', () => {
            expect(parseRule(p => p.typeRule(), 'type reporting.public.bug_status varchar\n')).toEqual({result: {
                kind: 'Type',
                catalog: identifier('reporting', 5, 13, 1, 1, 6, 14),
                schema: identifier('public', 15, 20, 1, 1, 16, 21),
                name: identifier('bug_status', 22, 31, 1, 1, 23, 32),
                content: {kind: 'alias', name: identifier('varchar', 33, 39, 1, 1, 34, 40)},
            }})
        })
        test('metadata', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status varchar {tags: seo} | a note # a comment\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5, 14, 1, 1, 6, 15),
                content: {kind: 'alias', name: identifier('varchar', 16, 22, 1, 1, 17, 23)},
                properties: [{
                    key: identifier('tags', 25, 28, 1, 1, 26, 29),
                    sep: tokenPosition(29, 29, 1, 30, 1, 30),
                    value: identifier('seo', 31, 33, 1, 1, 32, 34)
                }],
                doc: doc('a note', 36, 44, 1, 1, 37, 45),
                comment: comment('a comment', 45, 55, 1, 1, 46, 56),
            }})
        })
        // TODO: test bad
    })
    describe('emptyStatementRule', () => {
        test('basic', () => expect(parseRule(p => p.emptyStatementRule(), '\n')).toEqual({result: {kind: 'Empty'}}))
        test('with spaces', () => expect(parseRule(p => p.emptyStatementRule(), '  \n')).toEqual({result: {kind: 'Empty'}}))
        test('with comment', () => expect(parseRule(p => p.emptyStatementRule(), ' # hello\n')).toEqual({result: {kind: 'Empty', comment: comment('hello', 1, 7, 1, 1, 2, 8)}}))
    })
    describe('legacy', () => {
        test('attribute type', () => {
            // as `varchar(12)` is valid on both v1 & v2 but has different meaning, it's handled when building AML, see aml-legacy.test.ts
            expect(parseRule(p => p.attributeRule(), '  name varchar(12)\n').result).toEqual({
                nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('name', 2, 5, 1, 1, 3, 6),
                type: identifier('varchar', 7, 13, 1, 1, 8, 14),
                enumValues: [integer(12, 15, 16, 1, 1, 16, 17)]
            })
        })
        test('attribute relation', () => {
            const v1 = parseRule(p => p.attributeRule(), '  user_id fk users.id\n').result?.relation as AttributeRelationAst
            const v2 = parseRule(p => p.attributeRule(), '  user_id -> users(id)\n').result?.relation
            expect(v1).toEqual({
                srcCardinality: 'n',
                refCardinality: '1',
                ref: {
                    entity: identifier('users', 13, 17, 1, 1, 14, 18),
                    attrs: [identifier('id', 19, 20, 1, 1, 20, 21)],
                    warning: {...tokenPosition(13, 20, 1, 14, 1, 21), issues: [legacy('"users.id" is the legacy way, use "users(id)" instead')]}
                },
                warning: {...tokenPosition(10, 11, 1, 11, 1, 12), issues: [legacy('"fk" is legacy, replace it with "->"')]}
            })
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
        })
        test('standalone relation', () => {
            const v1 = parseRule(p => p.relationRule(), 'fk groups.owner -> users.id\n')
            const v2 = parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id)\n')
            expect(v1).toEqual({result: {
                kind: 'Relation',
                srcCardinality: 'n',
                refCardinality: '1',
                src: {
                    entity: identifier('groups', 3, 8, 1, 1, 4, 9),
                    attrs: [identifier('owner', 10, 14, 1, 1, 11, 15)],
                    warning: {...tokenPosition(3, 14, 1, 4, 1, 15), issues: [legacy('"groups.owner" is the legacy way, use "groups(owner)" instead')]}
                },
                ref: {
                    entity: identifier('users', 19, 23, 1, 1, 20, 24),
                    attrs: [identifier('id', 25, 26, 1, 1, 26, 27)],
                    warning: {...tokenPosition(19, 26, 1, 20, 1, 27), issues: [legacy('"users.id" is the legacy way, use "users(id)" instead')]}
                },
                warning: {...tokenPosition(0, 1, 1, 1, 1, 2), issues: [legacy('"fk" is legacy, replace it with "rel"')]}
            }})
            expect(removeFieldsDeep(v1, ['offset', 'position', 'warning'])).toEqual(removeFieldsDeep(v2, ['offset', 'position']))
        })
        test('nested attribute', () => {
            const v1 = parseRule(p => p.attributeRefRule(), 'users.settings:github')
            const v2 = parseRule(p => p.attributeRefRule(), 'users(settings.github)')
            expect(v1).toEqual({result: {
                entity: identifier('users', 0, 4, 1, 1, 1, 5),
                attr: {...identifier('settings', 6, 13, 1, 1, 7, 14), path: [identifier('github', 15, 20, 1, 1, 16, 21)]},
                warning: {...tokenPosition(0, 20, 1, 1, 1, 21), issues: [legacy('"users.settings:github" is the legacy way, use "users(settings.github)" instead')]}
            }})
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
            expect(removeFieldsDeep(parseRule(p => p.attributeRefRule(), 'public.users.settings:github'), ['warning'])).toEqual(parseRule(p => p.attributeRefRule(), 'public.users(settings.github)'))
        })
        test('nested attribute composite', () => {
            const v1 = parseRule(p => p.attributeRefCompositeRule(), 'users.settings:github')
            const v2 = parseRule(p => p.attributeRefCompositeRule(), 'users(settings.github)')
            expect(v1).toEqual({result: {
                entity: identifier('users', 0, 4, 1, 1, 1, 5),
                attrs: [{...identifier('settings', 6, 13, 1, 1, 7, 14), path: [identifier('github', 15, 20, 1, 1, 16, 21)]}],
                warning: {...tokenPosition(0, 20, 1, 1, 1, 21), issues: [legacy('"users.settings:github" is the legacy way, use "users(settings.github)" instead')]},
            }})
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
            expect(removeFieldsDeep(parseRule(p => p.attributeRefCompositeRule(), 'public.users.settings:github'), ['warning'])).toEqual(parseRule(p => p.attributeRefCompositeRule(), 'public.users(settings.github)'))
        })
        test('properties', () => {
            expect(parseRule(p => p.propertiesRule(), '{color=red}')).toEqual({result: [{
                key: identifier('color', 1, 5, 1, 1, 2, 6),
                sep: {...tokenPosition(6, 6, 1, 7, 1, 7), issues: [legacy('"=" is legacy, replace it with ":"')]},
                value: identifier('red', 7, 9, 1, 1, 8, 10),
            }]})
        })
        test('check identifier', () => {
            const v1 = parseRule(p => p.attributeRule(), '  age int check="age > 0"\n').result
            const v2 = parseRule(p => p.attributeRule(), '  age int check(`age > 0`)\n').result
            expect(v1).toEqual({
                nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('age', 2, 4, 1, 1, 3, 5),
                type: identifier('int', 6, 8, 1, 1, 7, 9),
                check: {
                    token: tokenPosition(10, 14, 1, 11, 1, 15),
                    predicate: expression('age > 0', 15, 24, 1, 1, 16, 25, [legacy('"=age > 0" is the legacy way, use expression instead "(`age > 0`)"')]),
                },
            })
            expect(removeFieldsDeep(v1, ['issues', 'offset', 'position', 'quoted'])).toEqual(removeFieldsDeep(v2, ['issues', 'offset', 'position']))
        })
    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: integer(12, 0, 1, 1, 1, 1, 2)})
            expect(parseRule(p => p.integerRule(), '1.2')).toEqual({errors: [{message: "Expecting token of type --> Integer <-- but found --> '1.2' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('decimalRule', () => {
            expect(parseRule(p => p.decimalRule(), '1.2')).toEqual({result: decimal(1.2, 0, 2, 1, 1, 1, 3)})
            expect(parseRule(p => p.decimalRule(), '12')).toEqual({errors: [{message: "Expecting token of type --> Decimal <-- but found --> '12' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 1, 1, 1, 1, 2)}]})
            expect(parseRule(p => p.decimalRule(), 'bad')).toEqual({errors: [{message: "Expecting token of type --> Decimal <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: identifier('id', 0, 1, 1, 1, 1, 2)})
            expect(parseRule(p => p.identifierRule(), 'user_id')).toEqual({result: identifier('user_id', 0, 6, 1, 1, 1, 7)})
            expect(parseRule(p => p.identifierRule(), 'C##INVENTORY')).toEqual({result: identifier('C##INVENTORY', 0, 11, 1, 1, 1, 12)})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {...identifier('my col', 0, 7, 1, 1, 1, 8), quoted: true}})
            expect(parseRule(p => p.identifierRule(), '"varchar[]"')).toEqual({result: {...identifier('varchar[]', 0, 10, 1, 1, 1, 11), quoted: true}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {...identifier('my "new" col', 0, 15, 1, 1, 1, 16), quoted: true}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({result: identifier('bad', 0, 2, 1, 1, 1, 3), errors: [{message: "Redundant input, expecting EOF but found:  ", kind: 'NotAllInputParsedException', level: 'error', ...tokenPosition(3, 3, 1, 4, 1, 4)}]})
        })
        test('commentRule', () => {
            expect(parseRule(p => p.commentRule(), '# a comment')).toEqual({result: comment('a comment', 0, 10, 1, 1, 1, 11)})
            expect(parseRule(p => p.commentRule(), 'bad')).toEqual({errors: [{message: "Expecting token of type --> Comment <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('noteRule', () => {
            expect(parseRule(p => p.docRule(), '| a note')).toEqual({result: doc('a note', 0, 7, 1, 1, 1, 8)})
            expect(parseRule(p => p.docRule(), '| "a # note"')).toEqual({result: doc('a # note', 0, 11, 1, 1, 1, 12)})
            expect(parseRule(p => p.docRule(), '|||\n   a note\n   multiline\n|||')).toEqual({result: {...doc('a note\nmultiline', 0, 29, 1, 4, 1, 3), multiLine: true}})
            expect(parseRule(p => p.docRule(), 'bad')).toEqual({errors: [{message: "Expecting: one of these possible Token sequences:\n  1. [DocMultiline]\n  2. [Doc]\nbut found: 'bad'", kind: 'NoViableAltException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('propertiesRule', () => {
            expect(parseRule(p => p.propertiesRule(), '{}')).toEqual({result: []})
            expect(parseRule(p => p.propertiesRule(), '{flag}')).toEqual({result: [{key: identifier('flag', 1, 4, 1, 1, 2, 5)}]})
            expect(parseRule(p => p.propertiesRule(), '{color: red}')).toEqual({result: [{
                key: identifier('color', 1, 5, 1, 1, 2, 6),
                sep: tokenPosition(6, 6, 1, 7, 1, 7),
                value: identifier('red', 8, 10, 1, 1, 9, 11)
            }]})
            expect(parseRule(p => p.propertiesRule(), '{size: 12}')).toEqual({result: [{
                key: identifier('size', 1, 4, 1, 1, 2, 5),
                sep: tokenPosition(5, 5, 1, 6, 1, 6),
                value: integer(12, 7, 8, 1, 1, 8, 9)
            }]})
            expect(parseRule(p => p.propertiesRule(), '{tags: []}')).toEqual({result: [{
                key: identifier('tags', 1, 4, 1, 1, 2, 5),
                sep: tokenPosition(5, 5, 1, 6, 1, 6),
                value: []
            }]})
            expect(parseRule(p => p.propertiesRule(), '{tags: [pii, deprecated]}')).toEqual({result: [{
                key: identifier('tags', 1, 4, 1, 1, 2, 5),
                sep: tokenPosition(5, 5, 1, 6, 1, 6),
                value: [identifier('pii', 8, 10, 1, 1, 9, 11), identifier('deprecated', 13, 22, 1, 1, 14, 23)]
            }]})
            expect(parseRule(p => p.propertiesRule(), '{color:red, size : 12 , deprecated}')).toEqual({result: [{
                key: identifier('color', 1, 5, 1, 1, 2, 6),
                sep: tokenPosition(6, 6, 1, 7, 1, 7),
                value: identifier('red', 7, 9, 1, 1, 8, 10)
            }, {
                key: identifier('size', 12, 15, 1, 1, 13, 16),
                sep: tokenPosition(17, 17, 1, 18, 1, 18),
                value: integer(12, 19, 20, 1, 1, 20, 21)
            }, {
                key: identifier('deprecated', 24, 33, 1, 1, 25, 34)
            }]})

            // bad
            expect(parseRule(p => p.propertiesRule(), 'bad')).toEqual({errors: [
                {message: "Expecting token of type --> CurlyLeft <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 2, 1, 1, 1, 3)},
                {message: "Expecting token of type --> CurlyRight <-- but found --> '' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(-1, -1, -1, -1, -1, -1)},
            ]})
            expect(parseRule(p => p.propertiesRule(), '{')).toEqual({errors: [{message: "Expecting token of type --> CurlyRight <-- but found --> '' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(-1, -1, -1, -1, -1, -1)}]})
        })
        test('extraRule', () => {
            expect(parseRule(p => p.extraRule(), '')).toEqual({result: {}})
            expect(parseRule(p => p.extraRule(), '{key: value} | some note # a comment')).toEqual({result: {
                properties: [{
                    key: identifier('key', 1, 3, 1, 1, 2, 4),
                    sep: tokenPosition(4, 4, 1, 5, 1, 5),
                    value: identifier('value', 6, 10, 1, 1, 7, 11)
                }],
                doc: doc('some note', 13, 24, 1, 1, 14, 25),
                comment: comment('a comment', 25, 35, 1, 1, 26, 36),
            }})
        })
        test('entityRefRule', () => {
            expect(parseRule(p => p.entityRefRule(), 'users')).toEqual({result: {entity: identifier('users', 0, 4, 1, 1, 1, 5)}})
            expect(parseRule(p => p.entityRefRule(), 'public.users')).toEqual({result: {
                entity: identifier('users', 7, 11, 1, 1, 8, 12),
                schema: identifier('public', 0, 5, 1, 1, 1, 6),
            }})
            expect(parseRule(p => p.entityRefRule(), 'core.public.users')).toEqual({result: {
                entity: identifier('users', 12, 16, 1, 1, 13, 17),
                schema: identifier('public', 5, 10, 1, 1, 6, 11),
                catalog: identifier('core', 0, 3, 1, 1, 1, 4),
            }})
            expect(parseRule(p => p.entityRefRule(), 'analytics.core.public.users')).toEqual({result: {
                entity: identifier('users', 22, 26, 1, 1, 23, 27),
                schema: identifier('public', 15, 20, 1, 1, 16, 21),
                catalog: identifier('core', 10, 13, 1, 1, 11, 14),
                database: identifier('analytics', 0, 8, 1, 1, 1, 9),
            }})
            expect(parseRule(p => p.entityRefRule(), '42')).toEqual({errors: [{message: "Expecting token of type --> Identifier <-- but found --> '42' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 1, 1, 1, 1, 2)}]})
        })
        test('columnPathRule', () => {
            expect(parseRule(p => p.attributePathRule(), 'details')).toEqual({result: identifier('details', 0, 6, 1, 1, 1, 7)})
            expect(parseRule(p => p.attributePathRule(), 'details.address.street')).toEqual({result: {
                ...identifier('details', 0, 6, 1, 1, 1, 7),
                path: [identifier('address', 8, 14, 1, 1, 9, 15), identifier('street', 16, 21, 1, 1, 17, 22)],
            }})
            expect(parseRule(p => p.attributePathRule(), '42')).toEqual({errors: [{message: "Expecting token of type --> Identifier <-- but found --> '42' <--", kind: 'MismatchedTokenException', level: 'error', ...tokenPosition(0, 1, 1, 1, 1, 2)}]})
        })
        test('columnRefRule', () => {
            expect(parseRule(p => p.attributeRefRule(), 'users(id)')).toEqual({result: {
                entity: identifier('users', 0, 4, 1, 1, 1, 5),
                attr: identifier('id', 6, 7, 1, 1, 7, 8),
            }})
            expect(parseRule(p => p.attributeRefRule(), 'public.events(details.item_id)')).toEqual({result: {
                schema: identifier('public', 0, 5, 1, 1, 1, 6),
                entity: identifier('events', 7, 12, 1, 1, 8, 13),
                attr: {...identifier('details', 14, 20, 1, 1, 15, 21), path: [identifier('item_id', 22, 28, 1, 1, 23, 29)]},
            }})
        })
        test('columnRefCompositeRule', () => {
            expect(parseRule(p => p.attributeRefCompositeRule(), 'user_roles(user_id, role_id)')).toEqual({result: {
                entity: identifier('user_roles', 0, 9, 1, 1, 1, 10),
                attrs: [
                    identifier('user_id', 11, 17, 1, 1, 12, 18),
                    identifier('role_id', 20, 26, 1, 1, 21, 27),
                ],
            }})
        })
        test('columnValueRule', () => {
            expect(parseRule(p => p.attributeValueRule(), '42')).toEqual({result: integer(42, 0, 1, 1, 1, 1, 2)})
            expect(parseRule(p => p.attributeValueRule(), '2.0')).toEqual({result: decimal(2, 0, 2, 1, 1, 1, 3)})
            expect(parseRule(p => p.attributeValueRule(), '3.14')).toEqual({result: decimal(3.14, 0, 3, 1, 1, 1, 4)})
            expect(parseRule(p => p.attributeValueRule(), 'User')).toEqual({result: identifier('User', 0, 3, 1, 1, 1, 4)})
            expect(parseRule(p => p.attributeValueRule(), '"a user"')).toEqual({result: {...identifier('a user', 0, 7, 1, 1, 1, 8), quoted: true}})
        })
    })
    describe('utils', () => {
        test('nestAttributes', () => {
            expect(nestAttributes([])).toEqual([])
            expect(nestAttributes([{
                nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('id', 8, 9, 2, 2, 3, 4),
                type: identifier('int', 11, 13, 2, 2, 6, 8),
                primaryKey: {token: tokenPosition(15, 16, 2, 10, 2, 11)}
            }, {
                nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('name', 20, 23, 3, 3, 3, 6),
                type: identifier('varchar', 25, 31, 3, 3, 8, 14)
            }, {
                nesting: {depth: 0, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('settings', 35, 42, 4, 4, 3, 10),
                type: identifier('json', 44, 47, 4, 4, 12, 15)
            }, {
                nesting: {depth: 1, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('address', 53, 59, 5, 5, 5, 11),
                type: identifier('json', 61, 64, 5, 5, 13, 16)
            }, {
                nesting: {depth: 2, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('street', 72, 77, 6, 6, 7, 12),
                type: identifier('string', 79, 84, 6, 6, 14, 19)
            }, {
                nesting: {depth: 2, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('city', 92, 95, 7, 7, 7, 10),
                type: identifier('string', 97, 102, 7, 7, 12, 17)
            }, {
                nesting: {depth: 1, token: tokenPosition(0, 1, 1, 1, 1, 2)},
                name: identifier('github', 108, 113, 8, 8, 5, 10),
                type: identifier('string', 115, 120, 8, 8, 12, 17)
            }])).toEqual([{
                path: [identifier('id', 8, 9, 2, 2, 3, 4)],
                type: identifier('int', 11, 13, 2, 2, 6, 8),
                primaryKey: {token: tokenPosition(15, 16, 2, 10, 2, 11)},
            }, {
                path: [identifier('name', 20, 23, 3, 3, 3, 6)],
                type: identifier('varchar', 25, 31, 3, 3, 8, 14),
            }, {
                path: [identifier('settings', 35, 42, 4, 4, 3, 10)],
                type: identifier('json', 44, 47, 4, 4, 12, 15),
                attrs: [{
                    path: [identifier('settings', 35, 42, 4, 4, 3, 10), identifier('address', 53, 59, 5, 5, 5, 11)],
                    type: identifier('json', 61, 64, 5, 5, 13, 16),
                    attrs: [{
                        path: [identifier('settings', 35, 42, 4, 4, 3, 10), identifier('address', 53, 59, 5, 5, 5, 11), identifier('street', 72, 77, 6, 6, 7, 12)],
                        type: identifier('string', 79, 84, 6, 6, 14, 19),
                    }, {
                        path: [identifier('settings', 35, 42, 4, 4, 3, 10), identifier('address', 53, 59, 5, 5, 5, 11), identifier('city', 92, 95, 7, 7, 7, 10)],
                        type: identifier('string', 97, 102, 7, 7, 12, 17),
                    }]
                }, {
                    path: [identifier('settings', 35, 42, 4, 4, 3, 10), identifier('github', 108, 113, 8, 8, 5, 10)],
                    type: identifier('string', 115, 120, 8, 8, 12, 17),
                }]
            }])
        })
    })
})

// doc('some note', 13, 24, 1, 1, 14, 25)
function doc(value: string, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): DocAst {
    return {kind: 'Doc', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function comment(value: string, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): CommentAst {
    return {kind: 'Comment', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function expression(value: string, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number, issues?: TokenIssue[]): ExpressionAst {
    return {kind: 'Expression', token: issues ? {...tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), issues} : tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function identifier(value: string, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): IdentifierAst {
    return {kind: 'Identifier', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function integer(value: number, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): IntegerAst {
    return {kind: 'Integer', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function decimal(value: number, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): DecimalAst {
    return {kind: 'Decimal', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function boolean(value: boolean, start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): BooleanAst {
    return {kind: 'Boolean', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd), value}
}

function null_(start: number, end: number, lineStart: number, lineEnd: number, columnStart: number, columnEnd: number): NullAst {
    return {kind: 'Null', token: tokenPosition(start, end, lineStart, columnStart, lineEnd, columnEnd)}
}
