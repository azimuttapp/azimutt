import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generateAml, parseAml} from "./aml";

describe('aml', () => {
    test('sample schema', () => {
        const input = `
users |||
  list
  all users
|||
  id int pk # users primary key
  name varchar
  role user_role=guest
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
  id int pk
  title "varchar(100)" index | Title of the post
  author int check="author > 0" -> users(id)
  created_by int

rel posts(created_by) -> users(id)
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
                    {name: 'id', type: 'int'},
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
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}], extra: {statement: 3}},
            ]
        }
        const {extra, ...db} = parseAml(input).result || {}
        expect(db).toEqual(parsed)
        expect(generateAml(parsed)).toEqual(input.trim() + '\n')
    })
    test.skip('complex schema',  () => {
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
        expect(parseAml(`a bad schema`)).toEqual({errors: [{
            name: 'MismatchedTokenException',
            message: "Expecting token of type --> NewLine <-- but found --> 'bad' <--",
            position: {offset: [2, 4], line: [1, 1], column: [3, 5]}
        }]})
    })
})
