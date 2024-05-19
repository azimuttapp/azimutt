import {describe, expect, test} from "@jest/globals";
import {DatabaseQuery} from "../../interfaces/connector";
import {queryHighVariationRule} from "./queryHighVariation";
import {ruleConf} from "../rule.test";

describe('queryHighVariationRule', () => {
    test('violation message', () => {
        const query: DatabaseQuery = {id: '123', database: 'azimutt_dev', query: 'SELECT * FROM users;', rows: 1234, exec: {count: 5, minTime: 10, maxTime: 150, sumTime: 543, meanTime: 142, sdTime: 60}}
        expect(queryHighVariationRule.analyze(ruleConf, {}, [query]).map(v => v.message)).toEqual([
            'Query 123 on users has high variation, with 60 ms standard deviation and execution time ranging from 10 to 150 ms (SELECT * FROM users;)'
        ])
    })
})
