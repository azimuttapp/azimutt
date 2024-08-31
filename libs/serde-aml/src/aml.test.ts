import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generate, parse} from "./aml";

describe.skip('aml', () => {
    test('very basic schema', () => {
        const input = `
users
  id uuid pk
  name varchar
`
        expect(parse(input)).toEqual({result: {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}]}]}})
    })
    test('basic schema', () => {
        const input = `
users
  id integer pk
  name varchar

posts
  id integer pk
  title varchar | Title of the post
  author int -> users(id)
`
        const parsed: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'integer'},
                    {name: 'name', type: 'varchar'}
                ],
                pk: {attrs: [['id']]}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'integer'},
                    {name: 'title', type: 'varchar', doc: 'Title of the post'},
                    {name: 'author', type: 'integer'},
                ],
                pk: {attrs: [['id']]}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
            ],
            extra: {source: 'serde-AML'}
        }
        expect(parse(input)).toEqual({result: parsed})
        expect(generate(parsed)).toEqual(input)
    })
    test('complex schema',  () => {
        const source = fs.readFileSync('./resources/complex.aml', 'utf8')
        const parsed: Database = JSON.parse(fs.readFileSync('./resources/complex.json', 'utf8'))
        expect(parse(source).result).toEqual(parsed)
        expect(generate(parsed)).toEqual(source)
    })
    test('empty schema',  () => {
        const source = ``
        const parsed: Database = {extra: {source: 'serde-AML'}}
        expect(parse(source).result).toEqual(parsed)
        expect(generate(parsed)).toEqual(source)
    })
    test('bad schema',  () => {
        const source = `a bad schema`
        const error = [
            {message: "A Custom element shouldn't have a name", start: {line: 3, column: 15}, end: {line: 3, column: 17}}
        ]
        expect(parse(source).result).toEqual(error)
    })
    describe('entities', () => {
        // TODO
    })
})
