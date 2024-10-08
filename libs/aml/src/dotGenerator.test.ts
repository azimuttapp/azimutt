import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, parseJsonDatabase} from "@azimutt/models";
import {generateDot} from "./dotGenerator";

describe('dotGenerator', () => {
    test('empty', () => {
        expect(generateDot({})).toEqual('digraph {\n    node [shape=none, margin=0]\n}\n')
    })
    test('basic', () => {
        const db: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                ],
                pk: {attrs: [['id']]}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'uuid'},
                    {name: 'title', type: 'varchar'},
                    {name: 'content', type: 'text', doc: 'support markdown'},
                    {name: 'author', type: 'int'},
                ],
                pk: {attrs: [['id']]}
            }],
            relations: [
                {src: {entity: 'posts', attrs: [['author']]}, ref: {entity: 'users', attrs: [['id']]}}
            ],
            stats: {
                name: 'Basic db'
            }
        }
        const sql = `digraph "Basic db" {
    label = "Basic db"
    node [shape=none, margin=0]

    users [label=<
        <table border="0" cellborder="1" cellspacing="0" cellpadding="4">
            <tr><td bgcolor="lightblue" colspan="3">users</td></tr>
            <tr><td align="left">id</td><td align="left">int</td><td align="left">pk</td></tr>
            <tr><td align="left">name</td><td align="left">varchar</td><td align="left"></td></tr>
        </table>
    >]

    posts [label=<
        <table border="0" cellborder="1" cellspacing="0" cellpadding="4">
            <tr><td bgcolor="lightblue" colspan="3">posts</td></tr>
            <tr><td align="left">id</td><td align="left">uuid</td><td align="left">pk</td></tr>
            <tr><td align="left">title</td><td align="left">varchar</td><td align="left"></td></tr>
            <tr><td align="left">content</td><td align="left">text</td><td align="left">doc: support markdown</td></tr>
            <tr><td align="left">author</td><td align="left">int</td><td align="left">fk</td></tr>
        </table>
    >]
    posts -> users [label=author]
}
`
        expect(generateDot(db)).toEqual(sql)
    })
    test('full', () => {
        const db: Database = parseJsonDatabase(fs.readFileSync('./resources/full.json', 'utf8')).result || {}
        const dot = fs.readFileSync('./resources/full.dot', 'utf8')
        // const parsed = parseMermaid(dot)
        // expect(parsed).toEqual({result: db})
        expect(generateDot(db, {doc: false})).toEqual(dot)
    })
})
