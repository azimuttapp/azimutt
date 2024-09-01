import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generate, parse} from "./aml";

describe('aml', () => {
    test('sample schema', () => {
        const input = `
users
  id int pk
  name varchar
  settings json
    address json
      number number
      street string
      city string index=address
      country string index=address
    github string
    twitter string

posts | all posts
  id int pk
  title varchar index | Title of the post
  author int check="author > 0" -> users(id)
  created_by int

rel posts(created_by) -> users(id)
`
        const parsed: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                    {name: 'settings', type: 'json', attrs: [
                        {name: 'address', type: 'json', attrs: [
                            {name: 'number', type: 'number'},
                            {name: 'street', type: 'string'},
                            {name: 'city', type: 'string'},
                            {name: 'country', type: 'string'},
                        ]},
                        {name: 'github', type: 'string'},
                        {name: 'twitter', type: 'string'},
                    ]},
                ],
                pk: {attrs: [['id']]},
                indexes: [{name: 'address', attrs: [['settings', 'address', 'city'], ['settings', 'address', 'country']]}],
                extra: {statement: 1}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar', doc: 'Title of the post'},
                    {name: 'author', type: 'int'},
                    {name: 'created_by', type: 'int'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['title']]}],
                checks: [{attrs: [['author']], predicate: 'author > 0'}],
                doc: 'all posts',
                extra: {statement: 2}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {statement: 2}},
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}], extra: {statement: 3}},
            ]
        }
        const {extra, ...db} = parse(input).result || {}
        expect(db).toEqual(parsed)
        expect(generate(parsed)).toEqual(input.trim() + '\n')
    })
    test.skip('complex schema',  () => {
        const input = fs.readFileSync('./resources/complex.aml', 'utf8')
        const result = fs.readFileSync('./resources/complex.json', 'utf8')
        const parsed: Database = JSON.parse(result)
        const res = parse(input)
        // console.log('input', input)
        // console.log('result', result)
        console.log('res', JSON.stringify(res, null, 2))
        const {extra, ...db} = res.result || {}
        expect(db).toEqual(parsed)
        expect(generate(parsed)).toEqual(input.trim() + '\n')
    })
    test('empty schema',  () => {
        const input = ``
        const parsed: Database = {}
        const {extra, ...db} = parse(input).result || {}
        expect(db).toEqual(parsed)
        expect(generate(parsed)).toEqual(input)
    })
    test('bad schema', () => {
        expect(parse(`a bad schema`)).toEqual({errors: [{
            name: 'MismatchedTokenException',
            message: "Expecting token of type --> NewLine <-- but found --> 'bad' <--",
            position: {offset: [2, 4], line: [1, 1], column: [3, 5]}
        }]})
    })
    describe('entities', () => {
        // TODO
    })
})
