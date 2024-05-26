import {describe, expect, test} from "@jest/globals";
import {oneDay} from "../../helpers/date";
import {DatabaseQuery} from "../../interfaces/connector";
import {getDegradingQuery, queryDegradingRule} from "./queryDegrading";
import {ruleConf} from "../rule.test";

describe('queryDegrading', () => {
    const now = 1716654244967
    const twoDaysAgo = now - (2 * oneDay)
    const report = 'report_2024-05-25T16-24-04-967Z.azimutt.json'
    test('constant query', () => {
        const current: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 42, sdTime: 30}}
        const previous: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 40, sdTime: 30}}
        expect(getDegradingQuery(now, current, [], 5, 1, 0.2, 0.1)).toEqual(undefined)
        expect(getDegradingQuery(now, current, [{report, date: twoDaysAgo, query: previous}], 5, 1, 0.2, 0.1)).toEqual(undefined)
    })
    test('degrading query', () => {
        const current: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 20, sdTime: 30}}
        const previous: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 10, sdTime: 30}}
        expect(getDegradingQuery(now, current, [{report, date: twoDaysAgo, query: previous}], 5, 1, 0.2, 0.1)).toEqual({report, date: twoDaysAgo, previous, current, degradation: 1, duration: 2 * oneDay, monthly: 15, daily: 0.5})
    })
    test('violation message', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 20, sdTime: 30}}
        const previous: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 100, sumTime: 243, meanTime: 10, sdTime: 30}}
        expect(queryDegradingRule.analyze({...ruleConf, minExec: 5, maxDegradation: 1, maxDegradationMonthly: 0.2, maxDegradationDaily: 0.1}, now, {}, [query], [{report, date: twoDaysAgo, database: {}, queries: [previous]}]).map(v => v.message)).toEqual([
            'Query 123 on users degraded mean exec time by 100% since 2024-05-23 (50% daily, SELECT * FROM users;).'
        ])
    })
    test('ignores', () => {
        const queries: DatabaseQuery[] = [
            {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 1452, sdTime: 60}},
            {id: '456', database: 'azimutt_dev', query: 'SELECT * FROM events;', rows: 4321, exec: {count: 8, minTime: 1, maxTime: 15, sumTime: 253, meanTime: 1212, sdTime: 6}},
        ]
        const history = [{report, date: twoDaysAgo, database: {}, queries: [
            {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 305, sdTime: 60}},
            {id: '456', database: 'azimutt_dev', query: 'SELECT * FROM events;', rows: 4321, exec: {count: 8, minTime: 1, maxTime: 15, sumTime: 253, meanTime: 453, sdTime: 6}},
        ]}]
        expect(queryDegradingRule.analyze({...ruleConf, minExec: 5, maxDegradation: 1, maxDegradationMonthly: 0.2, maxDegradationDaily: 0.1}, now, {}, queries, history).map(v => v.message)).toEqual([
            'Query 123 on users degraded mean exec time by 376% since 2024-05-23 (188% daily, SELECT * FROM users;).',
            'Query 456 on events degraded mean exec time by 168% since 2024-05-23 (84% daily, SELECT * FROM events;).',
        ])
        expect(queryDegradingRule.analyze({...ruleConf, minExec: 5, maxDegradation: 1, maxDegradationMonthly: 0.2, maxDegradationDaily: 0.1, ignores: ['456']}, now, {}, queries, history).map(v => v.message)).toEqual([
            'Query 123 on users degraded mean exec time by 376% since 2024-05-23 (188% daily, SELECT * FROM users;).',
        ])
    })
})
