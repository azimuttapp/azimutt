import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, ParserResult, tokenPosition} from "@azimutt/models";
import {genEntity, generateAml, parseAml} from "./aml";
import {duplicated, legacy} from "./errors";

describe('aml', () => {
    // TODO: namespace
    // TODO: entity alias
    test('empty schema',  () => {
        const input = ``
        const db: Database = {extra: {}}
        const parsed = parseAmlTest(input)
        expect(parsed).toEqual({result: db})
        expect(generateAml(parsed.result || {})).toEqual(input)
    })
    test('sample schema', () => {
        const input = `
#
# AML
#

countries
  id int pk
  name varchar

identity.users as users |||
  list
  all users
|||
  id int pk # users primary key
  name varchar(12) unique
  role user_role(admin, guest)=guest
  settings json {owner: team1}
    github string |||
      multiline note
      for github
    |||
    twitter string
    address json
      number number
      street string
      city string index=address
      country int index=address -> countries
  created_at timestamp=\`now()\`

posts* {pii, tags: [cms]} | all posts # an other entity
  id post_id pk
  title "character varying(100)"=draft nullable index | Title of the post
  author int check=\`author > 0\` -> users(id)
  created_by int

rel posts(created_by) -> users(id) {onUpdate: no_action, onDelete: cascade} | standalone relation

emails
  user_id int pk
  email varchar pk

# types

type post_id int {table: posts} | alias
type status (draft, published, archived)
type position {x int, y int} {generic}
type range \`(subtype = float8, subtype_diff = float8mi)\` # custom type
`
        const db: Database = {
            entities: [{
                name: 'countries',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                ],
                pk: {attrs: [['id']]},
                extra: {line: 6, statement: 1}
            }, {
                schema: 'identity',
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int', extra: {comment: 'users primary key'}},
                    {name: 'name', type: 'varchar(12)'},
                    {name: 'role', type: 'user_role', default: 'guest'},
                    {name: 'settings', type: 'json', attrs: [
                        {name: 'github', type: 'string', doc: "multiline note\nfor github"},
                        {name: 'twitter', type: 'string'},
                        {name: 'address', type: 'json', attrs: [
                            {name: 'number', type: 'number'},
                            {name: 'street', type: 'string'},
                            {name: 'city', type: 'string'},
                            {name: 'country', type: 'int'},
                        ]},
                    ], extra: {owner: 'team1'}},
                    {name: 'created_at', type: 'timestamp', default: '`now()`'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['name']], unique: true}, {name: 'address', attrs: [['settings', 'address', 'city'], ['settings', 'address', 'country']]}],
                doc: 'list\nall users',
                extra: {line: 10, statement: 2, alias: "users"}
            }, {
                name: 'posts',
                kind: 'view',
                attrs: [
                    {name: 'id', type: 'post_id'},
                    {name: 'title', type: 'character varying(100)', default: 'draft', null: true, doc: 'Title of the post'},
                    {name: 'author', type: 'int'},
                    {name: 'created_by', type: 'int'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['title']]}],
                checks: [{attrs: [['author']], predicate: 'author > 0'}],
                doc: 'all posts',
                extra: {line: 30, statement: 3, comment: 'an other entity', pii: true, tags: ['cms']}
            }, {
                name: 'emails',
                attrs: [
                    {name: 'user_id', type: 'int'},
                    {name: 'email', type: 'varchar'},
                ],
                pk: {attrs: [['user_id'], ['email']]},
                extra: {line: 38, statement: 5}
            }],
            relations: [
                {src: {schema: 'identity', entity: 'users'}, ref: {entity: 'countries'}, attrs: [{src: ['settings', 'address', 'country'], ref: ['id']}], extra: {line: 27, statement: 2, natural: 'ref', inline: true}},
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {line: 33, statement: 3, inline: true}},
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}], doc: 'standalone relation', extra: {line: 36, statement: 4, onUpdate: 'no_action', onDelete: 'cascade'}},
            ],
            types: [
                {schema: 'identity', name: 'user_role', values: ['admin', 'guest'], extra: {line: 16, statement: 2}},
                {name: 'post_id', definition: 'int', doc: 'alias', extra: {line: 44, statement: 6, table: 'posts'}},
                {name: 'status', values: ['draft', 'published', 'archived'], extra: {line: 45, statement: 7}},
                {name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}], extra: {line: 46, statement: 8, generic: true}},
                {name: 'range', definition: '(subtype = float8, subtype_diff = float8mi)', extra: {line: 47, statement: 9, comment: 'custom type'}},
            ],
            extra: {comments: [
                {line: 2, comment: ''},
                {line: 3, comment: 'AML'},
                {line: 4, comment: ''},
                {line: 42, comment: 'types'},
            ]}
        }
        const parsed = parseAmlTest(input)
        expect(parsed).toEqual({result: db})
        expect(generateAml(parsed.result || {})).toEqual(input.trim() + '\n')
    })
    test.skip('complex schema',  () => {
        const input = fs.readFileSync('./resources/complex.aml', 'utf8')
        const json = fs.readFileSync('./resources/complex.json', 'utf8')
        const db: Database = JSON.parse(json)
        const parsed = parseAmlTest(input)
        expect(parsed).toEqual({result: db})
        expect(generateAml(parsed.result || {})).toEqual(input.trim() + '\n')
    })
    test('escape doc',  () => {
        const input = `users\n  settings json | ex: {color: \\#000} # you can escape # in doc using \\#\n`
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'settings', type: 'json', doc: 'ex: {color: #000}', extra: {comment: 'you can escape # in doc using \\#'}}], extra: {line: 1, statement: 1}}], extra: {}}
        const parsed = parseAmlTest(input)
        expect(parsed).toEqual({result: db})
        expect(generateAml(parsed.result || {})).toEqual(input)
    })
    test('duplicate inline type',  () => {
        const input = `posts\n  status status(draft, published)\n\ncomments\n  status status(draft, published)\n`
        const db: Database = {
            entities: [
                {name: 'posts', attrs: [{name: 'status', type: 'status'}], extra: {line: 1, statement: 1}},
                {name: 'comments', attrs: [{name: 'status', type: 'status'}], extra: {line: 4, statement: 2}},
            ],
            types: [{name: 'status', values: ['draft', 'published'], extra: {line: 2, statement: 1}}],
            extra: {}
        }
        const parsed = parseAmlTest(input)
        expect(parsed).toEqual({result: db, errors: [{name: 'Duplicated', kind: 'warning', message: 'Type status already defined at line 2', ...tokenPosition(66, 81, 5, 17, 5, 32)}]})
        expect(generateAml(parsed.result || {})).toEqual(input)
    })
    test('bad schema', () => {
        expect(parseAmlTest(`a bad schema`)).toEqual({
            result: {
                entities: [
                    {name: 'a', extra: {line: 1, statement: 1}},
                    {name: 'bad', extra: {line: 1, statement: 2}},
                    {name: 'schema', extra: {line: 1, statement: 3}},
                ],
                extra: {}
            },
            errors: [
                {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'bad' <--", ...tokenPosition(2, 4, 1, 3, 1, 5)},
                {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'schema' <--", ...tokenPosition(6, 11, 1, 7, 1, 12)},
            ]
        })
    })
    describe('generateAml', () => {
        test('composite index', () => {
            expect(generateAml({entities: [{name: 'users', attrs: [{name: 'name', type: 'varchar'}, {name: 'email', type: 'varchar'}], indexes: [{attrs: [['name'], ['email']], name: 'users_1'}]}]}))
                .toEqual('users\n  name varchar index=users_1\n  email varchar index=users_1\n')
            expect(generateAml({entities: [{name: 'users', attrs: [{name: 'name', type: 'varchar'}, {name: 'email', type: 'varchar'}], indexes: [{attrs: [['name'], ['email']]}]}]}))
                .toEqual('users\n  name varchar index=users_idx_1\n  email varchar index=users_idx_1\n')
        })
        describe('genEntity', () => {
            test('should work without attributes', () => {
                expect(genEntity({name: 'users'}, [], [], false)).toEqual('users\n')
            })
        })
    })

    // check issues are reported
    describe('warnings', () => {
        test('duplicate entity', () => {
            expect(parseAml(`
public.users
  id uuid pk
  name varchar

public.users
  id uuid pk
  name varchar`).errors).toEqual([duplicated('Entity public.users', 2, tokenPosition(43, 54, 6, 1, 6, 12))])

            expect(parseAml(`
public.users
  id uuid pk
  name varchar

namespace public

users
  id uuid pk
  name varchar`).errors).toEqual([duplicated('Entity public.users', 2, tokenPosition(61, 65, 8, 1, 8, 5))])
        })
        test('duplicate relation', () => {
            expect(parseAml(`
posts
  id uuid pk
  author uuid -> users(id)

rel posts(author) -> users(id)
`).errors).toEqual([duplicated('Relation posts(author)->users(id)', 4, tokenPosition(52, 76, 6, 5, 6, 29))])
        })
        test('duplicate type', () => {
            expect(parseAml(`
public.posts
  id uuid pk
  status status(draft, published)

type public.status (pending, wip, done)
`).errors).toEqual([duplicated('Type public.status', 4, tokenPosition(67, 79, 6, 6, 6, 18))])
        })
    })

    // make sure the parser don't fail on invalid input
    describe('errors', () => {
        test('attribute relation', () => {
            expect(parseAmlTest('posts\n  author int\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}}
            })
            expect(parseAmlTest('posts\n  author int -\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}},
                errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Dash]\n  2. [LowerThan]\n  3. [GreaterThan]\nbut found: '\n'", ...tokenPosition(20, 20, 2, 15, 2, 15)}]
            })
            expect(parseAmlTest('posts\n  author int ->\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}},
                errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", ...tokenPosition(21, 21, 2, 16, 2, 16)}]
            })
            expect(parseAmlTest('posts\n  author int -> users\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['unknown']}], extra: {line: 2, statement: 1, natural: 'ref', inline: true}}], extra: {}},
            })
            expect(parseAmlTest('posts\n  author int -> users(\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}},
                errors: [{name: 'EarlyExitException', kind: 'error', message: "Expecting: expecting at least one iteration which starts with one of these possible Token sequences::\n  <[WhiteSpace] ,[Identifier]>\nbut found: '\n'", ...tokenPosition(28, 28, 2, 23, 2, 23)}]
            })
            expect(parseAmlTest('posts\n  author int -> users(id\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {line: 2, statement: 1, inline: true}}], extra: {}},
                errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> RParen <-- but found --> '\n' <--", ...tokenPosition(30, 30, 2, 25, 2, 25)}]
            })
            expect(parseAmlTest('posts\n  author int -> users(id)\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {line: 2, statement: 1, inline: true}}], extra: {}},
            })

            expect(parseAmlTest('posts\n  author int - users(id)\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {line: 2, statement: 1, inline: true}}], extra: {}},
                errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Dash]\n  2. [LowerThan]\n  3. [GreaterThan]\nbut found: ' '", ...tokenPosition(20, 20, 2, 15, 2, 15)}]
            })
            expect(parseAmlTest('posts\n  author int  users(id)\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}, {name: 'id', extra: {line: 2, statement: 2}}], extra: {}},
                // TODO handle error better to not generate a fake entity (id)
                errors: [
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'users' <--", ...tokenPosition(20, 24, 2, 15, 2, 19)},
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> '(' <--", ...tokenPosition(25, 25, 2, 20, 2, 20)},
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> ')' <--", ...tokenPosition(28, 28, 2, 23, 2, 23)}
                ]
            })
        })
        test('attribute relation legacy', () => {
            expect(parseAmlTest('posts\n  author int\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}}
            })
            expect(parseAmlTest('posts\n  author int f\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}, {name: 'f', extra: {line: 2, statement: 2}}], extra: {}},
                errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'f' <--", ...tokenPosition(19, 19, 2, 14, 2, 14)}]
            })
            expect(parseAmlTest('posts\n  author int fk\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}},
                errors: [
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", ...tokenPosition(21, 21, 2, 16, 2, 16)},
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(19, 20, 2, 14, 2, 15)},
                ]
            })
            expect(parseAmlTest('posts\n  author int fk users\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['unknown']}], extra: {line: 2, statement: 1, natural: 'ref', inline: true}}], extra: {}},
                // TODO: an error should be reported here
                errors: [{...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(19, 20, 2, 14, 2, 15)}]
            })
            expect(parseAmlTest('posts\n  author int fk users.\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}], extra: {}},
                errors: [
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", ...tokenPosition(28, 28, 2, 23, 2, 23)},
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(19, 20, 2, 14, 2, 15)},
                    {...legacy('"users." is the legacy way, use "users()" instead'), ...tokenPosition(22, 26, 2, 17, 2, 21)},
                ]
            })
            expect(parseAmlTest('posts\n  author int fk users.id\n')).toEqual({
                result: {
                    entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {line: 1, statement: 1}}],
                    relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {line: 2, statement: 1, inline: true}}],
                    extra: {}
                },
                errors: [
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(19, 20, 2, 14, 2, 15)},
                    {...legacy('"users.id" is the legacy way, use "users(id)" instead'), ...tokenPosition(22, 29, 2, 17, 2, 24)},
                ]
            })
        })
        test('incorrect properties', () => {
            expect(() => parseAmlTest('users {pii:}\n')).not.toThrow()
            expect(() => parseAmlTest('users\n  name varchar {pii:}\n')).not.toThrow()
        })
        test('no crash on typing', () => {
            const input = `
users
  id int pk
  name varchar {pii: true}
  role user_role=guest
  settings json
    github bool=false
    twitter bool=false

crm.public.posts {color: red} | entity doc # entity comment
  id uuid pk
  title varchar(100)="" unique=post_title {tags: indexed} | attr doc # attr comment
  created_by int -> users(id)

crm.public.comments |||
  multi-line
  entity
  doc
|||
  id uuid pk |||
    multi-line
    attribute
    doc
  |||
  item_kind comment_item(posts, comments)
  item_id uuid
  content text
  created_by int -> users(id)

rel crm.public.comments(item_id) -item_kind=posts> crm.public.posts(id)
rel crm.public.comments(item_id) -item_kind=comments> crm.public.comments(id)
type user_role (admin, guest)
`
            const length = input.length
            for (let i = 0; i < length; i++) {
                // parse the input at all length to make sure no partial input can break the parser
                expect(() => parseAmlTest(input.slice(0, i))).not.toThrow()
            }
        })
    })

    // make sure AML v1 is still correctly parsed
    describe('legacy', () => {
        test('basic', () => {
            expect(parseAmlTest(`
users
  id int
  name varchar(12)
  role user_role(admin, guest)

talks
  id int
  title varchar(140)
  speaker int fk users.id
`)).toEqual({
                result: {
                    entities: [{
                        name: 'users',
                        attrs: [
                            {name: 'id', type: 'int'},
                            {name: 'name', type: 'varchar(12)'},
                            {name: 'role', type: 'user_role'},
                        ],
                        extra: {line: 2, statement: 1}
                    }, {
                        name: 'talks',
                        attrs: [
                            {name: 'id', type: 'int'},
                            {name: 'title', type: 'varchar(140)'},
                            {name: 'speaker', type: 'int'},
                        ],
                        extra: {line: 7, statement: 2}
                    }],
                    relations: [
                        {src: {entity: 'talks'}, ref: {entity: 'users'}, attrs: [{src: ['speaker'], ref: ['id']}], extra: {line: 10, statement: 2, inline: true}}
                    ],
                    types: [
                        {name: 'user_role', values: ['admin', 'guest'], extra: {line: 5, statement: 1}}
                    ],
                    extra: {}
                },
                errors: [
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(117, 118, 10, 15, 10, 16)},
                    {...legacy('"users.id" is the legacy way, use "users(id)" instead'), ...tokenPosition(120, 127, 10, 18, 10, 25)},
                ]
            })
        })
        test('complex', () => {
            expect(parseAmlTest(`

emails
  email varchar
  score "double precision"

# How to define a table and it's columns
public.users {color=red, top=10, left=20} | Table description # a table with everything!
  id int pk
  role varchar=guest {hidden}
  score "double precision"=0.0 index {hidden} | User progression # a column with almost all possible attributes
  first_name varchar(10) unique=name
  last_name varchar(10) unique=name
  email varchar nullable check="email LIKE '%@%'" fk emails.email

admins* | View of \`users\` table with only admins
  id
  name | Computed from user first_name and last_name

fk admins.id -> users.id

`)).toEqual({
                result: {
                    entities: [{
                        name: "emails",
                        attrs: [
                            {name: "email", type: "varchar"},
                            {name: "score", type: "double precision"},
                        ],
                        extra: {line: 3, statement: 1}
                    }, {
                        schema: "public",
                        name: "users",
                        attrs: [
                            {name: 'id', type: 'int'},
                            {name: 'role', type: 'varchar', default: 'guest', extra: {hidden: true}},
                            {name: 'score', type: 'double precision', default: 0, doc: 'User progression', extra: {comment: 'a column with almost all possible attributes', hidden: true}},
                            {name: 'first_name', type: 'varchar(10)'},
                            {name: 'last_name', type: 'varchar(10)'},
                            {name: 'email', type: 'varchar', null: true},
                        ],
                        pk: {attrs: [['id']]},
                        indexes: [{name: 'name', attrs: [['first_name'], ['last_name']], unique: true}, {attrs: [['score']]}],
                        checks: [{attrs: [['email']], predicate: "email LIKE '%@%'"}],
                        doc: 'Table description',
                        extra: {line: 8, statement: 2, comment: 'a table with everything!', color: 'red', top: 10, left: 20}
                    }, {
                        name: 'admins',
                        kind: 'view',
                        attrs: [
                            {name: 'id', type: 'unknown'},
                            {name: 'name', type: 'unknown', doc: 'Computed from user first_name and last_name'},
                        ],
                        doc: 'View of `users` table with only admins',
                        extra: {line: 16, statement: 3}
                    }],
                    relations: [
                        {src: {schema: 'public', entity: 'users'}, ref: {entity: 'emails'}, attrs: [{src: ['email'], ref: ['email']}], extra: {line: 14, statement: 2, inline: true}},
                        {src: {entity: 'admins'}, ref: {entity: 'users'}, attrs: [{src: ['id'], ref: ['id']}], extra: {line: 20, statement: 4}},
                    ],
                    extra: {comments: [{line: 7, comment: 'How to define a table and it\'s columns'}]}
                },
                errors: [
                    {...legacy('"=" is legacy, replace it with ":"'), ...tokenPosition(113, 113, 8, 20, 8, 20)},
                    {...legacy('"=" is legacy, replace it with ":"'), ...tokenPosition(122, 122, 8, 29, 8, 29)},
                    {...legacy('"=" is legacy, replace it with ":"'), ...tokenPosition(131, 131, 8, 38, 8, 38)},
                    {...legacy('"email LIKE \'%@%\'" is the legacy way, use expression "`email LIKE \'%@%\'`" instead'), ...tokenPosition(441, 458, 14, 32, 14, 49)},
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(460, 461, 14, 51, 14, 52)},
                    {...legacy('"emails.email" is the legacy way, use "emails(email)" instead'), ...tokenPosition(463, 474, 14, 54, 14, 65)},
                    {...legacy('"fk" is legacy, replace it with "rel"'), ...tokenPosition(585, 586, 20, 1, 20, 2)},
                    {...legacy('"admins.id" is the legacy way, use "admins(id)" instead'), ...tokenPosition(588, 596, 20, 4, 20, 12)},
                    {...legacy('"users.id" is the legacy way, use "users(id)" instead'), ...tokenPosition(601, 608, 20, 17, 20, 24)},
                ]
            })
        })
        test('crm conversion', () => {
            const input = `contact_roles
  contact_id uuid pk fk contacts.id
  role_id uuid pk fk roles.id

contacts
  id uuid pk
  name varchar
  email varchar

events
  id uuid pk
  contact_id uuid nullable fk contacts.id
  instance_name varchar | hostname
  instance_id uuid

roles
  id uuid pk
  name varchar`
            const db: Database = {
                entities: [{
                    name: 'contact_roles',
                    attrs: [
                        {name: 'contact_id', type: 'uuid'},
                        {name: 'role_id', type: 'uuid'},
                    ],
                    pk: {attrs: [['contact_id'], ['role_id']]},
                    extra: {line: 1, statement: 1}
                }, {
                    name: 'contacts',
                    attrs: [
                        {name: 'id', type: 'uuid'},
                        {name: 'name', type: 'varchar'},
                        {name: 'email', type: 'varchar'},
                    ],
                    pk: {attrs: [['id']]},
                    extra: {line: 5, statement: 2}
                }, {
                    name: 'events',
                    attrs: [
                        {name: 'id', type: 'uuid'},
                        {name: 'contact_id', type: 'uuid', null: true},
                        {name: 'instance_name', type: 'varchar', doc: 'hostname'},
                        {name: 'instance_id', type: 'uuid'},
                    ],
                    pk: {attrs: [['id']]},
                    extra: {line: 10, statement: 3}
                }, {
                    name: 'roles',
                    attrs: [
                        {name: 'id', type: 'uuid'},
                        {name: 'name', type: 'varchar'},
                    ],
                    pk: {attrs: [['id']]},
                    extra: {line: 16, statement: 4}
                }],
                relations: [
                    {src: {entity: 'contact_roles'}, ref: {entity: 'contacts'}, attrs: [{src: ['contact_id'], ref: ['id']}], extra: {line: 2, statement: 1, inline: true}},
                    {src: {entity: 'contact_roles'}, ref: {entity: 'roles'}, attrs: [{src: ['role_id'], ref: ['id']}], extra: {line: 3, statement: 1, inline: true}},
                    {src: {entity: 'events'}, ref: {entity: 'contacts'}, attrs: [{src: ['contact_id'], ref: ['id']}], extra: {line: 12, statement: 3, inline: true}},
                ],
                extra: {}
            }
            const parsed = parseAmlTest(input)
            expect(parsed).toEqual({
                result: db,
                errors: [
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(35, 36, 2, 22, 2, 23)},
                    {...legacy('"contacts.id" is the legacy way, use "contacts(id)" instead'), ...tokenPosition(38, 48, 2, 25, 2, 35)},
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(68, 69, 3, 19, 3, 20)},
                    {...legacy('"roles.id" is the legacy way, use "roles(id)" instead'), ...tokenPosition(71, 78, 3, 22, 3, 29)},
                    {...legacy('"fk" is legacy, replace it with "->"'), ...tokenPosition(182, 183, 12, 28, 12, 29)},
                    {...legacy('"contacts.id" is the legacy way, use "contacts(id)" instead'), ...tokenPosition(185, 195, 12, 31, 12, 41)},
                ]
            })
            expect(generateAml(parsed.result || {}, true)).toEqual(input.trim() + '\n')
        })
        test('flexible identifiers', () => {
            // in v1, identifiers have no space and ends with the stop char of their context ('.' in entities, ',' in props...), more chars allowed...
            expect(parseAmlTest(`
C##INVENTORY.USERS
  ID BIGINT
  NAME VARCHAR
`)).toEqual({result: {entities: [{
                schema: 'C##INVENTORY',
                name: 'USERS',
                attrs: [
                    {name: 'ID', type: 'BIGINT'},
                    {name: 'NAME', type: 'VARCHAR'}
                ],
                extra: {line: 2, statement: 1}
            }], extra: {}}})
        })
        test('uppercase keywords', () => {
            expect(parseAmlTest(`
USERS
  ID BIGINT PK
  NAME VARCHAR
`)).toEqual({result: {entities: [{
                name: 'USERS',
                attrs: [
                    {name: 'ID', type: 'BIGINT'},
                    {name: 'NAME', type: 'VARCHAR'}
                ],
                pk: {attrs: [['ID']]},
                extra: {line: 2, statement: 1}
            }], extra: {}}})
        })
        test.skip('flexible enum values', () => {
            // too hard to make it pass, leave it for now
            // in v1, identifiers have no space and ends with the stop char of their context ('.' in entities, ',' in props...), more chars allowed...
            expect(parseAmlTest(`
users
  id bigint
  format asset_format(  1:1  ,  16:9  ,  4:3  )
  owner cart_owner(identity.Devices,identity.Users)
`)).toEqual({result: {
                entities: [{
                    name: 'users',
                    attrs: [
                        {name: 'id', type: 'bigint'},
                        {name: 'format', type: 'asset_format'},
                        {name: 'owner', type: 'cart_owner'},
                    ],
                    extra: {line: 2, statement: 1}
                }],
                types: [
                    {name: 'asset_format', values: ['1:1', '16:9', '4:3'], extra: {line: 4, statement: 1}},
                    {name: 'cart_owner', values: ['identity.Devices', 'identity.Users'], extra: {line: 5, statement: 1}},
                ],
                extra: {}
            }})
        })
    })
})

function parseAmlTest(aml: string): ParserResult<Database> {
    // remove not relevant db extra fields & print exception
    try {
        return parseAml(aml).map(({extra: {source, createdAt, creationTimeMs, parsingTimeMs, formattingTimeMs, ...extra} = {}, ...db}) => ({...db, extra}))
    } catch (e) {
        console.error(e) // print stack trace
        throw new Error(`Can't parse '${aml}'${typeof e === 'object' && e !== null && 'message' in e ? ': ' + e.message : ''}`)
    }
}

/*function printJson(json: any) {
    console.log(JSON.stringify(json)
        .replaceAll(/"([^" ]+)":/g, '$1:')
        .replaceAll(/:"([^" ]+)"/g, ":'$1'")
        .replaceAll(/\n/g, '\\n')
        .replaceAll(/,message:'([^"]*?)',position:/g, ',message:"$1",position:'))
}*/
