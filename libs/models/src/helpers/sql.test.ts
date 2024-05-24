import {describe, expect, test} from "@jest/globals";
import {formatSql, getEntities, getMainEntity} from "./sql";

describe('sql', () => {
    test('getMainEntity', () => {
        expect(getMainEntity('bad')).toEqual(undefined)
        expect(getMainEntity('select * from users;')).toEqual({entity: 'users'})
        expect(getMainEntity('SELECT * FROM users;')).toEqual({entity: 'users'})
        expect(getMainEntity('SELECT * FROM public.users;')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM "public"."users";')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity("SELECT * FROM 'public'.'users';")).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM `public`.`users`;')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM [public].[users];')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity("INSERT INTO users (id, name) VALUES (1, 'Loïc');")).toEqual({entity: 'users'})
        expect(getMainEntity("UPDATE users SET name='Loïc' WHERE id=1;")).toEqual({entity: 'users'})
        expect(getMainEntity("DELETE FROM users WHERE id=1;")).toEqual({entity: 'users'})
    })
    test('getEntities', () => {
        expect(getEntities('bad')).toEqual([])
        expect(getEntities('SELECT * FROM users;')).toEqual([{entity: 'users'}])
        expect(getEntities('SELECT * FROM events e JOIN users u ON e.created_by = u.id;')).toEqual([{entity: 'events'}, {entity: 'users'}])
        expect(getEntities(`
            SELECT *
            FROM events e
                     JOIN users u ON e.created_by = u.id
                     JOIN organizations o ON e.organization_id = o.id
            WHERE e.name = 'plan_limit';`)).toEqual([{entity: 'events'}, {entity: 'users'}, {entity: 'organizations'}])
        expect(getEntities("INSERT INTO users (id, name) VALUES (1, 'Loïc');")).toEqual([{entity: 'users'}])
        expect(getEntities("UPDATE users SET name='Loïc' WHERE id=1;")).toEqual([{entity: 'users'}])
        expect(getEntities("DELETE FROM users WHERE id=1;")).toEqual([{entity: 'users'}])
    })
    test('formatSql', () => {
        expect(formatSql('SELECT * FROM users;')).toEqual('SELECT * FROM users;')
        expect(formatSql('SELECT *\nFROM users\nWHERE id=1;')).toEqual('SELECT * FROM users WHERE id=1;')
        expect(formatSql('SELECT id\n     , name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT id,\n       name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT id, name      as n FROM users;')).toEqual('SELECT id, name as n FROM users;')
        expect(formatSql('SELECT id -- the id\n     , name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT e.id as event_id, e.details as event_details, u.email as email FROM events e JOIN users u ON u.id = e.created_by LEFT JOIN organizations o ON o.id = e.organization_id WHERE e.name="plan_limit" AND u.email="loicknuchel@gmail.com";'))
            .toEqual('SELECT e.id as event_id, e.details as event_... FROM events e JOIN users u ON u.id = e.created_by LEFT JOIN organizations o ON o.id = e.organization_id WHERE e.name="plan_limit" AND u.email="loickn...')
    })
})
