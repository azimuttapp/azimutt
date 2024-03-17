import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/database-model";
import {generate, parse} from "../src/aml";

describe.skip('aml', () => {
    test('basic schema', async () => {
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
                columns: [
                    {name: 'id', type: 'integer'},
                    {name: 'name', type: 'varchar'}
                ],
                primaryKey: {columns: ['id']}
            }, {
                name: 'posts',
                columns: [
                    {name: 'id', type: 'integer'},
                    {name: 'title', type: 'varchar', doc: 'Title of the post'},
                    {name: 'author', type: 'integer'},
                ],
                primaryKey: {columns: ['id']}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, columns: [{src: 'author', ref: 'id'}]}
            ],
            extra: {source: 'serde-AML'}
        }
        await expect(parse(source)).resolves.toEqual(parsed)
        await expect(generate(parsed)).resolves.toEqual(source)
    })
    test('complex schema',  async () => {
        const source = fs.readFileSync('./tests/resources/complex.aml', 'utf8')
        const parsed: Database = JSON.parse(fs.readFileSync('./tests/resources/complex.json', 'utf8'))
        await expect(parse(source)).resolves.toEqual(parsed)
        await expect(generate(parsed)).resolves.toEqual(source)
    })
    test('empty schema',  async () => {
        const source = ``
        const parsed: Database = {extra: {source: 'serde-AML'}}
        await expect(parse(source)).resolves.toEqual(parsed)
        await expect(generate(parsed)).resolves.toEqual(source)
    })
    test('bad schema',  async () => {
        const source = `a bad schema`
        const error = [
            {message: "A Custom element shouldn't have a name", start: {line: 3, column: 15}, end: {line: 3, column: 17}}
        ]
        await expect(parse(source)).rejects.toEqual(error)
    })
    describe('entities', () => {
        // TODO
    })
})
