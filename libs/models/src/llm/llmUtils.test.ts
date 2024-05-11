import {describe, expect, test} from "@jest/globals";
import {Entity, Relation} from "../database";
import {cleanSqlAnswer, entityToPrompt} from "./llmUtils";

describe('llmUtils', () => {
    test('entityToPrompt', () => {
        const entity: Entity = {
            name: 'events',
            attrs: [
                {name: 'id', type: 'uuid'},
                {name: 'name', type: 'varchar'},
                {name: 'item_type', type: 'varchar'},
                {name: 'item_id', type: 'uuid'},
                {name: 'created_by', type: 'uuid'},
            ]
        }
        const relations: Relation[] = [
            {src: {entity: 'events'}, ref: {entity: 'groups'}, attrs: [{src: ['item_id'], ref: ['id']}], polymorphic: {attribute: ['item_type'], value: 'Group'}},
            {src: {entity: 'events'}, ref: {entity: 'organizations'}, attrs: [{src: ['item_id'], ref: ['id']}], polymorphic: {attribute: ['item_type'], value: 'Organization'}},
            {src: {entity: 'events'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]},
        ]
        const attributes = [
            'id uuid',
            'name varchar',
            'item_type varchar',
            'item_id uuid',
            'created_by uuid REFERENCES users(id)',
            'FOREIGN KEY (item_id) REFERENCES groups(id)',
            'FOREIGN KEY (item_id) REFERENCES organizations(id)',
        ]
        expect(entityToPrompt(entity, relations)).toEqual(`CREATE TABLE events (${attributes.join(', ')});`)
    })
    test('cleanSqlAnswer', () => {
        expect(cleanSqlAnswer('SELECT * FROM users;')).toBe('SELECT * FROM users;')
        expect(cleanSqlAnswer('```sql\nSELECT * FROM users;\n```')).toBe('SELECT * FROM users;')
        expect(cleanSqlAnswer('```sql\n' +
            'SELECT name, email\n' +
            'FROM public.users\n' +
            'WHERE provider = \'github\'\n' +
            'ORDER BY name ASC;\n' +
            '```')).toBe('SELECT name, email\n' +
            'FROM public.users\n' +
            'WHERE provider = \'github\'\n' +
            'ORDER BY name ASC;')
    })
})
