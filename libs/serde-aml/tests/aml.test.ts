import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generate, parse} from "../src/aml";

describe.skip('aml', () => {
    test('basic schema', () => {
        const source = `
            users
              id integer pk
              name varchar

            posts
              id integer pk
              title varchar | Title of the post
              author int fk users.id`
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
        expect(parse(source).result).toEqual(parsed)
        expect(generate(parsed)).toEqual(source)
    })
    test('complex schema',  () => {
        const source = fs.readFileSync('./tests/resources/complex.aml', 'utf8')
        const parsed: Database = JSON.parse(fs.readFileSync('./tests/resources/complex.json', 'utf8'))
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
