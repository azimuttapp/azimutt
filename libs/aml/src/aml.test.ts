import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generateAml, parseAml} from "./aml";

describe('aml', () => {
    // TODO: add comment only lines
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

posts | all posts # an other entity
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
        expect(parseAml(`a bad schema`)).toEqual({errors: [
            {name: 'MismatchedTokenException', message: "Expecting token of type --> NewLine <-- but found --> 'bad' <--", position: {offset: [2, 4], line: [1, 1], column: [3, 5]}},
            {name: 'MismatchedTokenException', message: "Expecting token of type --> NewLine <-- but found --> 'schema' <--", position: {offset: [6, 11], line: [1, 1], column: [7, 12]}},
        ]})
    })
})
