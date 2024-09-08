import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, ParserResult, tokenPosition} from "@azimutt/models";
import {generateAml, parseAml} from "./aml";

describe('aml', () => {
    // TODO: add comment only lines
    // TODO: add props on entity, attribute, relation & type
    test('sample schema', () => {
        const input = `
users |||
  list
  all users
|||
  id int pk # users primary key
  name varchar
  role user_role(admin, guest)=guest
  settings json
    github string |||
      multiline note
      for github
    |||
    twitter string
    address json
      number number
      street string
      city string index=address
      country string index=address
  created_at timestamp=\`now()\`

posts* | all posts # an other entity
  id post_id pk
  title "varchar(100)" index | Title of the post
  author int check=\`author > 0\` -> users(id)
  created_by int

rel posts(created_by) -> users(id) | standalone relation

type post_id int | alias

type status (draft, published, archived)

type position {x int, y int}

type range \`(subtype = float8, subtype_diff = float8mi)\` # custom type
`
        const parsed: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int', extra: {comment: 'users primary key'}},
                    {name: 'name', type: 'varchar'},
                    {name: 'role', type: 'user_role', default: 'guest'},
                    {name: 'settings', type: 'json', attrs: [
                        {name: 'github', type: 'string', doc: "multiline note\nfor github"},
                        {name: 'twitter', type: 'string'},
                        {name: 'address', type: 'json', attrs: [
                            {name: 'number', type: 'number'},
                            {name: 'street', type: 'string'},
                            {name: 'city', type: 'string'},
                            {name: 'country', type: 'string'},
                        ]},
                    ]},
                    {name: 'created_at', type: 'timestamp', default: '`now()`'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{name: 'address', attrs: [['settings', 'address', 'city'], ['settings', 'address', 'country']]}],
                doc: 'list\nall users',
                extra: {statement: 1}
            }, {
                name: 'posts',
                kind: 'view',
                attrs: [
                    {name: 'id', type: 'post_id'},
                    {name: 'title', type: 'varchar(100)', doc: 'Title of the post'},
                    {name: 'author', type: 'int'},
                    {name: 'created_by', type: 'int'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['title']]}],
                checks: [{attrs: [['author']], predicate: 'author > 0'}],
                doc: 'all posts',
                extra: {statement: 2, comment: 'an other entity'}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {statement: 2}},
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}], doc: 'standalone relation', extra: {statement: 3}},
            ],
            types: [
                {name: 'user_role', values: ['admin', 'guest'], extra: {statement: 1, line: 8}},
                {name: 'post_id', definition: 'int', doc: 'alias', extra: {statement: 4, line: 30}},
                {name: 'status', values: ['draft', 'published', 'archived'], extra: {statement: 5, line: 32}},
                {name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}], extra: {statement: 6, line: 34}},
                {name: 'range', definition: '(subtype = float8, subtype_diff = float8mi)', extra: {statement: 7, line: 36, comment: 'custom type'}},
            ]
        }
        const {extra, ...db} = parseAml(input).result || {}
        expect(db).toEqual(parsed)
        expect(generateAml(parsed)).toEqual(input.trim() + '\n')
    })
    test.skip('complex schema',  () => { // TODO: unskip
        const input = fs.readFileSync('./resources/complex.aml', 'utf8')
        const result = fs.readFileSync('./resources/complex.json', 'utf8')
        const parsed: Database = JSON.parse(result)
        const res = parseAml(input)
        // console.log('input', input)
        // console.log('result', result)
        console.log('res', JSON.stringify(res, null, 2))
        const {extra, ...db} = res.result || {}
        expect(db).toEqual(parsed)
        expect(generateAml(parsed)).toEqual(input.trim() + '\n')
    })
    test('empty schema',  () => {
        const input = ``
        const parsed: Database = {}
        const {extra, ...db} = parseAml(input).result || {}
        expect(db).toEqual(parsed)
        expect(generateAml(parsed)).toEqual(input)
    })
    test('bad schema', () => {
        expect(parseLegacyAml(`a bad schema`)).toEqual({
            result: {
                entities: [
                    {name: 'a', extra: {statement: 1}},
                    {name: 'bad', extra: {statement: 2}},
                    {name: 'schema', extra: {statement: 3}},
                ],
                extra: {}
            },
            errors: [
                {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'bad' <--", ...tokenPosition(2, 4, 1, 3, 1, 5)},
                {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'schema' <--", ...tokenPosition(6, 11, 1, 7, 1, 12)},
            ]
        })
    })

    // make sure the parser don't fail on invalid input
    describe('errors', () => {
        test('attribute relation', () => {
            expect(parseLegacyAml('posts\n  author int\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}}
            })
            expect(parseLegacyAml('posts\n  author int -\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Dash]\n  2. [LowerThan]\n  3. [GreaterThan]\nbut found: '\n'", ...tokenPosition(20, 20, 2, 15, 2, 15)}]
            })
            expect(parseLegacyAml('posts\n  author int ->\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", ...tokenPosition(21, 21, 2, 16, 2, 16)}]
            })
            expect(parseLegacyAml('posts\n  author int -> users\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                // TODO: an error should be reported here
            })
            expect(parseLegacyAml('posts\n  author int -> users(\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                errors: [{name: 'EarlyExitException', kind: 'error', message: "Expecting: expecting at least one iteration which starts with one of these possible Token sequences::\n  <[WhiteSpace] ,[Identifier]>\nbut found: '\n'", ...tokenPosition(28, 28, 2, 23, 2, 23)}]
            })
            expect(parseLegacyAml('posts\n  author int -> users(id\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {statement: 1}}], extra: {}},
                errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> RParen <-- but found --> '\n' <--", ...tokenPosition(30, 30, 2, 25, 2, 25)}]
            })
            expect(parseLegacyAml('posts\n  author int -> users(id)\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {statement: 1}}], extra: {}},
            })

            expect(parseLegacyAml('posts\n  author int - users(id)\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {statement: 1}}], extra: {}},
                errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Dash]\n  2. [LowerThan]\n  3. [GreaterThan]\nbut found: ' '", ...tokenPosition(20, 20, 2, 15, 2, 15)}]
            })
            expect(parseLegacyAml('posts\n  author int  users(id)\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}, {name: 'id', extra: {statement: 2}}], extra: {}},
                // TODO handle error better to not generate a fake entity (id)
                errors: [
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'users' <--", ...tokenPosition(20, 24, 2, 15, 2, 19)},
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> '(' <--", ...tokenPosition(25, 25, 2, 20, 2, 20)},
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> ')' <--", ...tokenPosition(28, 28, 2, 23, 2, 23)}
                ]
            })
        })
        test('attribute relation legacy', () => {
            expect(parseLegacyAml('posts\n  author int\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}}
            })
            expect(parseLegacyAml('posts\n  author int f\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}, {name: 'f', extra: {statement: 2}}], extra: {}},
                errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> NewLine <-- but found --> 'f' <--", ...tokenPosition(19, 19, 2, 14, 2, 14)}]
            })
            expect(parseLegacyAml('posts\n  author int fk\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                errors: [
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", ...tokenPosition(21, 21, 2, 16, 2, 16)},
                    {name: 'LegacyWarning', kind: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", ...tokenPosition(19, 20, 2, 14, 2, 15)}
                ]
            })
            expect(parseLegacyAml('posts\n  author int fk users\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                // TODO: an error should be reported here
                errors: [{name: 'LegacyWarning', kind: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", ...tokenPosition(19, 20, 2, 14, 2, 15)}]
            })
            expect(parseLegacyAml('posts\n  author int fk users.\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
                errors: [
                    {name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", ...tokenPosition(28, 28, 2, 23, 2, 23)},
                    {name: 'LegacyWarning', kind: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", ...tokenPosition(19, 20, 2, 14, 2, 15)}
                ]
            })
            expect(parseLegacyAml('posts\n  author int fk users.id\n')).toEqual({
                result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {statement: 1}}], extra: {}},
                errors: [{name: 'LegacyWarning', kind: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", ...tokenPosition(19, 20, 2, 14, 2, 15)}]
            })
        })
    })

    // make sure AML v1 is still correctly parsed, cf frontend/tests/DataSources/AmlMiner/AmlParserTest.elm
    describe('legacy', () => {
        test('basic', () => {
            expect(parseLegacyAml(`
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
                        extra: {statement: 1}
                    }, {
                        name: 'talks',
                        attrs: [
                            {name: 'id', type: 'int'},
                            {name: 'title', type: 'varchar(140)'},
                            {name: 'speaker', type: 'int'},
                        ],
                        extra: {statement: 2}
                    }],
                    relations: [
                        {src: {entity: 'talks'}, ref: {entity: 'users'}, attrs: [{src: ['speaker'], ref: ['id']}], extra: {statement: 2}}
                    ],
                    types: [
                        {name: 'user_role', values: ['admin', 'guest'], extra: {statement: 1, line: 5}}
                    ],
                    extra: {}
                },
                errors: [
                    {name: 'LegacyWarning', kind: 'warning', message: '"fk" is legacy, replace it with "->"', ...tokenPosition(117, 118, 10, 15, 10, 16)}
                ]
            })
        })
        test('complex', () => {
            expect(parseLegacyAml(`

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
  email varchar nullable fk emails.email

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
                        extra: {statement: 1}
                    }, {
                        schema: "public",
                        name: "users",
                        attrs: [
                            {name: 'id', type: 'int'},
                            {name: 'role', type: 'varchar', default: 'guest'},
                            {name: 'score', type: 'double precision', default: 0, doc: 'User progression', extra: {comment: 'a column with almost all possible attributes'}},
                            {name: 'first_name', type: 'varchar(10)'},
                            {name: 'last_name', type: 'varchar(10)'},
                            {name: 'email', type: 'varchar', null: true},
                        ],
                        pk: {attrs: [['id']]},
                        indexes: [{name: 'name', attrs: [['first_name'], ['last_name']], unique: true}, {attrs: [['score']]}],
                        doc: 'Table description',
                        extra: {statement: 2, comment: 'a table with everything!'}
                    }, {
                        name: 'admins',
                        kind: 'view',
                        attrs: [
                            {name: 'id', type: 'unknown'},
                            {name: 'name', type: 'unknown', doc: 'Computed from user first_name and last_name'},
                        ],
                        doc: 'View of `users` table with only admins',
                        extra: {statement: 3}
                    }],
                    relations: [
                        {src: {schema: 'public', entity: 'users'}, ref: {entity: 'emails'}, attrs: [{src: ['email'], ref: ['email']}], extra: {statement: 2}},
                        {src: {entity: 'admins'}, ref: {entity: 'users'}, attrs: [{src: ['id'], ref: ['id']}], extra: {statement: 4}},
                    ],
                    extra: {}
                },
                errors: [
                    {name: 'LegacyWarning', kind: 'warning', message: '"fk" is legacy, replace it with "->"', ...tokenPosition(435, 436, 14, 26, 14, 27)}
                ]
            })
        })
        test.skip('specific', () => {
            expect(parseLegacyAml(`
C##INVENTORY.USERS # identifier with '#'
  ID BIGINT PK # uppercase keyword
  FORMAT asset_format(1:1, 16:9) # : in enum
  OWNER cart_owner(identity.Devices, identity.Users) # . in enum
`)).toEqual({result: {
                    // TODO
                }})
        })
    })
})

function parseLegacyAml(aml: string): ParserResult<Database> {
    // remove db extra fields not relevant
    try {
        return parseAml(aml).map(({extra: {source, parsedAt, parsingMs, formattingMs, ...extra} = {}, ...db}) => ({...db, extra}))
    } catch (e) {
        console.error(e) // print stack trace
        throw e
    }
}

/*function printJson(json: any) {
    console.log(JSON.stringify(json)
        .replaceAll(/"([^" ]+)":/g, '$1:')
        .replaceAll(/:"([^" ]+)"/g, ":'$1'")
        .replaceAll(/\n/g, '\\n')
        .replaceAll(/,message:'([^"]*?)',position:/g, ',message:"$1",position:'))
}*/
