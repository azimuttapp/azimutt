import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {ModelExporter, Parser} from "@dbml/core";
import DbmlDatabase from "@dbml/core/types/model_structure/database";
import {Database} from "@azimutt/models";
import {generate, parse, reformat} from "./dbml";
import {JsonDatabase} from "./jsonDatabase";

describe('dbml', () => {
    test('basic schema',  () => {
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
            extra: {source: 'serde-DBML'}
        }
        expect(parse(source).result).toEqual(parsed)
        expect(parse(generated).result).toEqual(parsed)
        expect(generate(parsed)).toEqual(generated)
        expect(reformat(source)).toEqual(generated)
    })
    test('complex schema',  () => {
        const source = fs.readFileSync('./resources/complex.dbml', 'utf8')
        const generated = fs.readFileSync('./resources/complex.generated.dbml', 'utf8')
        const parsed: Database = JSON.parse(fs.readFileSync('./resources/complex.json', 'utf8'))
        expect(parse(source).result).toEqual(parsed)
        // expect(parse(generated).result).toEqual(parsed) // `alias` and index `notes` are not preserved by DBML lib :/
        // expect(generate(parsed)).toEqual(generated) // `tableGroups` make JSON parser fail :/
        expect(reformat(source)).toEqual(generated)
    })
    test('empty schema',  () => {
        const source = ``
        const generated = ``
        const parsed: Database = {extra: {source: 'serde-DBML'}}
        expect(parse(source).result).toEqual(parsed)
        expect(parse(generated).result).toEqual(parsed)
        expect(generate(parsed)).toEqual(generated)
        expect(reformat(source)).toEqual(generated)
    })
    test('bad schema',  () => {
        const source = `
            users
              id uuid
            `
        const error = [
            {name: 'DBMLException-1005', message: "Expect an opening brace '{' or a colon ':'", position: {offset: [0, 0], line: [3, 3], column: [18, 22]}},
            {name: 'DBMLException-3057', message: "A custom element can only appear in a Project", position: {offset: [0, 0], line: [2, 3], column: [13, 17]}},
            {name: 'DBMLException-3001', message: "A Custom element shouldn't have a name", position: {offset: [0, 0], line: [3, 3], column: [15, 17]}}
        ]
        expect(parse(source).errors).toEqual(error)
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
