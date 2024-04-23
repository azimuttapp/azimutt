import {describe, expect, test} from "@jest/globals";
import {parseRule} from "./parser";

describe('aml parser', () => {
    /*test('empty', () => {
        expect(parse('')).toEqual({result: []})
    })*/
    describe('namespaceRule', () => {
        test('schema', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace public')).toEqual({result: {
                command: 'NAMESPACE',
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [10, 15], line: [1, 1], column: [11, 16]}},
            }})
        })
        test('catalog', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace core.public')).toEqual({result: {
                command: 'NAMESPACE',
                catalog: {identifier: 'core', parser: {token: 'Identifier', offset: [10, 13], line: [1, 1], column: [11, 14]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [15, 20], line: [1, 1], column: [16, 21]}},
            }})
        })
        test('database', () => {
            expect(parseRule(p => p.namespaceRule(), 'namespace analytics.core.public')).toEqual({result: {
                command: 'NAMESPACE',
                database: {identifier: 'analytics', parser: {token: 'Identifier', offset: [10, 18], line: [1, 1], column: [11, 19]}},
                catalog: {identifier: 'core', parser: {token: 'Identifier', offset: [20, 23], line: [1, 1], column: [21, 24]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [25, 30], line: [1, 1], column: [26, 31]}},
            }})
        })
    })
    describe('entityRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.entityRule(), 'users')).toEqual({result: {command: 'ENTITY', name: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}}}})
        })
        test('namespace', () => {
            expect(parseRule(p => p.entityRule(), 'ax.core.public.users')).toEqual({result: {
                command: 'ENTITY',
                database: {identifier: 'ax', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                catalog: {identifier: 'core', parser: {token: 'Identifier', offset: [3, 6], line: [1, 1], column: [4, 7]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [8, 13], line: [1, 1], column: [9, 14]}},
                name: {identifier: 'users', parser: {token: 'Identifier', offset: [15, 19], line: [1, 1], column: [16, 20]}},
            }})
        })
        test('alias', () => {
            expect(parseRule(p => p.entityRule(), 'users as u')).toEqual({result: {
                command: 'ENTITY',
                name: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}},
                alias: {identifier: 'u', parser: {token: 'Identifier', offset: [9, 9], line: [1, 1], column: [10, 10]}},
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.entityRule(), 'users {domain: auth} | list users # sample comment')).toEqual({result: {
                command: 'ENTITY',
                name: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}},
                properties: [{
                    key: {identifier: 'domain', parser: {token: 'Identifier', offset: [7, 12], line: [1, 1], column: [8, 13]}},
                    value: {identifier: 'auth', parser: {token: 'Identifier', offset: [15, 18], line: [1, 1], column: [16, 19]}},
                }],
                note: {note: 'list users', parser: {token: 'Note', offset: [21, 33], line: [1, 1], column: [22, 34]}},
                comment: {comment: 'sample comment', parser: {token: 'Comment', offset: [34, 49], line: [1, 1], column: [35, 50]}},
            }})
        })
        test('attributes', () => {
            expect(parseRule(p => p.entityRule(), 'users\n  id uuid pk\n  name varchar\n')).toEqual({result: {
                command: 'ENTITY',
                name: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}},
                attrs: [{
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [8, 9], line: [2, 2], column: [3, 4]}},
                    type: {identifier: 'uuid', parser: {token: 'Identifier', offset: [11, 14], line: [2, 2], column: [6, 9]}},
                    primaryKey: {parser: {token: 'PrimaryKey', offset: [16, 17], line: [2, 2], column: [11, 12]}},
                }, {
                    name: {identifier: 'name', parser: {token: 'Identifier', offset: [21, 24], line: [3, 3], column: [3, 6]}},
                    type: {identifier: 'varchar', parser: {token: 'Identifier', offset: [26, 32], line: [3, 3], column: [8, 14]}},
                }],
            }})
        })
        describe('attributeRule', () => {
            test('name', () => {
                expect(parseRule(p => p.attributeRule(), 'id')).toEqual({result: {name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}}})
            })
            test('type', () => {
                expect(parseRule(p => p.attributeRule(), 'id uuid')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    type: {identifier: 'uuid', parser: {token: 'Identifier', offset: [3, 6], line: [1, 1], column: [4, 7]}},
                }})
                expect(parseRule(p => p.attributeRule(), 'name "varchar(12)"')).toEqual({result: {
                    name: {identifier: 'name', parser: {token: 'Identifier', offset: [0, 3], line: [1, 1], column: [1, 4]}},
                    type: {identifier: 'varchar(12)', parser: {token: 'Identifier', offset: [5, 17], line: [1, 1], column: [6, 18]}},
                }})
                expect(parseRule(p => p.attributeRule(), 'bio "character varying"')).toEqual({result: {
                    name: {identifier: 'bio', parser: {token: 'Identifier', offset: [0, 2], line: [1, 1], column: [1, 3]}},
                    type: {identifier: 'character varying', parser: {token: 'Identifier', offset: [4, 22], line: [1, 1], column: [5, 23]}},
                }})
            })
            test('enum', () => {
                expect(parseRule(p => p.attributeRule(), 'status post_status(draft, published, archived)')).toEqual({result: {
                    name: {identifier: 'status', parser: {token: 'Identifier', offset: [0, 5], line: [1, 1], column: [1, 6]}},
                    type: {identifier: 'post_status', parser: {token: 'Identifier', offset: [7, 17], line: [1, 1], column: [8, 18]}},
                    enumValues: [
                        {identifier: 'draft', parser: {token: 'Identifier', offset: [19, 23], line: [1, 1], column: [20, 24]}},
                        {identifier: 'published', parser: {token: 'Identifier', offset: [26, 34], line: [1, 1], column: [27, 35]}},
                        {identifier: 'archived', parser: {token: 'Identifier', offset: [37, 44], line: [1, 1], column: [38, 45]}},
                    ],
                }})
            })
            test('default', () => {
                expect(parseRule(p => p.attributeRule(), 'id int=0')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    type: {identifier: 'int', parser: {token: 'Identifier', offset: [3, 5], line: [1, 1], column: [4, 6]}},
                    defaultValue: {value: 0, parser: {token: 'Integer', offset: [7, 7], line: [1, 1], column: [8, 8]}},
                }})
            })
            test('nullable', () => {
                expect(parseRule(p => p.attributeRule(), 'id nullable')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    nullable: {parser: {token: 'Nullable', offset: [3, 10], line: [1, 1], column: [4, 11]}},
                }})
            })
            test('pk', () => {
                expect(parseRule(p => p.attributeRule(), 'id pk')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    primaryKey: {parser: {token: 'PrimaryKey', offset: [3, 4], line: [1, 1], column: [4, 5]}},
                }})
            })
            test('index', () => {
                expect(parseRule(p => p.attributeRule(), 'id index')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    index: {parser: {token: 'Index', offset: [3, 7], line: [1, 1], column: [4, 8]}},
                }})
                expect(parseRule(p => p.attributeRule(), 'id index=id_idx')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    index: {parser: {token: 'Index', offset: [3, 7], line: [1, 1], column: [4, 8]}, value: {identifier: 'id_idx', parser: {token: 'Identifier', offset: [9, 14], line: [1, 1], column: [10, 15]}}},
                }})
            })
            test('unique', () => {
                expect(parseRule(p => p.attributeRule(), 'id unique')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    unique: {parser: {token: 'Unique', offset: [3, 8], line: [1, 1], column: [4, 9]}},
                }})
                expect(parseRule(p => p.attributeRule(), 'id unique=id_uniq')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    unique: {parser: {token: 'Unique', offset: [3, 8], line: [1, 1], column: [4, 9]}, value: {identifier: 'id_uniq', parser: {token: 'Identifier', offset: [10, 16], line: [1, 1], column: [11, 17]}}},
                }})
            })
            test('check', () => {
                expect(parseRule(p => p.attributeRule(), 'id check')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    check: {parser: {token: 'Check', offset: [3, 7], line: [1, 1], column: [4, 8]}},
                }})
                expect(parseRule(p => p.attributeRule(), 'id check="id > 0"')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    check: {parser: {token: 'Check', offset: [3, 7], line: [1, 1], column: [4, 8]}, value: {identifier: 'id > 0', parser: {token: 'Identifier', offset: [9, 16], line: [1, 1], column: [10, 17]}}},
                }})
            })
            test('relation', () => {
                expect(parseRule(p => p.attributeRule(), 'user_id -> users(id)')).toEqual({result: {
                    name: {identifier: 'user_id', parser: {token: 'Identifier', offset: [0, 6], line: [1, 1], column: [1, 7]}},
                    relation: {kind: 'n-1', ref: {
                        entity: {identifier: 'users', parser: {token: 'Identifier', offset: [11, 15], line: [1, 1], column: [12, 16]}},
                        attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [17, 18], line: [1, 1], column: [18, 19]}}],
                    }}
                }})
            })
            test('properties', () => {
                expect(parseRule(p => p.attributeRule(), 'id {tag: pii}')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    properties: [{key: {identifier: 'tag', parser: {token: 'Identifier', offset: [4, 6], line: [1, 1], column: [5, 7]}}, value: {identifier: 'pii', parser: {token: 'Identifier', offset: [9, 11], line: [1, 1], column: [10, 12]}}}],
                }})
            })
            test('note', () => {
                expect(parseRule(p => p.attributeRule(), 'id | some note')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    note: {note: 'some note', parser: {token: 'Note', offset: [3, 13], line: [1, 1], column: [4, 14]}},
                }})
            })
            test('comment', () => {
                expect(parseRule(p => p.attributeRule(), 'id # a comment')).toEqual({result: {
                    name: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}},
                    comment: {comment: 'a comment', parser: {token: 'Comment', offset: [3, 13], line: [1, 1], column: [4, 14]}},
                }})
            })
            test('error', () => {
                expect(parseRule(p => p.attributeRule(), '12')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Identifier <-- but found --> '12' <--", position: {offset: [0, 1], line: [1, 1], column: [1, 2]}}]})
            })
        })
    })
    describe('relationRule', () => {
        test('basic', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id)')).toEqual({result: {
                command: 'RELATION',
                kind: 'n-1',
                src: {
                    entity: {identifier: 'groups', parser: {token: 'Identifier', offset: [4, 9], line: [1, 1], column: [5, 10]}},
                    attrs: [{identifier: 'owner', parser: {token: 'Identifier', offset: [11, 15], line: [1, 1], column: [12, 16]}}],
                },
                ref: {
                    entity: {identifier: 'users', parser: {token: 'Identifier', offset: [21, 25], line: [1, 1], column: [22, 26]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [27, 28], line: [1, 1], column: [28, 29]}}],
                },
            }})
        })
        test('one-to-one', () => {
            expect(parseRule(p => p.relationRule(), 'rel profiles(id) -- users(id)')).toEqual({result: {
                command: 'RELATION',
                kind: '1-1',
                src: {
                    entity: {identifier: 'profiles', parser: {token: 'Identifier', offset: [4, 11], line: [1, 1], column: [5, 12]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [13, 14], line: [1, 1], column: [14, 15]}}],
                },
                ref: {
                    entity: {identifier: 'users', parser: {token: 'Identifier', offset: [20, 24], line: [1, 1], column: [21, 25]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [26, 27], line: [1, 1], column: [27, 28]}}],
                },
            }})
        })
        test('many-to-many', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(id) <> users(id)')).toEqual({result: {
                command: 'RELATION',
                kind: 'n-n',
                src: {
                    entity: {identifier: 'groups', parser: {token: 'Identifier', offset: [4, 9], line: [1, 1], column: [5, 10]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [11, 12], line: [1, 1], column: [12, 13]}}],
                },
                ref: {
                    entity: {identifier: 'users', parser: {token: 'Identifier', offset: [18, 22], line: [1, 1], column: [19, 23]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [24, 25], line: [1, 1], column: [25, 26]}}],
                },
            }})
        })
        test('composite', () => {
            expect(parseRule(p => p.relationRule(), 'rel audit(user_id, role_id) -> user_roles(user_id, role_id)')).toEqual({result: {
                command: 'RELATION',
                kind: 'n-1',
                src: {
                    entity: {identifier: 'audit', parser: {token: 'Identifier', offset: [4, 8], line: [1, 1], column: [5, 9]}},
                    attrs: [
                        {identifier: 'user_id', parser: {token: 'Identifier', offset: [10, 16], line: [1, 1], column: [11, 17]}},
                        {identifier: 'role_id', parser: {token: 'Identifier', offset: [19, 25], line: [1, 1], column: [20, 26]}},
                    ],
                },
                ref: {
                    entity: {identifier: 'user_roles', parser: {token: 'Identifier', offset: [31, 40], line: [1, 1], column: [32, 41]}},
                    attrs: [
                        {identifier: 'user_id', parser: {token: 'Identifier', offset: [42, 48], line: [1, 1], column: [43, 49]}},
                        {identifier: 'role_id', parser: {token: 'Identifier', offset: [51, 57], line: [1, 1], column: [52, 58]}},
                    ],
                },
            }})
        })
        test('polymorphic', () => {
            expect(parseRule(p => p.relationRule(), 'rel events(item_id) -item_kind=User> users(id)')).toEqual({result: {
                command: 'RELATION',
                kind: 'n-1',
                src: {
                    entity: {identifier: 'events', parser: {token: 'Identifier', offset: [4, 9], line: [1, 1], column: [5, 10]}},
                    attrs: [{identifier: 'item_id', parser: {token: 'Identifier', offset: [11, 17], line: [1, 1], column: [12, 18]}}],
                },
                ref: {
                    entity: {identifier: 'users', parser: {token: 'Identifier', offset: [37, 41], line: [1, 1], column: [38, 42]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [43, 44], line: [1, 1], column: [44, 45]}}],
                },
                polymorphic: {
                    attr: {identifier: 'item_kind', parser: {token: 'Identifier', offset: [21, 29], line: [1, 1], column: [22, 30]}},
                    value: {identifier: 'User', parser: {token: 'Identifier', offset: [31, 34], line: [1, 1], column: [32, 35]}},
                }
            }})
        })
        test('extra', () => {
            expect(parseRule(p => p.relationRule(), 'rel groups(owner) -> users(id) {color: red} | a note # a comment')).toEqual({result: {
                command: 'RELATION',
                kind: 'n-1',
                src: {
                    entity: {identifier: 'groups', parser: {token: 'Identifier', offset: [4, 9], line: [1, 1], column: [5, 10]}},
                    attrs: [{identifier: 'owner', parser: {token: 'Identifier', offset: [11, 15], line: [1, 1], column: [12, 16]}}],
                },
                ref: {
                    entity: {identifier: 'users', parser: {token: 'Identifier', offset: [21, 25], line: [1, 1], column: [22, 26]}},
                    attrs: [{identifier: 'id', parser: {token: 'Identifier', offset: [27, 28], line: [1, 1], column: [28, 29]}}],
                },
                properties: [{
                    key: {identifier: 'color', parser: {token: 'Identifier', offset: [32, 36], line: [1, 1], column: [33, 37]}},
                    value: {identifier: 'red', parser: {token: 'Identifier', offset: [39, 41], line: [1, 1], column: [40, 42]}}
                }],
                note: {note: 'a note', parser: {token: 'Note', offset: [44, 52], line: [1, 1], column: [45, 53]}},
                comment: {comment: 'a comment', parser: {token: 'Comment', offset: [53, 63], line: [1, 1], column: [54, 64]}},
            }})
        })
        test('bad', () => {
            expect(parseRule(p => p.relationRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Relation <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
    })
    describe.skip('typeRule', () => {
        test('enum', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_status enum(new, in progress, done)')).toEqual({result: {}})
        })
        test('struct', () => {
            expect(parseRule(p => p.typeRule(), 'type address {number: int, street: varchar}')).toEqual({result: {}})
        })
        test('custom', () => {
            expect(parseRule(p => p.typeRule(), 'type bug_value range(subtype = float8, subtype_diff = float8mi)')).toEqual({result: {}})
        })
    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: {value: 12, parser: {token: 'Integer', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {identifier: 'my col', parser: {token: 'Identifier', offset: [0, 7], line: [1, 1], column: [1, 8]}}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {identifier: 'my "new" col', parser: {token: 'Identifier', offset: [0, 15], line: [1, 1], column: [1, 16]}}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({errors: [{name: 'NotAllInputParsedException', message: "Redundant input, expecting EOF but found: col", position: {offset: [4, 6], line: [1, 1], column: [5, 7]}}]})
        })
        test('commentRule', () => {
            expect(parseRule(p => p.commentRule(), '# a comment')).toEqual({result: {comment: 'a comment', parser: {token: 'Comment', offset: [0, 10], line: [1, 1], column: [1, 11]}}})
            expect(parseRule(p => p.commentRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Comment <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('noteRule', () => {
            expect(parseRule(p => p.noteRule(), '| a note')).toEqual({result: {note: 'a note', parser: {token: 'Note', offset: [0, 7], line: [1, 1], column: [1, 8]}}})
            // TODO expect(parseRule(p => p.noteRule(), '|||\n   a note\n   multiline\n|||')).toEqual({result: {note: 'a note\nmultiline', parser: {token: 'Note', offset: [0, 7], line: [1, 1], column: [1, 8]}}})
            expect(parseRule(p => p.noteRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Note <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('propertiesRule', () => {
            expect(parseRule(p => p.propertiesRule(), '{}')).toEqual({result: []})
            expect(parseRule(p => p.propertiesRule(), '{flag}')).toEqual({result: [{key: {identifier: 'flag', parser: {token: 'Identifier', offset: [1, 4], line: [1, 1], column: [2, 5]}}}]})
            expect(parseRule(p => p.propertiesRule(), '{color: red}')).toEqual({result: [{
                key: {identifier: 'color', parser: {token: 'Identifier', offset: [1, 5], line: [1, 1], column: [2, 6]}},
                value: {identifier: 'red', parser: {token: 'Identifier', offset: [8, 10], line: [1, 1], column: [9, 11]}}
            }]})
            expect(parseRule(p => p.propertiesRule(), '{size: 12}')).toEqual({result: [{
                key: {identifier: 'size', parser: {token: 'Identifier', offset: [1, 4], line: [1, 1], column: [2, 5]}},
                value: {value: 12, parser: {token: 'Integer', offset: [7, 8], line: [1, 1], column: [8, 9]}}
            }]})
            expect(parseRule(p => p.propertiesRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> LCurly <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('extraRule', () => {
            expect(parseRule(p => p.extraRule(), '')).toEqual({result: {}})
            expect(parseRule(p => p.extraRule(), '{key: value} | some note # a comment')).toEqual({result: {
                properties: [{
                    key: {identifier: 'key', parser: {token: 'Identifier', offset: [1, 3], line: [1, 1], column: [2, 4]}},
                    value: {identifier: 'value', parser: {token: 'Identifier', offset: [6, 10], line: [1, 1], column: [7, 11]}}
                }],
                note: {note: 'some note', parser: {token: 'Note', offset: [13, 24], line: [1, 1], column: [14, 25]}},
                comment: {comment: 'a comment', parser: {token: 'Comment', offset: [25, 35], line: [1, 1], column: [26, 36]}},
            }})
        })
        test('entityRefRule', () => {
            expect(parseRule(p => p.entityRefRule(), 'users')).toEqual({result: {entity: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}}}})
            expect(parseRule(p => p.entityRefRule(), 'public.users')).toEqual({result: {
                entity: {identifier: 'users', parser: {token: 'Identifier', offset: [7, 11], line: [1, 1], column: [8, 12]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [0, 5], line: [1, 1], column: [1, 6]}},
            }})
            expect(parseRule(p => p.entityRefRule(), 'core.public.users')).toEqual({result: {
                entity: {identifier: 'users', parser: {token: 'Identifier', offset: [12, 16], line: [1, 1], column: [13, 17]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [5, 10], line: [1, 1], column: [6, 11]}},
                catalog: {identifier: 'core', parser: {token: 'Identifier', offset: [0, 3], line: [1, 1], column: [1, 4]}},
            }})
            expect(parseRule(p => p.entityRefRule(), 'analytics.core.public.users')).toEqual({result: {
                entity: {identifier: 'users', parser: {token: 'Identifier', offset: [22, 26], line: [1, 1], column: [23, 27]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [15, 20], line: [1, 1], column: [16, 21]}},
                catalog: {identifier: 'core', parser: {token: 'Identifier', offset: [10, 13], line: [1, 1], column: [11, 14]}},
                database: {identifier: 'analytics', parser: {token: 'Identifier', offset: [0, 8], line: [1, 1], column: [1, 9]}},
            }})
            expect(parseRule(p => p.entityRefRule(), '42')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Identifier <-- but found --> '42' <--", position: {offset: [0, 1], line: [1, 1], column: [1, 2]}}]})
        })
        test('columnPathRule', () => {
            expect(parseRule(p => p.attributePathRule(), 'details')).toEqual({result: {identifier: 'details', parser: {token: 'Identifier', offset: [0, 6], line: [1, 1], column: [1, 7]}}})
            expect(parseRule(p => p.attributePathRule(), 'details.address.street')).toEqual({result: {
                identifier: 'details',
                parser: {token: 'Identifier', offset: [0, 6], line: [1, 1], column: [1, 7]},
                path: [
                    {identifier: 'address', parser: {token: 'Identifier', offset: [8, 14], line: [1, 1], column: [9, 15]}},
                    {identifier: 'street', parser: {token: 'Identifier', offset: [16, 21], line: [1, 1], column: [17, 22]}}
                ],
            }})
            expect(parseRule(p => p.attributePathRule(), '42')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Identifier <-- but found --> '42' <--", position: {offset: [0, 1], line: [1, 1], column: [1, 2]}}]})
        })
        test('columnRefRule', () => {
            expect(parseRule(p => p.attributeRefRule(), 'users(id)')).toEqual({result: {
                entity: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}},
                attr: {identifier: 'id', parser: {token: 'Identifier', offset: [6, 7], line: [1, 1], column: [7, 8]}},
            }})
            expect(parseRule(p => p.attributeRefRule(), 'public.events(details.item_id)')).toEqual({result: {
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [0, 5], line: [1, 1], column: [1, 6]}},
                entity: {identifier: 'events', parser: {token: 'Identifier', offset: [7, 12], line: [1, 1], column: [8, 13]}},
                attr: {
                    identifier: 'details',
                    parser: {token: 'Identifier', offset: [14, 20], line: [1, 1], column: [15, 21]},
                    path: [{identifier: 'item_id', parser: {token: 'Identifier', offset: [22, 28], line: [1, 1], column: [23, 29]}}]
                },
            }})
        })
        test('columnRefCompositeRule', () => {
            expect(parseRule(p => p.attributeRefCompositeRule(), 'user_roles(user_id, role_id)')).toEqual({result: {
                entity: {identifier: 'user_roles', parser: {token: 'Identifier', offset: [0, 9], line: [1, 1], column: [1, 10]}},
                attrs: [
                    {identifier: 'user_id', parser: {token: 'Identifier', offset: [11, 17], line: [1, 1], column: [12, 18]}},
                    {identifier: 'role_id', parser: {token: 'Identifier', offset: [20, 26], line: [1, 1], column: [21, 27]}},
                ],
            }})
        })
        test('columnValueRule', () => {
            expect(parseRule(p => p.attributeValueRule(), 'User')).toEqual({result: {identifier: 'User', parser: {token: 'Identifier', offset: [0, 3], line: [1, 1], column: [1, 4]}}})
            expect(parseRule(p => p.attributeValueRule(), '42')).toEqual({result: {value: 42, parser: {token: 'Integer', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
        })
    })
})
