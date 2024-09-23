import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generateMermaid} from "./mermaidGenerator";

describe('mermaidGenerator', () => {
    test('empty', () => {
        expect(generateMermaid({})).toEqual('')
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
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
            ],
            stats: {
                name: 'Basic db'
            }
        }
        const sql = `---
title: Basic db
---
erDiagram
    users {
        int id PK
        varchar name
    }

    posts {
        uuid id PK
        varchar title
        text content "support markdown"
        int author FK
    }
    posts }o--|| users : author
`
        expect(generateMermaid(db)).toEqual(sql)
    })
})
