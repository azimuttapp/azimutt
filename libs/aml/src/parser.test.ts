import {describe, expect, test} from "@jest/globals";
import {removeFieldsDeep} from "@azimutt/utils";
import {tokenPosition} from "@azimutt/models";
import {AttributeRelationAst} from "./ast";
import {nestAttributes, parseAmlAst, parseRule} from "./parser";
import {legacy} from "./errors";

describe('aml parser', () => {
    test('empty', () => {
        expect(parseAmlAst('')).toEqual({result: []})
    })
    test('simple entity', () => {
        const input = `
users
  id uuid pk
  name varchar
`
        const ast = [{statement: 'Empty'}, {
            statement: 'Entity',
            name: {token: 'Identifier', value: 'users', ...tokenPosition(1, 5, 2, 1, 2, 5)},
            attrs: [{
                path: [{token: 'Identifier', value: 'id', ...tokenPosition(9, 10, 3, 3, 3, 4)}],
                type: {token: 'Identifier', value: 'uuid', ...tokenPosition(12, 15, 3, 6, 3, 9)},
                primaryKey: {keyword: tokenPosition(17, 18, 3, 11, 3, 12)},
            }, {
                path: [{token: 'Identifier', value: 'name', ...tokenPosition(22, 25, 4, 3, 4, 6)}],
                type: {token: 'Identifier', value: 'varchar', ...tokenPosition(27, 33, 4, 8, 4, 14)},
            }]
        }]
        expect(parseAmlAst(input)).toEqual({result: ast})
    })
    test('multiple entities', () => {
        const input = `
users
posts
comments
`
        const ast = [
            {statement: 'Empty'},
            {statement: 'Entity', name: {token: 'Identifier', value: 'users', ...tokenPosition(1, 5, 2, 1, 2, 5)}},
            {statement: 'Entity', name: {token: 'Identifier', value: 'posts', ...tokenPosition(7, 11, 3, 1, 3, 5)}},
            {statement: 'Entity', name: {token: 'Identifier', value: 'comments', ...tokenPosition(13, 20, 4, 1, 4, 8)}},
        ]
        expect(parseAmlAst(input)).toEqual({result: ast})
    })
    describe('namespaceRule', () => {
        test('schema', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace public\n')).toEqual({result: {
                statement: 'Namespace',
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(10, 15, 1, 11, 1, 16)},
            }})
        })
        test('catalog', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace core.public\n')).toEqual({result: {
                statement: 'Namespace',
                catalog: {token: 'Identifier', value: 'core', ...tokenPosition(10, 13, 1, 11, 1, 14)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(15, 20, 1, 16, 1, 21)},
            }})
        })
        test('database', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace analytics.core.public\n')).toEqual({result: {
                statement: 'Namespace',
                database: {token: 'Identifier', value: 'analytics', ...tokenPosition(10, 18, 1, 11, 1, 19)},
                catalog: {token: 'Identifier', value: 'core', ...tokenPosition(20, 23, 1, 21, 1, 24)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(25, 30, 1, 26, 1, 31)},
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace public | a note # and a comment\n')).toEqual({result: {
                statement: 'Namespace',
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(10, 15, 1, 11, 1, 16)},
                doc: {token: 'Doc', value: 'a note', ...tokenPosition(17, 25, 1, 18, 1, 26)},
                comment: {token: 'Comment', value: 'and a comment', ...tokenPosition(26, 40, 1, 27, 1, 41)},
            }})
        })
    })
    describe('entityRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.entityRule(), 'users\n')).toEqual({result: {statement: 'Entity', name: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)}}})
        })
        test('namespace', () => {
            expect(parseRule(p => p.entityRule(), 'public.users\n')).toEqual({result: {
                statement: 'Entity',
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(0, 5, 1, 1, 1, 6)},
                name: {token: 'Identifier', value: 'users', ...tokenPosition(7, 11, 1, 8, 1, 12)},
            }})
            expect(parseRule(p => p.entityRule(), 'core.public.users\n')).toEqual({result: {
                statement: 'Entity',
                catalog: {token: 'Identifier', value: 'core', ...tokenPosition(0, 3, 1, 1, 1, 4)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(5, 10, 1, 6, 1, 11)},
                name: {token: 'Identifier', value: 'users', ...tokenPosition(12, 16, 1, 13, 1, 17)},
            }})
            expect(parseRule(p => p.entityRule(), 'ax.core.public.users\n')).toEqual({result: {
                statement: 'Entity',
                database: {token: 'Identifier', value: 'ax', ...tokenPosition(0, 1, 1, 1, 1, 2)},
                catalog: {token: 'Identifier', value: 'core', ...tokenPosition(3, 6, 1, 4, 1, 7)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(8, 13, 1, 9, 1, 14)},
                name: {token: 'Identifier', value: 'users', ...tokenPosition(15, 19, 1, 16, 1, 20)},
            }})
        })
        test('view', () => {
            expect(parseRule(p => p.entityRule(), 'users*\n')).toEqual({result: {
                statement: 'Entity',
                name: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                view: tokenPosition(5, 5, 1, 6, 1, 6)
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.entityRule(), 'users as u\n')).toEqual({result: {
                statement: 'Entity',
                name: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                alias: {token: 'Identifier', value: 'u', ...tokenPosition(9, 9, 1, 10, 1, 10)},
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.entityRule(), 'users {domain: auth} | list users # sample comment\n')).toEqual({result: {
                statement: 'Entity',
                name: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                properties: [{
                    key: {token: 'Identifier', value: 'domain', ...tokenPosition(7, 12, 1, 8, 1, 13)},
                    sep: tokenPosition(13, 13, 1, 14, 1, 14),
                    value: {token: 'Identifier', value: 'auth', ...tokenPosition(15, 18, 1, 16, 1, 19)},
                }],
                doc: {token: 'Doc', value: 'list users', ...tokenPosition(21, 33, 1, 22, 1, 34)},
                comment: {token: 'Comment', value: 'sample comment', ...tokenPosition(34, 49, 1, 35, 1, 50)},
            }})
        })
        test('attributes', () => {
            expect(parseRule(p => p.entityRule(), 'users\n  id uuid pk\n  name varchar\n')).toEqual({result: {
                statement: 'Entity',
                name: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                attrs: [{
                    path: [{token: 'Identifier', value: 'id', ...tokenPosition(8, 9, 2, 3, 2, 4)}],
                    type: {token: 'Identifier', value: 'uuid', ...tokenPosition(11, 14, 2, 6, 2, 9)},
                    primaryKey: {keyword: tokenPosition(16, 17, 2, 11, 2, 12)},
                }, {
                    path: [{token: 'Identifier', value: 'name', ...tokenPosition(21, 24, 3, 3, 3, 6)}],
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(26, 32, 3, 8, 3, 14)},
                }],
            }})
        })
        describe('attributeRule', () => {
            test('name', () => {
                expect(parseRule(p => p.attributeRule(), '  id\n')).toEqual({result: {nesting: 0, name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)}}})
            })
            test('type', () => {
                expect(parseRule(p => p.attributeRule(), '  id uuid\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    type: {token: 'Identifier', value: 'uuid', ...tokenPosition(5, 8, 1, 6, 1, 9)},
                }})
                expect(parseRule(p => p.attributeRule(), '  name "varchar(12)"\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'name', ...tokenPosition(2, 5, 1, 3, 1, 6)},
                    type: {token: 'Identifier', value: 'varchar(12)', ...tokenPosition(7, 19, 1, 8, 1, 20)},
                }})
                expect(parseRule(p => p.attributeRule(), '  bio "character varying"\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'bio', ...tokenPosition(2, 4, 1, 3, 1, 5)},
                    type: {token: 'Identifier', value: 'character varying', ...tokenPosition(6, 24, 1, 7, 1, 25)},
                }})
            })
            test('enum', () => {
                expect(parseRule(p => p.attributeRule(), '  status post_status(draft, published, archived)\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'status', ...tokenPosition(2, 7, 1, 3, 1, 8)},
                    type: {token: 'Identifier', value: 'post_status', ...tokenPosition(9, 19, 1, 10, 1, 20)},
                    enumValues: [
                        {token: 'Identifier', value: 'draft', ...tokenPosition(21, 25, 1, 22, 1, 26)},
                        {token: 'Identifier', value: 'published', ...tokenPosition(28, 36, 1, 29, 1, 37)},
                        {token: 'Identifier', value: 'archived', ...tokenPosition(39, 46, 1, 40, 1, 47)},
                    ],
                }})
            })
            test('default', () => {
                expect(parseRule(p => p.attributeRule(), '  id int=0\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    type: {token: 'Identifier', value: 'int', ...tokenPosition(5, 7, 1, 6, 1, 8)},
                    defaultValue: {token: 'Integer', value: 0, ...tokenPosition(9, 9, 1, 10, 1, 10)},
                }})
                expect(parseRule(p => p.attributeRule(), '  price decimal=41.9\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'price', ...tokenPosition(2, 6, 1, 3, 1, 7)},
                    type: {token: 'Identifier', value: 'decimal', ...tokenPosition(8, 14, 1, 9, 1, 15)},
                    defaultValue: {token: 'Decimal', value: 41.9, ...tokenPosition(16, 19, 1, 17, 1, 20)},
                }})
                expect(parseRule(p => p.attributeRule(), '  role varchar=guest\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'role', ...tokenPosition(2, 5, 1, 3, 1, 6)},
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(7, 13, 1, 8, 1, 14)},
                    defaultValue: {token: 'Identifier', value: 'guest', ...tokenPosition(15, 19, 1, 16, 1, 20)},
                }})
                expect(parseRule(p => p.attributeRule(), '  is_admin boolean=false\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'is_admin', ...tokenPosition(2, 9, 1, 3, 1, 10)},
                    type: {token: 'Identifier', value: 'boolean', ...tokenPosition(11, 17, 1, 12, 1, 18)},
                    defaultValue: {token: 'Boolean', value: false, ...tokenPosition(19, 23, 1, 20, 1, 24)},
                }})
                expect(parseRule(p => p.attributeRule(), '  created_at timestamp=`now()`\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'created_at', ...tokenPosition(2, 11, 1, 3, 1, 12)},
                    type: {token: 'Identifier', value: 'timestamp', ...tokenPosition(13, 21, 1, 14, 1, 22)},
                    defaultValue: {token: 'Expression', value: 'now()', ...tokenPosition(23, 29, 1, 24, 1, 30)},
                }})
                expect(parseRule(p => p.attributeRule(), '  source varchar=null\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'source', ...tokenPosition(2, 7, 1, 3, 1, 8)},
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(9, 15, 1, 10, 1, 16)},
                    defaultValue: {token: 'Null', ...tokenPosition(17, 20, 1, 18, 1, 21)},
                }})
                // TODO: handle `[]` default value? Ex: '  tags varchar[]=[]\n' instead of '  tags varchar[]="[]"\n'
                // TODO: handle `{}` default value? Ex: '  details json={}\n' instead of '  details json="{}"\n'
            })
            test('nullable', () => {
                expect(parseRule(p => p.attributeRule(), '  id nullable\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    nullable: tokenPosition(5, 12, 1, 6, 1, 13),
                }})
                expect(parseRule(p => p.attributeRule(), '  id int nullable\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    type: {token: 'Identifier', value: 'int', ...tokenPosition(5, 7, 1, 6, 1, 8)},
                    nullable: tokenPosition(9, 16, 1, 10, 1, 17),
                }})
            })
            test('pk', () => {
                expect(parseRule(p => p.attributeRule(), '  id pk\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    primaryKey: {keyword: tokenPosition(5, 6, 1, 6, 1, 7)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id int pk\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    type: {token: 'Identifier', value: 'int', ...tokenPosition(5, 7, 1, 6, 1, 8)},
                    primaryKey: {keyword: tokenPosition(9, 10, 1, 10, 1, 11)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id int pk=pk_name\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    type: {token: 'Identifier', value: 'int', ...tokenPosition(5, 7, 1, 6, 1, 8)},
                    primaryKey: {keyword: tokenPosition(9, 10, 1, 10, 1, 11), name: {token: 'Identifier', value: 'pk_name', ...tokenPosition(12, 18, 1, 13, 1, 19)}},
                }})
            })
            test('index', () => {
                expect(parseRule(p => p.attributeRule(), '  id index\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    index: {keyword: tokenPosition(5, 9, 1, 6, 1, 10)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id index=id_idx\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    index: {keyword: tokenPosition(5, 9, 1, 6, 1, 10), name: {token: 'Identifier', value: 'id_idx', ...tokenPosition(11, 16, 1, 12, 1, 17)}},
                }})
                expect(parseRule(p => p.attributeRule(), '  id index = "idx \\" id"\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    index: {keyword: tokenPosition(5, 9, 1, 6, 1, 10), name: {token: 'Identifier', value: 'idx " id', ...tokenPosition(13, 23, 1, 14, 1, 24)}},
                }})
            })
            test('unique', () => {
                expect(parseRule(p => p.attributeRule(), '  id unique\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    unique: {keyword: tokenPosition(5, 10, 1, 6, 1, 11)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id unique=id_uniq\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    unique: {keyword: tokenPosition(5, 10, 1, 6, 1, 11), name: {token: 'Identifier', value: 'id_uniq', ...tokenPosition(12, 18, 1, 13, 1, 19)}},
                }})
            })
            test('check', () => {
                expect(parseRule(p => p.attributeRule(), '  id check\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    check: {keyword: tokenPosition(5, 9, 1, 6, 1, 10)},
                }})
                expect(parseRule(p => p.attributeRule(), '  id check=`id > 0`\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    check: {keyword: tokenPosition(5, 9, 1, 6, 1, 10), definition: {token: 'Expression', value: 'id > 0', ...tokenPosition(11, 18, 1, 12, 1, 19)}},
                }})
            })
            test('relation', () => {
                expect(parseRule(p => p.attributeRule(), '  user_id -> users(id)\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'user_id', ...tokenPosition(2, 8, 1, 3, 1, 9)},
                    relation: {kind: 'n-1', ref: {
                        entity: {token: 'Identifier', value: 'users', ...tokenPosition(13, 17, 1, 14, 1, 18)},
                        attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(19, 20, 1, 20, 1, 21)}],
                    }}
                }})
            })
            test('properties', () => {
                expect(parseRule(p => p.attributeRule(), '  id {tag: pii}\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    properties: [{key: {token: 'Identifier', value: 'tag', ...tokenPosition(6, 8, 1, 7, 1, 9)}, sep: tokenPosition(9, 9, 1, 10, 1, 10), value: {token: 'Identifier', value: 'pii', ...tokenPosition(11, 13, 1, 12, 1, 14)}}],
                }})
            })
            test('note', () => {
                expect(parseRule(p => p.attributeRule(), '  id | some note\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    doc: {token: 'Doc', value: 'some note', ...tokenPosition(5, 15, 1, 6, 1, 16)},
                }})
            })
            test('comment', () => {
                expect(parseRule(p => p.attributeRule(), '  id # a comment\n')).toEqual({result: {
                    nesting: 0,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(2, 3, 1, 3, 1, 4)},
                    comment: {token: 'Comment', value: 'a comment', ...tokenPosition(5, 15, 1, 6, 1, 16)},
                }})
            })
            test('all', () => {
                expect(parseRule(p => p.attributeRule(), '    id int(8, 9, 10)=8 nullable pk index=idx unique check=`id > 0` -kind=users> public.users(id) { tag : pii , owner:PANDA} | some note # comment\n')).toEqual({result: {
                    nesting: 1,
                    name: {token: 'Identifier', value: 'id', ...tokenPosition(4, 5, 1, 5, 1, 6)},
                    type: {token: 'Identifier', value: 'int', ...tokenPosition(7, 9, 1, 8, 1, 10)},
                    enumValues: [{value: 8, token: 'Integer', ...tokenPosition(11, 11, 1, 12, 1, 12)}, {value: 9, token: 'Integer', ...tokenPosition(14, 14, 1, 15, 1, 15)}, {value: 10, token: 'Integer', ...tokenPosition(17, 18, 1, 18, 1, 19)}],
                    defaultValue: {token: 'Integer', value: 8, ...tokenPosition(21, 21, 1, 22, 1, 22)},
                    nullable: tokenPosition(23, 30, 1, 24, 1, 31),
                    primaryKey: {keyword: tokenPosition(32, 33, 1, 33, 1, 34)},
                    index: {keyword: tokenPosition(35, 39, 1, 36, 1, 40), name: {token: 'Identifier', value: 'idx', ...tokenPosition(41, 43, 1, 42, 1, 44)}},
                    unique: {keyword: tokenPosition(45, 50, 1, 46, 1, 51)},
                    check: {keyword: tokenPosition(52, 56, 1, 53, 1, 57), definition: {token: 'Expression', value: 'id > 0', ...tokenPosition(58, 65, 1, 59, 1, 66)}},
                    relation: {kind: 'n-1',
                        ref: {schema: {token: 'Identifier', value: 'public', ...tokenPosition(80, 85, 1, 81, 1, 86)}, entity: {token: 'Identifier', value: 'users', ...tokenPosition(87, 91, 1, 88, 1, 92)}, attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(93, 94, 1, 94, 1, 95)}]},
                        polymorphic: {attr: {token: 'Identifier', value: 'kind', ...tokenPosition(68, 71, 1, 69, 1, 72)}, value: {token: 'Identifier', value: 'users', ...tokenPosition(73, 77, 1, 74, 1, 78)}}
                    },
                    properties: [
                        {key: {token: 'Identifier', value: 'tag', ...tokenPosition(99, 101, 1, 100, 1, 102)}, sep: tokenPosition(103, 103, 1, 104, 1, 104), value: {token: 'Identifier', value: 'pii', ...tokenPosition(105, 107, 1, 106, 1, 108)}},
                        {key: {token: 'Identifier', value: 'owner', ...tokenPosition(111, 115, 1, 112, 1, 116)}, sep: tokenPosition(116, 116, 1, 117, 1, 117), value: {token: 'Identifier', value: 'PANDA', ...tokenPosition(117, 121, 1, 118, 1, 122)}},
                    ],
                    doc: {token: 'Doc', value: 'some note', ...tokenPosition(124, 135, 1, 125, 1, 136)},
                    comment: {token: 'Comment', value: 'comment', ...tokenPosition(136, 144, 1, 137, 1, 145)},
                }})
            })
            test('error', () => {
                expect(parseRule(p => p.attributeRule(), '  12\n')).toEqual({result: {nesting: 0}, errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '12' <--", ...tokenPosition(2, 3, 1, 3, 1, 4)}]})
            })
        })
    })
    describe('relationRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id)\n')).toEqual({result: {
                statement: 'Relation',
                kind: 'n-1',
                src: {
                    entity: {token: 'Identifier', value: 'groups', ...tokenPosition(4, 9, 1, 5, 1, 10)},
                    attrs: [{token: 'Identifier', value: 'owner', ...tokenPosition(11, 15, 1, 12, 1, 16)}],
                },
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(21, 25, 1, 22, 1, 26)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(27, 28, 1, 28, 1, 29)}],
                },
            }})
        })
        test('one-to-one', () => {
            expect(parseRule(p => p.relationRule(), 'rel profiles(id) -- users(id)\n')).toEqual({result: {
                statement: 'Relation',
                kind: '1-1',
                src: {
                    entity: {token: 'Identifier', value: 'profiles', ...tokenPosition(4, 11, 1, 5, 1, 12)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(13, 14, 1, 14, 1, 15)}],
                },
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(20, 24, 1, 21, 1, 25)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(26, 27, 1, 27, 1, 28)}],
                },
            }})
        })
        test('many-to-many', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(id) <> users(id)\n')).toEqual({result: {
                statement: 'Relation',
                kind: 'n-n',
                src: {
                    entity: {token: 'Identifier', value: 'groups', ...tokenPosition(4, 9, 1, 5, 1, 10)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(11, 12, 1, 12, 1, 13)}],
                },
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(18, 22, 1, 19, 1, 23)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(24, 25, 1, 25, 1, 26)}],
                },
            }})
        })
        test('composite', () => {
            expect(parseRule(p => p.relationRule(), 'rel audit(user_id, role_id) -> user_roles(user_id, role_id)\n')).toEqual({result: {
                statement: 'Relation',
                kind: 'n-1',
                src: {
                    entity: {token: 'Identifier', value: 'audit', ...tokenPosition(4, 8, 1, 5, 1, 9)},
                    attrs: [
                        {token: 'Identifier', value: 'user_id', ...tokenPosition(10, 16, 1, 11, 1, 17)},
                        {token: 'Identifier', value: 'role_id', ...tokenPosition(19, 25, 1, 20, 1, 26)},
                    ],
                },
                ref: {
                    entity: {token: 'Identifier', value: 'user_roles', ...tokenPosition(31, 40, 1, 32, 1, 41)},
                    attrs: [
                        {token: 'Identifier', value: 'user_id', ...tokenPosition(42, 48, 1, 43, 1, 49)},
                        {token: 'Identifier', value: 'role_id', ...tokenPosition(51, 57, 1, 52, 1, 58)},
                    ],
                },
            }})
        })
        test('polymorphic', () => {
            expect(parseRule(p => p.relationRule(), 'rel events(item_id) -item_kind=User> users(id)\n')).toEqual({result: {
                statement: 'Relation',
                kind: 'n-1',
                src: {
                    entity: {token: 'Identifier', value: 'events', ...tokenPosition(4, 9, 1, 5, 1, 10)},
                    attrs: [{token: 'Identifier', value: 'item_id', ...tokenPosition(11, 17, 1, 12, 1, 18)}],
                },
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(37, 41, 1, 38, 1, 42)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(43, 44, 1, 44, 1, 45)}],
                },
                polymorphic: {
                    attr: {token: 'Identifier', value: 'item_kind', ...tokenPosition(21, 29, 1, 22, 1, 30)},
                    value: {token: 'Identifier', value: 'User', ...tokenPosition(31, 34, 1, 32, 1, 35)},
                }
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id) {color: red} | a note # a comment\n')).toEqual({result: {
                statement: 'Relation',
                kind: 'n-1',
                src: {
                    entity: {token: 'Identifier', value: 'groups', ...tokenPosition(4, 9, 1, 5, 1, 10)},
                    attrs: [{token: 'Identifier', value: 'owner', ...tokenPosition(11, 15, 1, 12, 1, 16)}],
                },
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(21, 25, 1, 22, 1, 26)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(27, 28, 1, 28, 1, 29)}],
                },
                properties: [{
                    key: {token: 'Identifier', value: 'color', ...tokenPosition(32, 36, 1, 33, 1, 37)},
                    sep: tokenPosition(37, 37, 1, 38, 1, 38),
                    value: {token: 'Identifier', value: 'red', ...tokenPosition(39, 41, 1, 40, 1, 42)}
                }],
                doc: {token: 'Doc', value: 'a note', ...tokenPosition(44, 52, 1, 45, 1, 53)},
                comment: {token: 'Comment', value: 'a comment', ...tokenPosition(53, 63, 1, 54, 1, 64)},
            }})
        })
        test('bad', () => {
            expect(parseRule(p => p.relationRule(), 'bad')).toEqual({errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Relation]\n  2. [ForeignKey]\nbut found: 'bad'", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
    })
    describe('typeRule', () => {
        test('empty', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status varchar\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
                content: {kind: 'alias', name: {token: 'Identifier', value: 'varchar', ...tokenPosition(16, 22, 1, 17, 1, 23)}},
            }})
        })
        test('enum', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status (new, "in progress", done)\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
                content: {kind: 'enum', values: [
                    {token: 'Identifier', value: 'new', ...tokenPosition(17, 19, 1, 18, 1, 20)},
                    {token: 'Identifier', value: 'in progress', ...tokenPosition(22, 34, 1, 23, 1, 35)},
                    {token: 'Identifier', value: 'done', ...tokenPosition(37, 40, 1, 38, 1, 41)},
                ]}
            }})
        })
        test('struct', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status {internal varchar, public varchar}\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
                content: {kind: 'struct', attrs: [{
                    path: [{token: 'Identifier', value: 'internal', ...tokenPosition(17, 24, 1, 18, 1, 25)}],
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(26, 32, 1, 27, 1, 33)},
                }, {
                    path: [{token: 'Identifier', value: 'public', ...tokenPosition(35, 40, 1, 36, 1, 41)}],
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(42, 48, 1, 43, 1, 49)},
                }]}
            }})
            // FIXME: would be nice to have this alternative but the $.MANY fails, see `typeRule`
            /*expect(parseRule(p => p.typeRule(), 'type bug_status\n  internal varchar\n  public varchar\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
                content: {kind: 'struct', attrs: [{
                    path: [{token: 'Identifier', value: 'internal', ...tokenPosition(18, 25, 2, 3, 2, 10)}],
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(27, 33, 2, 12, 2, 18)},
                }, {
                    path: [{token: 'Identifier', value: 'public', ...tokenPosition(37, 42, 3, 3, 3, 8)}],
                    type: {token: 'Identifier', value: 'varchar', ...tokenPosition(44, 50, 3, 10, 3, 16)},
                }]}
            }})*/
        })
        test('custom', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status `range(subtype = float8, subtype_diff = float8mi)`\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
                content: {kind: 'custom', definition: {token: 'Expression', value: 'range(subtype = float8, subtype_diff = float8mi)', ...tokenPosition(16, 65, 1, 17, 1, 66)}}
            }})
        })
        test('namespace', () => {
            expect(parseRule(p => p.typeRule(), 'type reporting.public.bug_status varchar\n')).toEqual({result: {
                statement: 'Type',
                catalog: {token: 'Identifier', value: 'reporting', ...tokenPosition(5, 13, 1, 6, 1, 14)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(15, 20, 1, 16, 1, 21)},
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(22, 31, 1, 23, 1, 32)},
                content: {kind: 'alias', name: {token: 'Identifier', value: 'varchar', ...tokenPosition(33, 39, 1, 34, 1, 40)}},
            }})
        })
        test('metadata', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status varchar {tags: seo} | a note # a comment\n')).toEqual({result: {
                statement: 'Type',
                name: {token: 'Identifier', value: 'bug_status', ...tokenPosition(5, 14, 1, 6, 1, 15)},
                content: {kind: 'alias', name: {token: 'Identifier', value: 'varchar', ...tokenPosition(16, 22, 1, 17, 1, 23)}},
                properties: [{
                    key: {token: 'Identifier', value: 'tags', ...tokenPosition(25, 28, 1, 26, 1, 29)},
                    sep: tokenPosition(29, 29, 1, 30, 1, 30),
                    value: {token: 'Identifier', value: 'seo', ...tokenPosition(31, 33, 1, 32, 1, 34)}
                }],
                doc: {token: 'Doc', value: 'a note', ...tokenPosition(36, 44, 1, 37, 1, 45)},
                comment: {token: 'Comment', value: 'a comment', ...tokenPosition(45, 55, 1, 46, 1, 56)},
            }})
        })
        // TODO: test bad
    })
    describe('emptyStatementRule', () => {
        test('basic', () => expect(parseRule(p => p.emptyStatementRule(), '\n')).toEqual({result: {statement: 'Empty'}}))
        test('with spaces', () => expect(parseRule(p => p.emptyStatementRule(), '  \n')).toEqual({result: {statement: 'Empty'}}))
        test('with comment', () => expect(parseRule(p => p.emptyStatementRule(), ' # hello\n')).toEqual({result: {statement: 'Empty', comment: {token: 'Comment', value: 'hello', ...tokenPosition(1, 7, 1, 2, 1, 8)}}}))
    })
    describe('legacy', () => {
        test('attribute type', () => {
            // as `varchar(12)` is valid on both v1 & v2 but has different meaning, it's handled when building AML, see aml-legacy.test.ts
            expect(parseRule(p => p.attributeRule(), '  name varchar(12)\n').result).toEqual({
                nesting: 0,
                name: {token: 'Identifier', value: 'name', ...tokenPosition(2, 5, 1, 3, 1, 6)},
                type: {token: 'Identifier', value: 'varchar', ...tokenPosition(7, 13, 1, 8, 1, 14)},
                enumValues: [{token: 'Integer', value: 12, ...tokenPosition(15, 16, 1, 16, 1, 17)}]
            })
        })
        test('attribute relation', () => {
            const v1 = parseRule(p => p.attributeRule(), '  user_id fk users.id\n').result?.relation as AttributeRelationAst
            const v2 = parseRule(p => p.attributeRule(), '  user_id -> users(id)\n').result?.relation
            expect(v1).toEqual({
                kind: 'n-1',
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(13, 17, 1, 14, 1, 18)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(19, 20, 1, 20, 1, 21)}],
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
                statement: 'Relation',
                kind: 'n-1',
                src: {
                    entity: {token: 'Identifier', value: 'groups', ...tokenPosition(3, 8, 1, 4, 1, 9)},
                    attrs: [{token: 'Identifier', value: 'owner', ...tokenPosition(10, 14, 1, 11, 1, 15)}],
                    warning: {...tokenPosition(3, 14, 1, 4, 1, 15), issues: [legacy('"groups.owner" is the legacy way, use "groups(owner)" instead')]}
                },
                ref: {
                    entity: {token: 'Identifier', value: 'users', ...tokenPosition(19, 23, 1, 20, 1, 24)},
                    attrs: [{token: 'Identifier', value: 'id', ...tokenPosition(25, 26, 1, 26, 1, 27)}],
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
                entity: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                attr: {token: 'Identifier', value: 'settings', ...tokenPosition(6, 13, 1, 7, 1, 14), path: [{token: 'Identifier', value: 'github', ...tokenPosition(15, 20, 1, 16, 1, 21)}]},
                warning: {...tokenPosition(0, 20, 1, 1, 1, 21), issues: [legacy('"users.settings:github" is the legacy way, use "users(settings.github)" instead')]}
            }})
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
            expect(removeFieldsDeep(parseRule(p => p.attributeRefRule(), 'public.users.settings:github'), ['warning'])).toEqual(parseRule(p => p.attributeRefRule(), 'public.users(settings.github)'))
        })
        test('nested attribute composite', () => {
            const v1 = parseRule(p => p.attributeRefCompositeRule(), 'users.settings:github')
            const v2 = parseRule(p => p.attributeRefCompositeRule(), 'users(settings.github)')
            expect(v1).toEqual({result: {
                entity: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                attrs: [{token: 'Identifier', value: 'settings', ...tokenPosition(6, 13, 1, 7, 1, 14), path: [{token: 'Identifier', value: 'github', ...tokenPosition(15, 20, 1, 16, 1, 21)}]}],
                warning: {...tokenPosition(0, 20, 1, 1, 1, 21), issues: [legacy('"users.settings:github" is the legacy way, use "users(settings.github)" instead')]},
            }})
            expect(removeFieldsDeep(v1, ['warning'])).toEqual(v2)
            expect(removeFieldsDeep(parseRule(p => p.attributeRefCompositeRule(), 'public.users.settings:github'), ['warning'])).toEqual(parseRule(p => p.attributeRefCompositeRule(), 'public.users(settings.github)'))
        })
        test('properties', () => {
            expect(parseRule(p => p.propertiesRule(), '{color=red}')).toEqual({result: [{
                key: {token: 'Identifier', value: 'color', ...tokenPosition(1, 5, 1, 2, 1, 6)},
                sep: {...tokenPosition(6, 6, 1, 7, 1, 7), issues: [legacy('"=" is legacy, replace it with ":"')]},
                value: {token: 'Identifier', value: 'red', ...tokenPosition(7, 9, 1, 8, 1, 10)},
            }]})
        })
        test('check identifier', () => {
            const v1 = parseRule(p => p.attributeRule(), '  age int check="age > 0"\n').result
            const v2 = parseRule(p => p.attributeRule(), '  age int check=`age > 0`\n').result
            expect(v1).toEqual({
                nesting: 0,
                name: {value: 'age', token: 'Identifier', ...tokenPosition(2, 4, 1, 3, 1, 5)},
                type: {value: 'int', token: 'Identifier', ...tokenPosition(6, 8, 1, 7, 1, 9)},
                check: {
                    keyword: tokenPosition(10, 14, 1, 11, 1, 15),
                    definition: {value: 'age > 0', token: 'Expression', ...tokenPosition(16, 24, 1, 17, 1, 25), issues: [legacy('"age > 0" is the legacy way, use expression "`age > 0`" instead')]},
                },
            })
            expect(removeFieldsDeep(v1, ['issues'])).toEqual(v2)
        })
    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: {token: 'Integer', value: 12, ...tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.integerRule(), '1.2')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Integer <-- but found --> '1.2' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('decimalRule', () => {
            expect(parseRule(p => p.decimalRule(), '1.2')).toEqual({result: {token: 'Decimal', value: 1.2, ...tokenPosition(0, 2, 1, 1, 1, 3)}})
            expect(parseRule(p => p.decimalRule(), '12')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Decimal <-- but found --> '12' <--", ...tokenPosition(0, 1, 1, 1, 1, 2)}]})
            expect(parseRule(p => p.decimalRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Decimal <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: {token: 'Identifier', value: 'id', ...tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {token: 'Identifier', value: 'my col', ...tokenPosition(0, 7, 1, 1, 1, 8)}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {token: 'Identifier', value: 'my "new" col', ...tokenPosition(0, 15, 1, 1, 1, 16)}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({result: {token: 'Identifier', value: 'bad', ...tokenPosition(0, 2, 1, 1, 1, 3)}, errors: [{name: 'NotAllInputParsedException', kind: 'error', message: "Redundant input, expecting EOF but found:  ", ...tokenPosition(3, 3, 1, 4, 1, 4)}]})
        })
        test('commentRule', () => {
            expect(parseRule(p => p.commentRule(), '# a comment')).toEqual({result: {token: 'Comment', value: 'a comment', ...tokenPosition(0, 10, 1, 1, 1, 11)}})
            expect(parseRule(p => p.commentRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Comment <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('noteRule', () => {
            expect(parseRule(p => p.docRule(), '| a note')).toEqual({result: {token: 'Doc', value: 'a note', ...tokenPosition(0, 7, 1, 1, 1, 8)}})
            expect(parseRule(p => p.docRule(), '| "a # note"')).toEqual({result: {token: 'Doc', value: 'a # note', ...tokenPosition(0, 11, 1, 1, 1, 12)}})
            expect(parseRule(p => p.docRule(), '|||\n   a note\n   multiline\n|||')).toEqual({result: {token: 'Doc', value: 'a note\nmultiline', ...tokenPosition(0, 29, 1, 1, 4, 3)}})
            expect(parseRule(p => p.docRule(), 'bad')).toEqual({errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [DocMultiline]\n  2. [Doc]\nbut found: 'bad'", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('propertiesRule', () => {
            expect(parseRule(p => p.propertiesRule(), '{}')).toEqual({result: []})
            expect(parseRule(p => p.propertiesRule(), '{flag}')).toEqual({result: [{key: {token: 'Identifier', value: 'flag', ...tokenPosition(1, 4, 1, 2, 1, 5)}}]})
            expect(parseRule(p => p.propertiesRule(), '{color: red}')).toEqual({result: [{
                key: {token: 'Identifier', value: 'color', ...tokenPosition(1, 5, 1, 2, 1, 6)},
                sep: tokenPosition(6, 6, 1, 7, 1, 7),
                value: {token: 'Identifier', value: 'red', ...tokenPosition(8, 10, 1, 9, 1, 11)}
            }]})
            expect(parseRule(p => p.propertiesRule(), '{size: 12}')).toEqual({result: [{
                key: {token: 'Identifier', value: 'size', ...tokenPosition(1, 4, 1, 2, 1, 5)},
                sep: tokenPosition(5, 5, 1, 6, 1, 6),
                value: {token: 'Integer', value: 12, ...tokenPosition(7, 8, 1, 8, 1, 9)}
            }]})
            expect(parseRule(p => p.propertiesRule(), '{color:red, size : 12 , deprecated}')).toEqual({result: [{
                key: {token: 'Identifier', value: 'color', ...tokenPosition(1, 5, 1, 2, 1, 6)},
                sep: tokenPosition(6, 6, 1, 7, 1, 7),
                value: {token: 'Identifier', value: 'red', ...tokenPosition(7, 9, 1, 8, 1, 10)}
            }, {
                key: {token: 'Identifier', value: 'size', ...tokenPosition(12, 15, 1, 13, 1, 16)},
                sep: tokenPosition(17, 17, 1, 18, 1, 18),
                value: {token: 'Integer', value: 12, ...tokenPosition(19, 20, 1, 20, 1, 21)}
            }, {
                key: {token: 'Identifier', value: 'deprecated', ...tokenPosition(24, 33, 1, 25, 1, 34)}
            }]})

            // bad
            expect(parseRule(p => p.propertiesRule(), 'bad')).toEqual({errors: [
                {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> LCurly <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)},
                {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> RCurly <-- but found --> '' <--", ...tokenPosition(NaN, -1, -1, -1, -1, -1)},
            ]})
            expect(parseRule(p => p.propertiesRule(), '{')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> RCurly <-- but found --> '' <--", ...tokenPosition(NaN, -1, -1, -1, -1, -1)}]})
        })
        test('extraRule', () => {
            expect(parseRule(p => p.extraRule(), '')).toEqual({result: {}})
            expect(parseRule(p => p.extraRule(), '{key: value} | some note # a comment')).toEqual({result: {
                properties: [{
                    key: {token: 'Identifier', value: 'key', ...tokenPosition(1, 3, 1, 2, 1, 4)},
                    sep: tokenPosition(4, 4, 1, 5, 1, 5),
                    value: {token: 'Identifier', value: 'value', ...tokenPosition(6, 10, 1, 7, 1, 11)}
                }],
                doc: {token: 'Doc', value: 'some note', ...tokenPosition(13, 24, 1, 14, 1, 25)},
                comment: {token: 'Comment', value: 'a comment', ...tokenPosition(25, 35, 1, 26, 1, 36)},
            }})
        })
        test('entityRefRule', () => {
            expect(parseRule(p => p.entityRefRule(), 'users')).toEqual({result: {entity: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)}}})
            expect(parseRule(p => p.entityRefRule(), 'public.users')).toEqual({result: {
                entity: {token: 'Identifier', value: 'users', ...tokenPosition(7, 11, 1, 8, 1, 12)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(0, 5, 1, 1, 1, 6)},
            }})
            expect(parseRule(p => p.entityRefRule(), 'core.public.users')).toEqual({result: {
                entity: {token: 'Identifier', value: 'users', ...tokenPosition(12, 16, 1, 13, 1, 17)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(5, 10, 1, 6, 1, 11)},
                catalog: {token: 'Identifier', value: 'core', ...tokenPosition(0, 3, 1, 1, 1, 4)},
            }})
            expect(parseRule(p => p.entityRefRule(), 'analytics.core.public.users')).toEqual({result: {
                entity: {token: 'Identifier', value: 'users', ...tokenPosition(22, 26, 1, 23, 1, 27)},
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(15, 20, 1, 16, 1, 21)},
                catalog: {token: 'Identifier', value: 'core', ...tokenPosition(10, 13, 1, 11, 1, 14)},
                database: {token: 'Identifier', value: 'analytics', ...tokenPosition(0, 8, 1, 1, 1, 9)},
            }})
            expect(parseRule(p => p.entityRefRule(), '42')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '42' <--", ...tokenPosition(0, 1, 1, 1, 1, 2)}]})
        })
        test('columnPathRule', () => {
            expect(parseRule(p => p.attributePathRule(), 'details')).toEqual({result: {token: 'Identifier', value: 'details', ...tokenPosition(0, 6, 1, 1, 1, 7)}})
            expect(parseRule(p => p.attributePathRule(), 'details.address.street')).toEqual({result: {
                token: 'Identifier',
                value: 'details',
                ...tokenPosition(0, 6, 1, 1, 1, 7),
                path: [
                    {token: 'Identifier', value: 'address', ...tokenPosition(8, 14, 1, 9, 1, 15)},
                    {token: 'Identifier', value: 'street', ...tokenPosition(16, 21, 1, 17, 1, 22)}
                ],
            }})
            expect(parseRule(p => p.attributePathRule(), '42')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '42' <--", ...tokenPosition(0, 1, 1, 1, 1, 2)}]})
        })
        test('columnRefRule', () => {
            expect(parseRule(p => p.attributeRefRule(), 'users(id)')).toEqual({result: {
                entity: {token: 'Identifier', value: 'users', ...tokenPosition(0, 4, 1, 1, 1, 5)},
                attr: {token: 'Identifier', value: 'id', ...tokenPosition(6, 7, 1, 7, 1, 8)},
            }})
            expect(parseRule(p => p.attributeRefRule(), 'public.events(details.item_id)')).toEqual({result: {
                schema: {token: 'Identifier', value: 'public', ...tokenPosition(0, 5, 1, 1, 1, 6)},
                entity: {token: 'Identifier', value: 'events', ...tokenPosition(7, 12, 1, 8, 1, 13)},
                attr: {token: 'Identifier', value: 'details', ...tokenPosition(14, 20, 1, 15, 1, 21), path: [{token: 'Identifier', value: 'item_id', ...tokenPosition(22, 28, 1, 23, 1, 29)}]},
            }})
        })
        test('columnRefCompositeRule', () => {
            expect(parseRule(p => p.attributeRefCompositeRule(), 'user_roles(user_id, role_id)')).toEqual({result: {
                entity: {token: 'Identifier', value: 'user_roles', ...tokenPosition(0, 9, 1, 1, 1, 10)},
                attrs: [
                    {token: 'Identifier', value: 'user_id', ...tokenPosition(11, 17, 1, 12, 1, 18)},
                    {token: 'Identifier', value: 'role_id', ...tokenPosition(20, 26, 1, 21, 1, 27)},
                ],
            }})
        })
        test('columnValueRule', () => {
            expect(parseRule(p => p.attributeValueRule(), '42')).toEqual({result: {token: 'Integer', value: 42, ...tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.attributeValueRule(), '2.0')).toEqual({result: {token: 'Decimal', value: 2, ...tokenPosition(0, 2, 1, 1, 1, 3)}})
            expect(parseRule(p => p.attributeValueRule(), '3.14')).toEqual({result: {token: 'Decimal', value: 3.14, ...tokenPosition(0, 3, 1, 1, 1, 4)}})
            expect(parseRule(p => p.attributeValueRule(), 'User')).toEqual({result: {token: 'Identifier', value: 'User', ...tokenPosition(0, 3, 1, 1, 1, 4)}})
            expect(parseRule(p => p.attributeValueRule(), '"a user"')).toEqual({result: {token: 'Identifier', value: 'a user', ...tokenPosition(0, 7, 1, 1, 1, 8)}})
        })
    })
    describe('utils', () => {
        test('nestAttributes', () => {
            expect(nestAttributes([])).toEqual([])
            expect(nestAttributes([{
                nesting: 0,
                name: {token: 'Identifier', value: 'id', ...tokenPosition(8, 9, 2, 3, 2, 4)},
                type: {token: 'Identifier', value: 'int', ...tokenPosition(11, 13, 2, 6, 2, 8)},
                primaryKey: {keyword: tokenPosition(15, 16, 2, 10, 2, 11)}
            }, {
                nesting: 0,
                name: {token: 'Identifier', value: 'name', ...tokenPosition(20, 23, 3, 3, 3, 6)},
                type: {token: 'Identifier', value: 'varchar', ...tokenPosition(25, 31, 3, 8, 3, 14)}
            }, {
                nesting: 0,
                name: {token: 'Identifier', value: 'settings', ...tokenPosition(35, 42, 4, 3, 4, 10)},
                type: {token: 'Identifier', value: 'json', ...tokenPosition(44, 47, 4, 12, 4, 15)}
            }, {
                nesting: 1,
                name: {token: 'Identifier', value: 'address', ...tokenPosition(53, 59, 5, 5, 5, 11)},
                type: {token: 'Identifier', value: 'json', ...tokenPosition(61, 64, 5, 13, 5, 16)}
            }, {
                nesting: 2,
                name: {token: 'Identifier', value: 'street', ...tokenPosition(72, 77, 6, 7, 6, 12)},
                type: {token: 'Identifier', value: 'string', ...tokenPosition(79, 84, 6, 14, 6, 19)}
            }, {
                nesting: 2,
                name: {token: 'Identifier', value: 'city', ...tokenPosition(92, 95, 7, 7, 7, 10)},
                type: {token: 'Identifier', value: 'string', ...tokenPosition(97, 102, 7, 12, 7, 17)}
            }, {
                nesting: 1,
                name: {token: 'Identifier', value: 'github', ...tokenPosition(108, 113, 8, 5, 8, 10)},
                type: {token: 'Identifier', value: 'string', ...tokenPosition(115, 120, 8, 12, 8, 17)}
            }])).toEqual([{
                path: [{token: 'Identifier', value: 'id', ...tokenPosition(8, 9, 2, 3, 2, 4)}],
                type: {token: 'Identifier', value: 'int', ...tokenPosition(11, 13, 2, 6, 2, 8)},
                primaryKey: {keyword: tokenPosition(15, 16, 2, 10, 2, 11)},
            }, {
                path: [{token: 'Identifier', value: 'name', ...tokenPosition(20, 23, 3, 3, 3, 6)}],
                type: {token: 'Identifier', value: 'varchar', ...tokenPosition(25, 31, 3, 8, 3, 14)},
            }, {
                path: [{token: 'Identifier', value: 'settings', ...tokenPosition(35, 42, 4, 3, 4, 10)}],
                type: {token: 'Identifier', value: 'json', ...tokenPosition(44, 47, 4, 12, 4, 15)},
                attrs: [{
                    path: [{token: 'Identifier', value: 'settings', ...tokenPosition(35, 42, 4, 3, 4, 10)}, {token: 'Identifier', value: 'address', ...tokenPosition(53, 59, 5, 5, 5, 11)}],
                    type: {token: 'Identifier', value: 'json', ...tokenPosition(61, 64, 5, 13, 5, 16)},
                    attrs: [{
                        path: [{token: 'Identifier', value: 'settings', ...tokenPosition(35, 42, 4, 3, 4, 10)}, {token: 'Identifier', value: 'address', ...tokenPosition(53, 59, 5, 5, 5, 11)}, {token: 'Identifier', value: 'street', ...tokenPosition(72, 77, 6, 7, 6, 12)}],
                        type: {token: 'Identifier', value: 'string', ...tokenPosition(79, 84, 6, 14, 6, 19)},
                    }, {
                        path: [{token: 'Identifier', value: 'settings', ...tokenPosition(35, 42, 4, 3, 4, 10)}, {token: 'Identifier', value: 'address', ...tokenPosition(53, 59, 5, 5, 5, 11)}, {token: 'Identifier', value: 'city', ...tokenPosition(92, 95, 7, 7, 7, 10)}],
                        type: {token: 'Identifier', value: 'string', ...tokenPosition(97, 102, 7, 12, 7, 17)},
                    }]
                }, {
                    path: [{token: 'Identifier', value: 'settings', ...tokenPosition(35, 42, 4, 3, 4, 10)}, {token: 'Identifier', value: 'github', ...tokenPosition(108, 113, 8, 5, 8, 10)}],
                    type: {token: 'Identifier', value: 'string', ...tokenPosition(115, 120, 8, 12, 8, 17)},
                }]
            }])
        })
        test('tokenPosition has expected structure', () => {
            expect(tokenPosition(1, 2, 3, 4, 5, 6)).toEqual({offset: {start: 1, end: 2}, position: {start: {line: 3, column: 4}, end: {line: 5, column: 6}}})
        })
    })
})
