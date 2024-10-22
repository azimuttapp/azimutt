import {describe, expect, test} from "@jest/globals";
import {removeFieldsDeep} from "@azimutt/utils";
import {TokenPosition} from "@azimutt/models";
import {
    BooleanAst,
    CommentAst,
    DecimalAst,
    DocAst,
    ExpressionAst,
    IdentifierAst,
    IntegerAst,
    NullAst,
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
                constraints: [{kind: 'PrimaryKey', token: token(17, 18, 3, 3, 11, 12)}],
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
                schema: identifier('public', 10),
            }})
        })
        test('catalog', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace core.public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                catalog: identifier('core', 10),
                schema: identifier('public', 15),
            }})
        })
        test('database', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace analytics.core.public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                database: identifier('analytics', 10),
                catalog: identifier('core', 20),
                schema: identifier('public', 25),
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace public | a note # and a comment\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                schema: identifier('public', 10),
                doc: doc('a note', 17),
                comment: comment('and a comment', 26),
            }})
        })
        test('empty catalog', () => {
            expect(parseRule(p => p.namespaceStatementRule(), 'namespace analytics..public\n')).toEqual({result: {
                kind: 'Namespace',
                line: 1,
                database: identifier('analytics', 10),
                schema: identifier('public', 21),
            }})
        })
    })
    describe('entityRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.entityRule(), 'users\n')).toEqual({result: {kind: 'Entity', name: identifier('users', 0)}})
        })
        test('namespace', () => {
            expect(parseRule(p => p.entityRule(), 'public.users\n')).toEqual({result: {
                kind: 'Entity',
                schema: identifier('public', 0),
                name: identifier('users', 7),
            }})
            expect(parseRule(p => p.entityRule(), 'core.public.users\n')).toEqual({result: {
                kind: 'Entity',
                catalog: identifier('core', 0),
                schema: identifier('public', 5),
                name: identifier('users', 12),
            }})
            expect(parseRule(p => p.entityRule(), 'ax.core.public.users\n')).toEqual({result: {
                kind: 'Entity',
                database: identifier('ax', 0),
                catalog: identifier('core', 3),
                schema: identifier('public', 8),
                name: identifier('users', 15),
            }})
        })
        test('view', () => {
            expect(parseRule(p => p.entityRule(), 'users*\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0),
                view: token(5, 5)
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.entityRule(), 'users as u\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0),
                alias: identifier('u', 9),
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.entityRule(), 'users {domain: auth} | list users # sample comment\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0),
                properties: [{
                    key: identifier('domain', 7),
                    sep: token(13, 13),
                    value: identifier('auth', 15),
                }],
                doc: doc('list users', 21),
                comment: comment('sample comment', 34),
            }})
        })
        test('attributes', () => {
            expect(parseRule(p => p.entityRule(), 'users\n  id uuid pk\n  name varchar\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0),
                attrs: [{
                    path: [identifier('id', 8, 9, 2, 2, 3, 4)],
                    type: identifier('uuid', 11, 14, 2, 2, 6, 9),
                    constraints: [{kind: 'PrimaryKey', token: token(16, 17, 2, 2, 11, 12)}],
                }, {
                    path: [identifier('name', 21, 24, 3, 3, 3, 6)],
                    type: identifier('varchar', 26, 32, 3, 3, 8, 14),
                }],
            }})
            expect(parseRule(p => p.entityRule(), 'users\n  id uuid pk\n  name json\n      first string\n')).toEqual({result: {
                kind: 'Entity',
                name: identifier('users', 0),
                attrs: [{
                    path: [identifier('id', 8, 9, 2, 2, 3, 4)],
                    type: identifier('uuid', 11, 14, 2, 2, 6, 9),
                    constraints: [{kind: 'PrimaryKey', token: token(16, 17, 2, 2, 11, 12)}],
                }, {
                    path: [identifier('name', 21, 24, 3, 3, 3, 6)],
                    type: identifier('json', 26, 29, 3, 3, 8, 11),
                    attrs: [{
                        path: [identifier('name', 21, 24, 3, 3, 3, 6), identifier('first', 37, 41, 4, 4, 7, 11)],
                        type: identifier('string', 43, 48, 4, 4, 13, 18),
                        warning: {issues: [badIndent(1, 2)], ...token(31, 36, 4, 4, 1, 6)}
                    }]
                }],
            }})
        })
        describe('attributeRule', () => {
            test('name', () => {
                expect(parseRule(p => p.attributeRule(), '  id\n')).toEqual({result: {nesting: {depth: 0, token: token(0, 1)}, name: identifier('id', 2)}})
                expect(parseRule(p => p.attributeRule(), '  "index"\n')).toEqual({result: {nesting: {depth: 0, token: token(0, 1)}, name: {...identifier('index', 2, 8), quoted: true}}})
                expect(parseRule(p => p.attributeRule(), '  fk_col\n')).toEqual({result: {nesting: {depth: 0, token: token(0, 1)}, name: identifier('fk_col', 2)}})
            })
            test('type', () => {
                expect(parseRule(p => p.attributeRule(), '  id uuid\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    type: identifier('uuid', 5),
                }})
                expect(parseRule(p => p.attributeRule(), '  name "varchar(12)"\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('name', 2),
                    type: {...identifier('varchar(12)', 7, 19), quoted: true},
                }})
                expect(parseRule(p => p.attributeRule(), '  bio "character varying"\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('bio', 2),
                    type: {...identifier('character varying', 6, 24), quoted: true},
                }})
                expect(parseRule(p => p.attributeRule(), '  id "type"\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    type: {...identifier('type', 5, 10), quoted: true},
                }})
            })
            test('enum', () => {
                expect(parseRule(p => p.attributeRule(), '  status post_status(draft, published, archived)\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('status', 2),
                    type: identifier('post_status', 9),
                    enumValues: [
                        identifier('draft', 21),
                        identifier('published', 28),
                        identifier('archived', 39),
                    ],
                }})
            })
            test('default', () => {
                expect(parseRule(p => p.attributeRule(), '  id int=0\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    type: identifier('int', 5),
                    defaultValue: integer(0, 9),
                }})
                expect(parseRule(p => p.attributeRule(), '  price decimal=41.9\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('price', 2),
                    type: identifier('decimal', 8),
                    defaultValue: decimal(41.9, 16),
                }})
                expect(parseRule(p => p.attributeRule(), '  role varchar=guest\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('role', 2),
                    type: identifier('varchar', 7),
                    defaultValue: identifier('guest', 15),
                }})
                expect(parseRule(p => p.attributeRule(), '  is_admin boolean=false\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('is_admin', 2),
                    type: identifier('boolean', 11),
                    defaultValue: boolean(false, 19),
                }})
                expect(parseRule(p => p.attributeRule(), '  created_at timestamp=`now()`\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('created_at', 2),
                    type: identifier('timestamp', 13),
                    defaultValue: expression('now()', 23),
                }})
                expect(parseRule(p => p.attributeRule(), '  source varchar=null\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('source', 2),
                    type: identifier('varchar', 9),
                    defaultValue: null_(17),
                }})
                // TODO: handle `[]` default value? Ex: '  tags varchar[]=[]\n' instead of '  tags varchar[]="[]"\n'
                // TODO: handle `{}` default value? Ex: '  details json={}\n' instead of '  details json="{}"\n'
            })
            test('nullable', () => {
                expect(parseRule(p => p.attributeRule(), '  id nullable\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    nullable: token(5, 12),
                }})
                expect(parseRule(p => p.attributeRule(), '  id int nullable\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    type: identifier('int', 5),
                    nullable: token(9, 16),
                }})
            })
            test('pk', () => {
                expect(parseRule(p => p.attributeRule(), '  id pk\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'PrimaryKey', token: token(5, 6)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id int pk\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    type: identifier('int', 5),
                    constraints: [{kind: 'PrimaryKey', token: token(9, 10)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id int pk=pk_name\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    type: identifier('int', 5),
                    constraints: [{kind: 'PrimaryKey', token: token(9, 10), name: identifier('pk_name', 12)}],
                }})
            })
            test('index', () => {
                expect(parseRule(p => p.attributeRule(), '  id index\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Index', token: token(5, 9)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id index=id_idx\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Index', token: token(5, 9), name: identifier('id_idx', 11)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id index = "idx \\" id"\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Index', token: token(5, 9), name: {...identifier('idx " id', 13, 23), quoted: true}}],
                }})
            })
            test('unique', () => {
                expect(parseRule(p => p.attributeRule(), '  id unique\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Unique', token: token(5, 10)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id unique=id_uniq\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Unique', token: token(5, 10), name: identifier('id_uniq', 12)}],
                }})
            })
            test('check', () => {
                expect(parseRule(p => p.attributeRule(), '  id check\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Check', token: token(5, 9)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id check=id_chk\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Check', token: token(5, 9), name: identifier('id_chk', 11)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id check(`id > 0`)\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{kind: 'Check', token: token(5, 9), predicate: expression('id > 0', 11)}],
                }})
                expect(parseRule(p => p.attributeRule(), '  id check(`id > 0`)=id_chk\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    constraints: [{
                        kind: 'Check',
                        token: token(5, 9),
                        predicate: expression('id > 0', 11),
                        name: identifier('id_chk', 21)
                    }],
                }})
            })
            test('relation', () => {
                expect(parseRule(p => p.attributeRule(), '  user_id -> users(id)\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('user_id', 2),
                    constraints: [{
                        kind: 'Relation',
                        token: token(10, 11),
                        refCardinality: {kind: '1', token: token(10, 10)},
                        srcCardinality: {kind: 'n', token: token(11, 11)},
                        ref: {entity: identifier('users', 13), attrs: [identifier('id', 19)]}
                    }]
                }})
                expect(parseRule(p => p.attributeRule(), '  user_id -> users\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('user_id', 2),
                    constraints: [{
                        kind: 'Relation',
                        token: token(10, 11),
                        refCardinality: {kind: '1', token: token(10, 10)},
                        srcCardinality: {kind: 'n', token: token(11, 11)},
                        ref: {entity: identifier('users', 13), attrs: []}
                    }]
                }})
            })
            test('properties', () => {
                expect(parseRule(p => p.attributeRule(), '  id {tag: pii}\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    properties: [{key: identifier('tag', 6), sep: token(9, 9), value: identifier('pii', 11)}],
                }})
            })
            test('note', () => {
                expect(parseRule(p => p.attributeRule(), '  id | some note\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    doc: doc('some note', 5, 15),
                }})
            })
            test('comment', () => {
                expect(parseRule(p => p.attributeRule(), '  id # a comment\n')).toEqual({result: {
                    nesting: {depth: 0, token: token(0, 1)},
                    name: identifier('id', 2),
                    comment: comment('a comment', 5),
                }})
            })
            test('several identical constraints', () => {
                expect(parseRule(p => p.attributeRule(), '  item_id int nullable index index=idx check(`item_id > 0`) check(`item_id < 0`) -kind=users> public.users(id) -kind=posts> posts(id)\n')).toEqual({result: {
                    nesting: {token: token(0, 1), depth: 0},
                    name: identifier('item_id', 2),
                    type: identifier('int', 10),
                    nullable: token(14, 21),
                    constraints: [
                        {kind: 'Index', token: token(23, 27)},
                        {kind: 'Index', token: token(29, 33), name: identifier('idx', 35)},
                        {kind: 'Check', token: token(39, 43), predicate: expression('item_id > 0', 45)},
                        {kind: 'Check', token: token(60, 64), predicate: expression('item_id < 0', 66)},
                        {
                            kind: 'Relation',
                            token: token(81, 92),
                            refCardinality: {kind: '1', token: token(81, 81)},
                            polymorphic: {attr: identifier('kind', 82), value: identifier('users', 87)},
                            srcCardinality: {kind: 'n', token: token(92, 92)},
                            ref: {schema: identifier('public', 94), entity: identifier('users', 101), attrs: [identifier('id', 107)]}
                        },
                        {
                            kind: 'Relation',
                            token: token(111, 122),
                            refCardinality: {kind: '1', token: token(111, 111)},
                            polymorphic: {attr: identifier('kind', 112), value: identifier('posts', 117)},
                            srcCardinality: {kind: 'n', token: token(122, 122)},
                            ref: {entity: identifier('posts', 124), attrs: [identifier('id', 130)]}
                        }
                    ]
                }})
            })
            test('all', () => {
                expect(parseRule(p => p.attributeRule(), '    id int(8, 9, 10)=8 nullable pk unique index=idx check(`id > 0`) -kind=users> public.users(id) { tag : pii , owner:PANDA} | some note # comment\n')).toEqual({result: {
                    nesting: {depth: 1, token: token(0, 3)},
                    name: identifier('id', 4),
                    type: identifier('int', 7),
                    enumValues: [integer(8, 11), integer(9, 14), integer(10, 17)],
                    defaultValue: integer(8, 21),
                    nullable: token(23, 30),
                    constraints: [
                        {kind: 'PrimaryKey', token: token(32, 33)},
                        {kind: 'Unique', token: token(35, 40)},
                        {kind: 'Index', token: token(42, 46), name: identifier('idx', 48)},
                        {kind: 'Check', token: token(52, 56), predicate: expression('id > 0', 58)},
                        {
                            kind: 'Relation',
                            token: token(68, 79),
                            refCardinality: {kind: '1', token: token(68, 68)},
                            polymorphic: {attr: identifier('kind', 69), value: identifier('users', 74)},
                            srcCardinality: {kind: 'n', token: token(79, 79)},
                            ref: {schema: identifier('public', 81), entity: identifier('users', 88), attrs: [identifier('id', 94)]},
                        },
                    ],
                    properties: [
                        {key: identifier('tag', 100), sep: token(104, 104), value: identifier('pii', 106)},
                        {key: identifier('owner', 112), sep: token(117, 117), value: identifier('PANDA', 118)},
                    ],
                    doc: doc('some note', 125),
                    comment: comment('comment', 137),
                }})
            })
            test('error', () => {
                expect(parseRule(p => p.attributeRule(), '  12\n')).toEqual({result: {nesting: {depth: 0, token: token(0, 1)}}, errors: [{message: "Expecting token of type --> Identifier <-- but found --> '12' <--", kind: 'MismatchedTokenException', level: 'error', ...token(2, 3)}]})
            })
        })
    })
    describe('relationRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id)\n')).toEqual({result: {
                kind: 'Relation',
                src: {entity: identifier('groups', 4), attrs: [identifier('owner', 11)]},
                refCardinality: {kind: '1', token: token(18, 18)},
                srcCardinality: {kind: 'n', token: token(19, 19)},
                ref: {entity: identifier('users', 21), attrs: [identifier('id', 27)]},
            }})
        })
        test('one-to-one', () => {
            expect(parseRule(p => p.relationRule(), 'rel profiles(id) -- users(id)\n')).toEqual({result: {
                kind: 'Relation',
                src: {entity: identifier('profiles', 4), attrs: [identifier('id', 13)]},
                refCardinality: {kind: '1', token: token(17, 17)},
                srcCardinality: {kind: '1', token: token(18, 18)},
                ref: {entity: identifier('users', 20), attrs: [identifier('id', 26)]},
            }})
        })
        test('many-to-many', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(id) <> users(id)\n')).toEqual({result: {
                kind: 'Relation',
                src: {entity: identifier('groups', 4), attrs: [identifier('id', 11)]},
                refCardinality: {kind: 'n', token: token(15, 15)},
                srcCardinality: {kind: 'n', token: token(16, 16)},
                ref: {entity: identifier('users', 18), attrs: [identifier('id', 24)]},
            }})
        })
        test('composite', () => {
            expect(parseRule(p => p.relationRule(), 'rel audit(user_id, role_id) -> user_roles(user_id, role_id)\n')).toEqual({result: {
                kind: 'Relation',
                src: {entity: identifier('audit', 4), attrs: [identifier('user_id', 10), identifier('role_id', 19)],},
                refCardinality: {kind: '1', token: token(28, 28)},
                srcCardinality: {kind: 'n', token: token(29, 29)},
                ref: {entity: identifier('user_roles', 31), attrs: [identifier('user_id', 42), identifier('role_id', 51)]},
            }})
        })
        test('polymorphic', () => {
            expect(parseRule(p => p.relationRule(), 'rel events(item_id) -item_kind=User> users(id)\n')).toEqual({result: {
                kind: 'Relation',
                src: {entity: identifier('events', 4), attrs: [identifier('item_id', 11)]},
                refCardinality: {kind: '1', token: token(20, 20)},
                polymorphic: {attr: identifier('item_kind', 21), value: identifier('User', 31)},
                srcCardinality: {kind: 'n', token: token(35, 35)},
                ref: {entity: identifier('users', 37), attrs: [identifier('id', 43)]}
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id) {color: red} | a note # a comment\n')).toEqual({result: {
                kind: 'Relation',
                src: {entity: identifier('groups', 4), attrs: [identifier('owner', 11)]},
                refCardinality: {kind: '1', token: token(18, 18)},
                srcCardinality: {kind: 'n', token: token(19, 19)},
                ref: {entity: identifier('users', 21), attrs: [identifier('id', 27)]},
                properties: [{key: identifier('color', 32), sep: token(37, 37), value: identifier('red', 39)}],
                doc: doc('a note', 44),
                comment: comment('a comment', 53),
            }})
        })
        test('bad', () => {
            expect(parseRule(p => p.relationRule(), 'bad')).toEqual({errors: [{message: "Expecting: one of these possible Token sequences:\n  1. [Relation]\n  2. [ForeignKey]\nbut found: 'bad'", kind: 'NoViableAltException', level: 'error', ...token(0, 2)}]})
        })
    })
    describe('typeRule', () => {
        test('empty', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5),
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status varchar\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5),
                content: {kind: 'Alias', name: identifier('varchar', 16)},
            }})
        })
        test('enum', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status (new, "in progress", done)\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5),
                content: {kind: 'Enum', values: [
                    identifier('new', 17),
                    {...identifier('in progress', 22, 34), quoted: true},
                    identifier('done', 37),
                ]}
            }})
        })
        test('struct', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status {internal varchar, public varchar}\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5),
                content: {kind: 'Struct', attrs: [{
                    path: [identifier('internal', 17)],
                    type: identifier('varchar', 26),
                }, {
                    path: [identifier('public', 35)],
                    type: identifier('varchar', 42),
                }]}
            }})
            // FIXME: would be nice to have this alternative but the $.MANY fails, see `typeRule`
            /*expect(parseRule(p => p.typeRule(), 'type bug_status\n  internal varchar\n  public varchar\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5),
                content: {kind: 'Struct', attrs: [{
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
                name: identifier('bug_status', 5),
                content: {kind: 'Custom', definition: expression('range(subtype = float8, subtype_diff = float8mi)', 16)}
            }})
        })
        test('namespace', () => {
            expect(parseRule(p => p.typeRule(), 'type reporting.public.bug_status varchar\n')).toEqual({result: {
                kind: 'Type',
                catalog: identifier('reporting', 5),
                schema: identifier('public', 15),
                name: identifier('bug_status', 22),
                content: {kind: 'Alias', name: identifier('varchar', 33)},
            }})
        })
        test('metadata', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status varchar {tags: seo} | a note # a comment\n')).toEqual({result: {
                kind: 'Type',
                name: identifier('bug_status', 5),
                content: {kind: 'Alias', name: identifier('varchar', 16)},
                properties: [{
                    key: identifier('tags', 25),
                    sep: token(29, 29),
                    value: identifier('seo', 31)
                }],
                doc: doc('a note', 36),
                comment: comment('a comment', 45),
            }})
        })
        // TODO: test bad
    })
    describe('emptyStatementRule', () => {
        test('basic', () => expect(parseRule(p => p.emptyStatementRule(), '\n')).toEqual({result: {kind: 'Empty'}}))
        test('with spaces', () => expect(parseRule(p => p.emptyStatementRule(), '  \n')).toEqual({result: {kind: 'Empty'}}))
        test('with comment', () => expect(parseRule(p => p.emptyStatementRule(), ' # hello\n')).toEqual({result: {kind: 'Empty', comment: comment('hello', 1)}}))
    })
    describe('legacy', () => {
        test('attribute type', () => {
            // as `varchar(12)` is valid on both v1 & v2 but has different meaning, it's handled when building AML, see aml-legacy.test.ts
            expect(parseRule(p => p.attributeRule(), '  name varchar(12)\n').result).toEqual({
                nesting: {depth: 0, token: token(0, 1)},
                name: identifier('name', 2),
                type: identifier('varchar', 7),
                enumValues: [integer(12, 15)]
            })
        })
        test('attribute relation', () => {
            const v1 = parseRule(p => p.attributeRule(), '  user_id fk users.id\n').result?.constraints
            const v2 = parseRule(p => p.attributeRule(), '  user_id -> users(id)\n').result?.constraints
            expect(v1).toEqual([{
                kind: 'Relation',
                token: token(10, 11),
                refCardinality: {kind: '1', token: token(10, 11)},
                srcCardinality: {kind: 'n', token: token(10, 11)},
                ref: {
                    entity: identifier('users', 13),
                    attrs: [identifier('id', 19)],
                    warning: {...token(13, 20), issues: [legacy('"users.id" is the legacy way, use "users(id)" instead')]}
                },
                warning: {...token(10, 11), issues: [legacy('"fk" is legacy, replace it with "->"')]}
            }])
            expect(removeFieldsDeep(v1, ['token', 'warning'])).toEqual(removeFieldsDeep(v2, ['token']))
        })
        test('standalone relation', () => {
            const v1 = parseRule(p => p.relationRule(), 'fk groups.owner -> users.id\n')
            const v2 = parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id)\n')
            expect(v1).toEqual({result: {
                kind: 'Relation',
                src: {
                    entity: identifier('groups', 3),
                    attrs: [identifier('owner', 10)],
                    warning: {...token(3, 14), issues: [legacy('"groups.owner" is the legacy way, use "groups(owner)" instead')]}
                },
                refCardinality: {kind: '1', token: token(16, 16)},
                srcCardinality: {kind: 'n', token: token(17, 17)},
                ref: {
                    entity: identifier('users', 19),
                    attrs: [identifier('id', 25)],
                    warning: {...token(19, 26), issues: [legacy('"users.id" is the legacy way, use "users(id)" instead')]}
                },
                warning: {...token(0, 1), issues: [legacy('"fk" is legacy, replace it with "rel"')]}
            }})
            expect(removeFieldsDeep(v1, ['offset', 'position', 'warning'])).toEqual(removeFieldsDeep(v2, ['offset', 'position']))
        })
        test('nested attribute', () => {
            const v1 = parseRule(p => p.attributeRefRule(), 'users.settings:github')
            const v2 = parseRule(p => p.attributeRefRule(), 'users(settings.github)')
            expect(v1).toEqual({result: {
                entity: identifier('users', 0),
                attr: {...identifier('settings', 6), path: [identifier('github', 15)]},
                warning: {...token(0, 20), issues: [legacy('"users.settings:github" is the legacy way, use "users(settings.github)" instead')]}
            }})
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
            expect(removeFieldsDeep(parseRule(p => p.attributeRefRule(), 'public.users.settings:github'), ['warning'])).toEqual(parseRule(p => p.attributeRefRule(), 'public.users(settings.github)'))
        })
        test('nested attribute composite', () => {
            const v1 = parseRule(p => p.attributeRefCompositeRule(), 'users.settings:github')
            const v2 = parseRule(p => p.attributeRefCompositeRule(), 'users(settings.github)')
            expect(v1).toEqual({result: {
                entity: identifier('users', 0),
                attrs: [{...identifier('settings', 6), path: [identifier('github', 15)]}],
                warning: {...token(0, 20), issues: [legacy('"users.settings:github" is the legacy way, use "users(settings.github)" instead')]},
            }})
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
            expect(removeFieldsDeep(parseRule(p => p.attributeRefCompositeRule(), 'public.users.settings:github'), ['warning'])).toEqual(parseRule(p => p.attributeRefCompositeRule(), 'public.users(settings.github)'))
        })
        test('properties', () => {
            expect(parseRule(p => p.propertiesRule(), '{color=red}')).toEqual({result: [{
                key: identifier('color', 1),
                sep: {...token(6, 6), issues: [legacy('"=" is legacy, replace it with ":"')]},
                value: identifier('red', 7),
            }]})
        })
        test('check identifier', () => {
            const v1 = parseRule(p => p.attributeRule(), '  age int check="age > 0"\n').result
            const v2 = parseRule(p => p.attributeRule(), '  age int check(`age > 0`)\n').result
            expect(v1).toEqual({
                nesting: {depth: 0, token: token(0, 1)},
                name: identifier('age', 2),
                type: identifier('int', 6),
                constraints: [{
                    kind: 'Check',
                    token: token(10, 14),
                    predicate: expression('age > 0', 15, 24, 1, 1, 16, 25, [legacy('"=age > 0" is the legacy way, use expression instead "(`age > 0`)"')]),
                }],
            })
            expect(removeFieldsDeep(v1, ['issues', 'offset', 'position', 'quoted'])).toEqual(removeFieldsDeep(v2, ['issues', 'offset', 'position']))
        })
    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: integer(12, 0)})
            expect(parseRule(p => p.integerRule(), '1.2')).toEqual({errors: [{message: "Expecting token of type --> Integer <-- but found --> '1.2' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 2)}]})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 2)}]})
        })
        test('decimalRule', () => {
            expect(parseRule(p => p.decimalRule(), '1.2')).toEqual({result: decimal(1.2, 0)})
            expect(parseRule(p => p.decimalRule(), '12')).toEqual({errors: [{message: "Expecting token of type --> Decimal <-- but found --> '12' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 1)}]})
            expect(parseRule(p => p.decimalRule(), 'bad')).toEqual({errors: [{message: "Expecting token of type --> Decimal <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 2)}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: identifier('id', 0)})
            expect(parseRule(p => p.identifierRule(), 'user_id')).toEqual({result: identifier('user_id', 0)})
            expect(parseRule(p => p.identifierRule(), 'C##INVENTORY')).toEqual({result: identifier('C##INVENTORY', 0)})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {...identifier('my col', 0, 7), quoted: true}})
            expect(parseRule(p => p.identifierRule(), '"varchar[]"')).toEqual({result: {...identifier('varchar[]', 0, 10), quoted: true}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {...identifier('my "new" col', 0, 15), quoted: true}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({result: identifier('bad', 0), errors: [{message: "Redundant input, expecting EOF but found:  ", kind: 'NotAllInputParsedException', level: 'error', ...token(3, 3)}]})
        })
        test('commentRule', () => {
            expect(parseRule(p => p.commentRule(), '# a comment')).toEqual({result: comment('a comment', 0)})
            expect(parseRule(p => p.commentRule(), 'bad')).toEqual({errors: [{message: "Expecting token of type --> Comment <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 2)}]})
        })
        test('noteRule', () => {
            expect(parseRule(p => p.docRule(), '| a note')).toEqual({result: doc('a note', 0, 7)})
            expect(parseRule(p => p.docRule(), '| "a # note"')).toEqual({result: doc('a # note', 0, 11)})
            expect(parseRule(p => p.docRule(), '|||\n   a note\n   multiline\n|||')).toEqual({result: {...doc('a note\nmultiline', 0, 29, 1, 4, 1, 3), multiLine: true}})
            expect(parseRule(p => p.docRule(), 'bad')).toEqual({errors: [{message: "Expecting: one of these possible Token sequences:\n  1. [DocMultiline]\n  2. [Doc]\nbut found: 'bad'", kind: 'NoViableAltException', level: 'error', ...token(0, 2)}]})
        })
        test('propertiesRule', () => {
            expect(parseRule(p => p.propertiesRule(), '{}')).toEqual({result: []})
            expect(parseRule(p => p.propertiesRule(), '{flag}')).toEqual({result: [{key: identifier('flag', 1)}]})
            expect(parseRule(p => p.propertiesRule(), '{color: red}')).toEqual({result: [{
                key: identifier('color', 1),
                sep: token(6, 6),
                value: identifier('red', 8)
            }]})
            expect(parseRule(p => p.propertiesRule(), '{size: 12}')).toEqual({result: [{
                key: identifier('size', 1),
                sep: token(5, 5),
                value: integer(12, 7)
            }]})
            expect(parseRule(p => p.propertiesRule(), '{tags: []}')).toEqual({result: [{
                key: identifier('tags', 1),
                sep: token(5, 5),
                value: []
            }]})
            expect(parseRule(p => p.propertiesRule(), '{tags: [pii, deprecated]}')).toEqual({result: [{
                key: identifier('tags', 1),
                sep: token(5, 5),
                value: [identifier('pii', 8), identifier('deprecated', 13)]
            }]})
            expect(parseRule(p => p.propertiesRule(), '{color:red, size : 12 , deprecated}')).toEqual({result: [{
                key: identifier('color', 1),
                sep: token(6, 6),
                value: identifier('red', 7)
            }, {
                key: identifier('size', 12),
                sep: token(17, 17),
                value: integer(12, 19)
            }, {
                key: identifier('deprecated', 24)
            }]})

            // bad
            expect(parseRule(p => p.propertiesRule(), 'bad')).toEqual({errors: [
                {message: "Expecting token of type --> CurlyLeft <-- but found --> 'bad' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 2)},
                {message: "Expecting token of type --> CurlyRight <-- but found --> '' <--", kind: 'MismatchedTokenException', level: 'error', ...token(-1, -1, -1, -1, -1, -1)},
            ]})
            expect(parseRule(p => p.propertiesRule(), '{')).toEqual({errors: [{message: "Expecting token of type --> CurlyRight <-- but found --> '' <--", kind: 'MismatchedTokenException', level: 'error', ...token(-1, -1, -1, -1, -1, -1)}]})
        })
        test('extraRule', () => {
            expect(parseRule(p => p.extraRule(), '')).toEqual({result: {}})
            expect(parseRule(p => p.extraRule(), '{key: value} | some note # a comment')).toEqual({result: {
                properties: [{
                    key: identifier('key', 1),
                    sep: token(4, 4),
                    value: identifier('value', 6)
                }],
                doc: doc('some note', 13),
                comment: comment('a comment', 25),
            }})
        })
        test('entityRefRule', () => {
            expect(parseRule(p => p.entityRefRule(), 'users')).toEqual({result: {entity: identifier('users', 0)}})
            expect(parseRule(p => p.entityRefRule(), 'public.users')).toEqual({result: {
                entity: identifier('users', 7),
                schema: identifier('public', 0),
            }})
            expect(parseRule(p => p.entityRefRule(), 'core.public.users')).toEqual({result: {
                entity: identifier('users', 12),
                schema: identifier('public', 5),
                catalog: identifier('core', 0),
            }})
            expect(parseRule(p => p.entityRefRule(), 'analytics.core.public.users')).toEqual({result: {
                entity: identifier('users', 22),
                schema: identifier('public', 15),
                catalog: identifier('core', 10),
                database: identifier('analytics', 0),
            }})
            expect(parseRule(p => p.entityRefRule(), '42')).toEqual({errors: [{message: "Expecting token of type --> Identifier <-- but found --> '42' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 1)}]})
        })
        test('columnPathRule', () => {
            expect(parseRule(p => p.attributePathRule(), 'details')).toEqual({result: identifier('details', 0)})
            expect(parseRule(p => p.attributePathRule(), 'details.address.street')).toEqual({result: {
                ...identifier('details', 0),
                path: [identifier('address', 8), identifier('street', 16)],
            }})
            expect(parseRule(p => p.attributePathRule(), '42')).toEqual({errors: [{message: "Expecting token of type --> Identifier <-- but found --> '42' <--", kind: 'MismatchedTokenException', level: 'error', ...token(0, 1)}]})
        })
        test('columnRefRule', () => {
            expect(parseRule(p => p.attributeRefRule(), 'users(id)')).toEqual({result: {
                entity: identifier('users', 0),
                attr: identifier('id', 6),
            }})
            expect(parseRule(p => p.attributeRefRule(), 'public.events(details.item_id)')).toEqual({result: {
                schema: identifier('public', 0),
                entity: identifier('events', 7),
                attr: {...identifier('details', 14), path: [identifier('item_id', 22)]},
            }})
        })
        test('columnRefCompositeRule', () => {
            expect(parseRule(p => p.attributeRefCompositeRule(), 'user_roles(user_id, role_id)')).toEqual({result: {
                entity: identifier('user_roles', 0),
                attrs: [
                    identifier('user_id', 11),
                    identifier('role_id', 20),
                ],
            }})
        })
        test('columnValueRule', () => {
            expect(parseRule(p => p.attributeValueRule(), '42')).toEqual({result: integer(42, 0)})
            expect(parseRule(p => p.attributeValueRule(), '2.0')).toEqual({result: decimal(2, 0, 2)})
            expect(parseRule(p => p.attributeValueRule(), '3.14')).toEqual({result: decimal(3.14, 0)})
            expect(parseRule(p => p.attributeValueRule(), 'User')).toEqual({result: identifier('User', 0)})
            expect(parseRule(p => p.attributeValueRule(), '"a user"')).toEqual({result: {...identifier('a user', 0, 7), quoted: true}})
        })
    })
    describe('utils', () => {
        test('nestAttributes', () => {
            expect(nestAttributes([])).toEqual([])
            expect(nestAttributes([{
                nesting: {depth: 0, token: token(0, 1)},
                name: identifier('id', 8, 9, 2, 2, 3, 4),
                type: identifier('int', 11, 13, 2, 2, 6, 8),
                constraints: [{kind: 'PrimaryKey', token: token(15, 16, 2, 2, 10, 11)}]
            }, {
                nesting: {depth: 0, token: token(0, 1)},
                name: identifier('name', 20, 23, 3, 3, 3, 6),
                type: identifier('varchar', 25, 31, 3, 3, 8, 14)
            }, {
                nesting: {depth: 0, token: token(0, 1)},
                name: identifier('settings', 35, 42, 4, 4, 3, 10),
                type: identifier('json', 44, 47, 4, 4, 12, 15)
            }, {
                nesting: {depth: 1, token: token(0, 1)},
                name: identifier('address', 53, 59, 5, 5, 5, 11),
                type: identifier('json', 61, 64, 5, 5, 13, 16)
            }, {
                nesting: {depth: 2, token: token(0, 1)},
                name: identifier('street', 72, 77, 6, 6, 7, 12),
                type: identifier('string', 79, 84, 6, 6, 14, 19)
            }, {
                nesting: {depth: 2, token: token(0, 1)},
                name: identifier('city', 92, 95, 7, 7, 7, 10),
                type: identifier('string', 97, 102, 7, 7, 12, 17)
            }, {
                nesting: {depth: 1, token: token(0, 1)},
                name: identifier('github', 108, 113, 8, 8, 5, 10),
                type: identifier('string', 115, 120, 8, 8, 12, 17)
            }])).toEqual([{
                path: [identifier('id', 8, 9, 2, 2, 3, 4)],
                type: identifier('int', 11, 13, 2, 2, 6, 8),
                constraints: [{kind: 'PrimaryKey', token: token(15, 16, 2, 2, 10, 11)}],
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

function doc(value: string, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): DocAst {
    return {kind: 'Doc', token: token(start, end || start + value.length + 2, lineStart, lineEnd, columnStart, columnEnd), value}
}

function comment(value: string, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): CommentAst {
    return {kind: 'Comment', token: token(start, end || start + value.length + 1, lineStart, lineEnd, columnStart, columnEnd), value}
}

function expression(value: string, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number, issues?: TokenIssue[]): ExpressionAst {
    const t = token(start, end || start + value.length + 1, lineStart, lineEnd, columnStart, columnEnd)
    return {kind: 'Expression', token: issues ? {...t, issues} : t, value}
}

function identifier(value: string, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): IdentifierAst {
    return {kind: 'Identifier', token: token(start, end || start + value.length - 1, lineStart, lineEnd, columnStart, columnEnd), value}
}

function integer(value: number, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): IntegerAst {
    return {kind: 'Integer', token: token(start, end || start + value.toString().length - 1, lineStart, lineEnd, columnStart, columnEnd), value}
}

function decimal(value: number, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): DecimalAst {
    return {kind: 'Decimal', token: token(start, end || start + value.toString().length - 1, lineStart, lineEnd, columnStart, columnEnd), value}
}

function boolean(value: boolean, start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): BooleanAst {
    return {kind: 'Boolean', token: token(start, end || start + value.toString().length - 1, lineStart, lineEnd, columnStart, columnEnd), value}
}

function null_(start: number, end?: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): NullAst {
    return {kind: 'Null', token: token(start, end || start + 3, lineStart, lineEnd, columnStart, columnEnd)}
}

function token(start: number, end: number, lineStart?: number, lineEnd?: number, columnStart?: number, columnEnd?: number): TokenPosition {
    return {offset: {start: start, end: end}, position: {start: {line: lineStart || 1, column: columnStart || start + 1}, end: {line: lineEnd || 1, column: columnEnd || end + 1}}}
}
