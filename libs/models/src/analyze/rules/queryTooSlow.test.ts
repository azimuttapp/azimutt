import {describe, expect, test} from "@jest/globals";
import {DatabaseQuery} from "../../interfaces/connector";
import {isQueryTooSlow, queryTooSlowRule} from "./queryTooSlow";
import {ruleConf} from "../rule.test";

describe('queryTooSlowRule', () => {
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
        expect(queryTooSlowRule.analyze({...ruleConf, maxMs: 100}, {}, [query]).map(v => v.message)).toEqual([
            'Query 123 on users is too slow (142 ms, SELECT * FROM users;).'
        ])
    })
})
