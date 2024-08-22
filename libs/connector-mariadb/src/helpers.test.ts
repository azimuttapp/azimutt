import {describe, expect, test} from "@jest/globals";
import {buildSqlColumn, buildSqlTable, scopeWhere} from "./helpers";

describe('helpers', () => {
    test('buildSqlTable', () => {
        expect(buildSqlTable({entity: 'events'})).toEqual("`events`")
        expect(buildSqlTable({schema: '', entity: 'events'})).toEqual("`events`")
        expect(buildSqlTable({schema: 'public', entity: 'events'})).toEqual("`public`.`events`")
    })
    test('buildSqlColumn', () => {
        expect(buildSqlColumn(['name'])).toEqual("`name`")
        expect(buildSqlColumn(['data', 'email'])).toEqual("JSON_VALUE(`data`, '$.email')")
    })
    test('scopeWhere', () => {
        const opts = {}
        expect(scopeWhere({}, opts)).toEqual(``)
        expect(scopeWhere({schema: 't.owner'}, opts)).toEqual(`t.owner NOT IN ('information_schema', 'performance_schema', 'sys', 'sky', 'mysql')`)
        expect(scopeWhere({schema: 't.owner'}, {...opts, schema: 'public'})).toEqual(`t.owner = 'public'`)
        expect(scopeWhere({schema: 't.owner'}, {...opts, schema: '!public'})).toEqual(`t.owner != 'public'`)
        expect(scopeWhere({schema: 't.owner'}, {...opts, schema: 'p_%'})).toEqual(`t.owner LIKE 'p_%'`)
        expect(scopeWhere({schema: 't.owner'}, {...opts, schema: '!p_%'})).toEqual(`t.owner NOT LIKE 'p_%'`)
        expect(scopeWhere({schema: 't.owner'}, {...opts, schema: 'wp', entity: 'wp_%'})).toEqual(`t.owner = 'wp'`)
        expect(scopeWhere({schema: 't.owner', entity: 't.name'}, {...opts, schema: 'wp', entity: 'wp_%'})).toEqual(`t.owner = 'wp' AND t.name LIKE 'wp_%'`)
    })
})
