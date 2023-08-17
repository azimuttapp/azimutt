import {describe, expect, test} from "@jest/globals";
import {buildSqlColumn, buildSqlTable} from "../src/helpers";

describe('helpers', () => {
    test('buildSqlTable', async () => {
        expect(buildSqlTable('', 'events')).toEqual('events')
        expect(buildSqlTable('public', 'events')).toEqual('public.events')
        expect(buildSqlTable('public', 'Event')).toEqual('public."Event"')
    })
    test('buildSqlColumn', async () => {
        expect(buildSqlColumn('name')).toEqual("'name'")
    })
})
