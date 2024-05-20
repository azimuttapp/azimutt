import {describe, expect, test} from "@jest/globals";
import {DatabaseQuery} from "../../interfaces/connector";
import {queryHighVariationRule} from "./queryHighVariation";
import {ruleConf} from "../rule.test";

describe('queryHighVariationRule', () => {
    test('ignores', () => {
        const queries: DatabaseQuery[] = [
            {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}},
            {id: '456', database: 'azimutt_dev', query: 'SELECT * FROM events;', rows: 4321, exec: {count: 8, minTime: 1, maxTime: 15, sumTime: 253, meanTime: 12, sdTime: 6}},
        ]
        expect(queryHighVariationRule.analyze(ruleConf, {}, queries).map(v => v.message)).toEqual([
            'Query 123 on users has high variation, with 60 ms standard deviation and execution time ranging from 10 ms to 150 ms (SELECT * FROM users;)',
            'Query 456 on events has high variation, with 6 ms standard deviation and execution time ranging from 1 ms to 15 ms (SELECT * FROM events;)',
        ])
        expect(queryHighVariationRule.analyze({...ruleConf, ignores: ['456']}, {}, queries).map(v => v.message)).toEqual([
            'Query 123 on users has high variation, with 60 ms standard deviation and execution time ranging from 10 ms to 150 ms (SELECT * FROM users;)',
        ])
    })
    test('violation message', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}}
        expect(queryHighVariationRule.analyze(ruleConf, {}, [query]).map(v => v.message)).toEqual([
            'Query 123 on users has high variation, with 60 ms standard deviation and execution time ranging from 10 ms to 150 ms (SELECT * FROM users;)'
        ])
    })
})
