import {z} from "zod";
import {describe, expect, test} from "@jest/globals";
import {Entity, Relation} from "../database";
import {cleanJsonAnswer, cleanSqlAnswer, entityToPrompt} from "./llmUtils";

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
            {src: {entity: 'events', attrs: [['item_id']]}, ref: {entity: 'groups', attrs: [['id']]}, polymorphic: {attribute: ['item_type'], value: 'Group'}},
            {src: {entity: 'events', attrs: [['item_id']]}, ref: {entity: 'organizations', attrs: [['id']]}, polymorphic: {attribute: ['item_type'], value: 'Organization'}},
            {src: {entity: 'events', attrs: [['created_by']]}, ref: {entity: 'users', attrs: [['id']]}},
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
        expect(cleanSqlAnswer('SELECT * FROM users;')).toEqual('SELECT * FROM users;')
        expect(cleanSqlAnswer('```sql\nSELECT * FROM users;\n```')).toEqual('SELECT * FROM users;')
        expect(cleanSqlAnswer('```sql\n' +
            'SELECT name, email\n' +
            'FROM public.users\n' +
            'WHERE provider = \'github\'\n' +
            'ORDER BY name ASC;\n' +
            '```')).toEqual('SELECT name, email\n' +
            'FROM public.users\n' +
            'WHERE provider = \'github\'\n' +
            'ORDER BY name ASC;')
    })
    test('cleanJsonAnswer', async () => {
        const type = z.string().array()
        expect(await cleanJsonAnswer('[]', type)).toEqual([])
        expect(await cleanJsonAnswer('["bla", "bla"]', type)).toEqual(['bla', 'bla'])
        expect(await cleanJsonAnswer('```\n[]\n```', type)).toEqual([])
        expect(await cleanJsonAnswer('```json\n[]\n```', type)).toEqual([])
        await expect(cleanJsonAnswer('bla bla', type)).rejects.toEqual('Invalid JSON: bla bla')
        await expect(cleanJsonAnswer('[{}]', type)).rejects.toEqual("Invalid format at .0: expect 'string' but got 'object' ({})")
    })
})
