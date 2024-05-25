import {describe, expect, test} from "@jest/globals";
import {DatabaseQuery} from "../../interfaces/connector";
import {isQueryTooSlow, queryTooSlowRule} from "./queryTooSlow";
import {ruleConf} from "../rule.test";

describe('queryTooSlow', () => {
    const now = Date.now()
    test('quick query', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 42, sdTime: 30}}
        expect(isQueryTooSlow(query, 100)).toEqual(false)
    })
    test('slow query', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}}
        expect(isQueryTooSlow(query, 100)).toEqual(true)
    })
    test('violation message', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}}
        expect(queryTooSlowRule.analyze({...ruleConf, maxMs: 100}, now, {}, [query], []).map(v => v.message)).toEqual([
            'Query 123 on users is too slow (142 ms, SELECT * FROM users;).'
        ])
    })
    test('ignores', () => {
        const queries: DatabaseQuery[] = [
            {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 1452, sdTime: 60}},
            {id: '456', database: 'azimutt_dev', query: 'SELECT * FROM events;', rows: 4321, exec: {count: 8, minTime: 1, maxTime: 15, sumTime: 253, meanTime: 1212, sdTime: 6}},
        ]
        expect(queryTooSlowRule.analyze({...ruleConf, maxMs: 100}, now, {}, queries, []).map(v => v.message)).toEqual([
            'Query 123 on users is too slow (1452 ms, SELECT * FROM users;).',
            'Query 456 on events is too slow (1212 ms, SELECT * FROM events;).',
        ])
        expect(queryTooSlowRule.analyze({...ruleConf, maxMs: 100, ignores: ['456']}, now, {}, queries, []).map(v => v.message)).toEqual([
            'Query 123 on users is too slow (1452 ms, SELECT * FROM users;).',
        ])
    })
})
