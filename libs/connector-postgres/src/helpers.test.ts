import {describe, expect, test} from "@jest/globals";
import {buildSqlColumn, buildSqlTable, scopeWhere} from "./helpers";

describe('helpers', () => {
    test('buildSqlTable', () => {
        expect(buildSqlTable({entity: 'events'})).toEqual(`"events"`)
        expect(buildSqlTable({schema: '', entity: 'events'})).toEqual(`"events"`)
        expect(buildSqlTable({schema: 'public', entity: 'events'})).toEqual(`"public"."events"`)
    })
    test('buildSqlColumn', () => {
        expect(buildSqlColumn(['name'])).toEqual(`"name"`)
        expect(buildSqlColumn(['data', 'email'])).toEqual(`"data"->'email'`)
    })
    test('scopeWhere', () => {
        expect(scopeWhere({}, {})).toEqual(``)
        expect(scopeWhere({schema: 't.schema'}, {})).toEqual(`t.schema NOT IN ('information_schema', 'pg_catalog')`)
        expect(scopeWhere({schema: 't.schema'}, {schema: 'public'})).toEqual(`t.schema = 'public'`)
        expect(scopeWhere({schema: 't.schema'}, {schema: '!public'})).toEqual(`t.schema != 'public'`)
        expect(scopeWhere({schema: 't.schema'}, {schema: 'p_%'})).toEqual(`t.schema LIKE 'p_%'`)
        expect(scopeWhere({schema: 't.schema'}, {schema: '!p_%'})).toEqual(`t.schema NOT LIKE 'p_%'`)
        expect(scopeWhere({schema: 't.schema'}, {schema: 'wp', entity: 'wp_%'})).toEqual(`t.schema = 'wp'`)
        expect(scopeWhere({schema: 't.schema', entity: 't.name'}, {schema: 'wp', entity: 'wp_%'})).toEqual(`t.schema = 'wp' AND t.name LIKE 'wp_%'`)
    })
})
