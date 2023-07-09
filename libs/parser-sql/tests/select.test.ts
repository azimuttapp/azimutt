import {describe, expect, test} from "@jest/globals";
import {parseSelect, parseSelectField, parseSelectJoin, parseSelectTable} from "../src/select";

describe('parseSelect', () => {
    test('basic fields', () => expect(parseSelect('SELECT id, name FROM users;')).toEqual({
        command: 'SELECT',
        fields: [{name: 'id'}, {name: 'name'}],
        tables: [{name: 'users'}]
    }))
    test('field alias', () => expect(parseSelect('SELECT id, name as username FROM users;')).toEqual({
        command: 'SELECT',
        fields: [{name: 'id'}, {name: 'username', expression: 'name'}],
        tables: [{name: 'users'}]
    }))
    test('wildcard', () => expect(parseSelect('SELECT * FROM public.users;')).toEqual({
        command: 'SELECT',
        fields: [{name: '*'}],
        tables: [{name: 'public.users'}]
    }))
    test('table alias', () => expect(parseSelect('SELECT u.id FROM public.users u;')).toEqual({
        command: 'SELECT',
        fields: [{name: 'id', scope: 'u'}],
        tables: [{name: 'u', alias: 'public.users'}]
    }))
    test('simple join', () => expect(parseSelect('SELECT u.id, e.id, o.id FROM users u JOIN events e ON u.id = e.created_by JOIN organizations o ON o.id = e.organization_id;')).toEqual({
        command: 'SELECT',
        fields: [{name: 'id', scope: 'u'}, {name: 'id', scope: 'e'}, {name: 'id', scope: 'o'}],
        tables: [
            {name: 'u', alias: 'users'},
            {name: 'e', alias: 'events', on: 'u.id = e.created_by'},
            {name: 'o', alias: 'organizations', on: 'o.id = e.organization_id'}
        ]
    }))
    test('join and wildcard', () => expect(parseSelect('SELECT u.*, e.id FROM users u JOIN events e ON u.id = e.created_by;')).toEqual({
        command: 'SELECT',
        fields: [{name: '*', scope: 'u'}, {name: 'id', scope: 'e'}],
        tables: [{name: 'u', alias: 'users'}, {name: 'e', alias: 'events', on: 'u.id = e.created_by'}]
    }))
    test('join and anonymous fields', () => expect(parseSelect('SELECT slug, project_id FROM users u JOIN events e ON u.id = e.created_by;')).toEqual({
        command: 'SELECT',
        fields: [{name: 'slug'}, {name: 'project_id'}],
        tables: [{name: 'u', alias: 'users'}, {name: 'e', alias: 'events', on: 'u.id = e.created_by'}]
    }))
    test('pagination', () => expect(parseSelect("SELECT id, name FROM users WHERE provider='github' ORDER BY id LIMIT 5 OFFSET 10;")).toEqual({
        command: 'SELECT',
        fields: [{name: 'id'}, {name: 'name'}],
        tables: [{name: 'users'}],
        where: "provider='github'",
        sort: 'id',
        limit: 5,
        offset: 10
    }))
    describe('parseSelectField', () => {
        test('field basic', () => expect(parseSelectField('id'))
            .toEqual({name: 'id'}))
        test('field with alias', () => expect(parseSelectField('id as user_id'))
            .toEqual({name: 'user_id', expression: 'id'}))
        test('field with scope', () => expect(parseSelectField('u.id'))
            .toEqual({name: 'id', scope: 'u'}))
        test('field with scope and alias', () => expect(parseSelectField('u.id as user_id'))
            .toEqual({name: 'user_id', expression: 'id', scope: 'u'}))
        test('expression field', () => expect(parseSelectField("count(distinct to_char(e.created_at, 'yyyy-mm-dd')) as active_days"))
            .toEqual({name: 'active_days', expression: "count(distinct to_char(e.created_at, 'yyyy-mm-dd'))"}))
    })
    describe('parseSelectTable', () => {
        test('table basic', () => expect(parseSelectTable('users'))
            .toEqual({name: 'users'}))
        test('table with schema', () => expect(parseSelectTable('public.users'))
            .toEqual({name: 'public.users'}))
        test('table with alias', () => expect(parseSelectTable('users u'))
            .toEqual({name: 'u', alias: 'users'}))
        test('table with schema and alias', () => expect(parseSelectTable('public.users u'))
            .toEqual({name: 'u', alias: 'public.users'}))
    })
    describe('parseSelectJoin', () => {
        test('join basic', () => expect(parseSelectJoin('events ON users.id = events.created_by'))
            .toEqual({name: 'events', on: 'users.id = events.created_by'}))
        test('join with alias', () => expect(parseSelectJoin('events e ON u.id = e.created_by'))
            .toEqual({name: 'e', alias: 'events', on: 'u.id = e.created_by'}))
    })
})
