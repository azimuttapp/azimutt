import {describe, expect, test} from "@jest/globals";
import {DatabaseQuery} from "../../interfaces/connector";
import {queryExpensiveRule} from "./queryExpensive";
import {ruleConf} from "../rule.test";

describe('queryExpensive', () => {
    const now = Date.now()
    test('violation message', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}}
        expect(queryExpensiveRule.analyze(ruleConf, now, {}, [query], [], []).map(v => v.message)).toEqual([
            'Query 123 on users is one of the most expensive, cumulated 543 ms exec time in 5 executions (SELECT * FROM users;)'
        ])
    })
    test('ignores', () => {
        const queries: DatabaseQuery[] = [
            {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}},
            {id: '456', database: 'azimutt_dev', query: 'SELECT * FROM events;', rows: 4321, exec: {count: 8, minTime: 1, maxTime: 15, sumTime: 253, meanTime: 12, sdTime: 6}},
        ]
        expect(queryExpensiveRule.analyze(ruleConf, now, {}, queries, [], []).map(v => v.message)).toEqual([
            'Query 123 on users is one of the most expensive, cumulated 543 ms exec time in 5 executions (SELECT * FROM users;)',
            'Query 456 on events is one of the most expensive, cumulated 253 ms exec time in 8 executions (SELECT * FROM events;)',
        ])
        expect(queryExpensiveRule.analyze({...ruleConf, ignores: ['456']}, now, {}, queries, [], []).map(v => v.message)).toEqual([
            'Query 123 on users is one of the most expensive, cumulated 543 ms exec time in 5 executions (SELECT * FROM users;)'
        ])
        expect(queryExpensiveRule.analyze(ruleConf, now, {}, queries, [], [{message: '', extra: {queryId: '456'}}]).map(v => v.message)).toEqual([
            'Query 123 on users is one of the most expensive, cumulated 543 ms exec time in 5 executions (SELECT * FROM users;)'
        ])
    })
})
