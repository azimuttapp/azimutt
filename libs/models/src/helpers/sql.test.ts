import {describe, expect, test} from "@jest/globals";
import {formatSql, getMainEntity} from "./sql";

describe('sql', () => {
    test('getMainEntity', () => {
        expect(getMainEntity('bad')).toEqual(undefined)
        expect(getMainEntity('SELECT * FROM users;')).toEqual({entity: 'users'})
        expect(getMainEntity('SELECT * FROM public.users;')).toEqual({schema: 'public', entity: 'users'})
        expect(getMainEntity('SELECT * FROM "public"."users";')).toEqual({schema: 'public', entity: 'users'})
    })
    test('formatSql', () => {
        expect(formatSql('SELECT * FROM users;')).toEqual('SELECT * FROM users;')
        expect(formatSql('SELECT *\nFROM users\nWHERE id=1;')).toEqual('SELECT * FROM users WHERE id=1;')
        expect(formatSql('SELECT id\n     , name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT id,\n       name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT id, name      as n FROM users;')).toEqual('SELECT id, name as n FROM users;')
        expect(formatSql('SELECT id -- the id\n     , name\nFROM users;')).toEqual('SELECT id, name FROM users;')
        expect(formatSql('SELECT e.id as event_id, e.details as event_details, u.email as email FROM events e JOIN users u ON e.created_by = u.id WHERE u.email="loicknuchel@gmail.com";'))
            .toEqual('SELECT e.id as event_id, e.details as event_... FROM events e JOIN users u ON e.created_by = u.id WHERE u.email="loicknuchel@gm...')
    })
})
