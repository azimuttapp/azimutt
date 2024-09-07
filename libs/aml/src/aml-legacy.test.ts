import {describe, expect, test} from "@jest/globals";
import {parseAml} from "./aml";
import {Database, ParserResult} from "@azimutt/models";

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
            warnings: [
                {name: 'warning', message: '"fk" is legacy, replace it with "->"', position: {offset: [117, 118], line: [10, 10], column: [15, 16]}}
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
            warnings: [
                {name: 'warning', message: '"fk" is legacy, replace it with "->"', position: {offset: [435, 436], line: [14, 14], column: [26, 27]}}
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

function parseLegacyAml(aml: string): ParserResult<Database> {
    // remove db extra fields not relevant
    try {
        return parseAml(aml).map(({extra: {source, parsedAt, parsingMs, formattingMs, ...extra} = {}, ...db}) => ({...db, extra}))
    } catch (e) {
        console.error(e) // print stack trace
        throw e
    }
}
