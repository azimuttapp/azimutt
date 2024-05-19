import {describe, expect, test} from "@jest/globals";
import {DatabaseQuery} from "../../interfaces/connector";
import {queryExpensiveRule} from "./queryExpensive";
import {ruleConf} from "../rule.test";

describe('queryExpensiveRule', () => {
    test('violation message', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}}
        expect(queryExpensiveRule.analyze(ruleConf, {}, [query]).map(v => v.message)).toEqual([
            'Query 123 on users is one of the most expensive, cumulated 543 ms (SELECT * FROM users;)'
        ])
    })
})
