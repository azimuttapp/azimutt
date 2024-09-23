import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, parseJsonDatabase} from "@azimutt/models";
import {generateMarkdown} from "./markdownGenerator";

describe('markdownGenerator', () => {
    test('empty', () => {
        expect(generateMarkdown({})).toEqual(`# Database documentation by Azimutt

## Summary

- [Entities](#entities)
- [Types](#types)
- [Diagram](#diagram)

## Entities

No defined entities

## Types

No custom types

## Diagram

\`\`\`mermaid
erDiagram
\`\`\`
`)
    })
    test('basic', () => {
        const db: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                    {name: 'role', type: 'user_role'},
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
                pk: {attrs: [['id']]},
                doc: "All posts"
            }, {
                name: 'admins',
                kind: 'view',
                def: "SELECT * FROM users WHERE role = 'admin'"
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
            ],
            types: [
                {name: 'user_role', values: ['admin', 'guest']}
            ],
            stats: {
                name: 'Basic db'
            }
        }
        const sql = `# Basic db

## Summary

- [Entities](#entities)
  - [users](#users)
  - [posts](#posts)
  - [admins](#admins)
- [Types](#types)
  - [user_role](#user_role)
- [Diagram](#diagram)

## Entities

### users

| Attribute | Type      | Properties | Reference | Documentation |
|-----------|-----------|------------|-----------|---------------|
| **id**    | int       | PK         |           |               |
| **name**  | varchar   |            |           |               |
| **role**  | user_role |            |           |               |

### posts

All posts

| Attribute   | Type    | Properties | Reference | Documentation    |
|-------------|---------|------------|-----------|------------------|
| **id**      | uuid    | PK         |           |                  |
| **title**   | varchar |            |           |                  |
| **content** | text    |            |           | support markdown |
| **author**  | int     |            | users.id  |                  |

### admins

View definition:
\`\`\`sql
SELECT * FROM users WHERE role = 'admin'
\`\`\`

## Types

### user_role

ENUM: admin, guest

## Diagram

\`\`\`mermaid
---
title: Basic db
---
erDiagram
    users {
        int id PK
        varchar name
        user_role role
    }

    posts {
        uuid id PK
        varchar title
        text content "support markdown"
        int author FK
    }
    posts }o--|| users : author

    admins
\`\`\`
`
        expect(generateMarkdown(db)).toEqual(sql)
    })
    test('full', () => {
        const db: Database = parseJsonDatabase(fs.readFileSync('./resources/full.json', 'utf8')).result || {}
        const markdown = fs.readFileSync('./resources/full.md', 'utf8')
        // const parsed = parseMarkdown(markdown)
        // expect(parsed).toEqual({result: db})
        expect(generateMarkdown(db)).toEqual(markdown)
    })
})
