import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generate, parse} from "./aml";

describe('aml', () => {
    test('basic schema', () => {
        const input = `
users
  id int pk
  name varchar

posts | all posts
  id int pk
  title varchar | Title of the post
  author int -> users(id)
`
        const parsed: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'}
                ],
                pk: {attrs: [['id']]},
                extra: {statement: 1}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar', doc: 'Title of the post'},
                    {name: 'author', type: 'int'},
                ],
                pk: {attrs: [['id']]},
                doc: 'all posts',
                extra: {statement: 2}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {statement: 2}}
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
