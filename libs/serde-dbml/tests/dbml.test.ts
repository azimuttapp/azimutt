import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {ModelExporter, Parser} from "@dbml/core";
import DbmlDatabase from "@dbml/core/types/model_structure/database";
import {Database} from "@azimutt/database-model";
import {generate, parse, reformat} from "../src/dbml";
import {JsonDatabase} from "../src/jsonDatabase";

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
                    {name: 'title', type: 'varchar', comment: 'Title of the post'},
                    {name: 'author', type: 'integer'},
                ],
                primaryKey: {columns: ['id']}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, columns: [{src: 'author', ref: 'id'}]}
            ],
            extra: {source: 'serde-DBML'}
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
        const parsed: Database = {extra: {source: 'serde-DBML'}}
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
    test.skip('test',   () => {
        const source = `Table users {
  id integer [primary key]
  name varchar
}

enum demo.job_status {
    created [note: 'Waiting to be processed']
    running
    done
    failure
}
`
        const db: DbmlDatabase = (new Parser(undefined)).parse(source, 'dbmlv2')
        const json = ModelExporter.export(db, 'json', false)
        const jsonDb: JsonDatabase = JSON.parse(json)
        console.log('json', jsonDb)

        // JSON parser fails with tableGroups :/
        const db2: DbmlDatabase = (new Parser(undefined)).parse(json, 'json')
        const res = ModelExporter.export(db2, 'dbml', false)
        console.log('res', res)
    })
    test.skip('https://github.com/holistics/dbml/issues/514',  () => {
        const content = `Table users {
                id integer
                username varchar
                role varchar
                created_at timestamp
            }

            Table posts {
                id integer [primary key]
                title varchar
                body text [note: 'Content of the post']
                user_id integer
                created_at timestamp
            }

            Ref: posts.user_id > users.id // many-to-one
        `
        const dbFromDbml = (new Parser(undefined)).parse(content, 'dbmlv2')
        const json: string = ModelExporter.export(dbFromDbml, 'json', false)
        console.log('json', json)
        const dbFromJson = (new Parser(undefined)).parse(json, 'json')
        console.log('json parsed!')
        const generated = ModelExporter.export(dbFromJson, 'dbml', false)
        console.log('dbml generated', generated)
    })
})
