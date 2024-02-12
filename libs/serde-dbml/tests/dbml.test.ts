import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/database-model";
import {generate, parse, reformat} from "../src/dbml";

describe('dbml', () => {
    test('basic schema',  async () => {
        const source = `
            Table users {
              id integer [primary key]
              name varchar
            }

            Table posts {
              id integer [primary key]
              title varchar [note: 'Title of the post']
              author integer
            }

            Ref: posts.author > users.id`
        const generated = `Table "users" {
  "id" integer [pk]
  "name" varchar
}

Table "posts" {
  "id" integer [pk]
  "title" varchar [note: 'Title of the post']
  "author" integer
}

Ref:"users"."id" < "posts"."author"
`
        const parsed: Database = {
            tables: [{
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
                    {name: 'title', type: 'varchar', comment: 'Title of the post'},
                    {name: 'author', type: 'integer'},
                ],
                primaryKey: {columns: ['id']}
            }],
            relations: [
                {src: {table: 'posts'}, ref: {table: 'users'}, columns: [{src: 'author', ref: 'id'}]}
            ],
            extensions: {source: 'serde-DBML'}
        }
        await expect(parse(source)).resolves.toEqual(parsed)
        await expect(parse(generated)).resolves.toEqual(parsed)
        await expect(generate(parsed)).resolves.toEqual(generated)
        await expect(reformat(source)).resolves.toEqual(generated)
    })
    test('complex schema',  async () => {
        const source = fs.readFileSync('./tests/resources/complex.dbml', 'utf8')
        const generated = fs.readFileSync('./tests/resources/complex.generated.dbml', 'utf8')
        const parsed: Database = JSON.parse(fs.readFileSync('./tests/resources/complex.json', 'utf8'))
        await expect(parse(source)).resolves.toEqual(parsed)
        // await expect(parse(generated)).resolves.toEqual(parsed) // `alias` and index `notes` are not preserved by DBML lib :/
        // await expect(generate(parsed)).resolves.toEqual(generated) // `tableGroups` make JSON parser fail :/
        await expect(reformat(source)).resolves.toEqual(generated)
    })
    test('empty schema',  async () => {
        const source = ``
        const generated = ``
        const parsed: Database = {extensions: {source: 'serde-DBML'}}
        await expect(parse(source)).resolves.toEqual(parsed)
        await expect(parse(generated)).resolves.toEqual(parsed)
        await expect(generate(parsed)).resolves.toEqual(generated)
        await expect(reformat(source)).resolves.toEqual(generated)
    })
    test('bad schema',  async () => {
        const source = `
            users
              id uuid
            `
        const error = [
            {message: "Expect an opening brace '{' or a colon ':'", start: {line: 3, column: 18}, end: {line: 3, column: 22}},
            {message: "A custom element can only appear in a Project", start: {line: 2, column: 13}, end: {line: 3, column: 17}},
            {message: "A Custom element shouldn't have a name", start: {line: 3, column: 15}, end: {line: 3, column: 17}}
        ]
        await expect(parse(source)).rejects.toEqual(error)
    })
})
