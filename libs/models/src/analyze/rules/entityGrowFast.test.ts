import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {oneMonth} from "../../helpers/date";
import {Mo} from "../../helpers/bytes";
import {entityGrowFastRule, isEntityGrowingFast} from "./entityGrowFast";
import {ruleConf} from "../rule.test";

describe('entityGrowFast', () => {
    const now = 1716654244967
    const oneMonthAgo = now - oneMonth
    const report = 'report_2024-04-25T16-24-04-967Z.azimutt.json'
    test('no stats', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isEntityGrowingFast(now, current, [], 10, 10, 2, 0.1, 0.01)).toEqual(undefined)
    })
    test('slow entity row growth', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1010}}
        const previous: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1005}}
        expect(isEntityGrowingFast(now, current, [{report, date: oneMonthAgo, entity: previous}], 10, 10, 2, 0.1, 0.01)).toEqual(undefined)
    })
    test('fast entity row growth', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1500}}
        const previous: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1000}}
        expect(isEntityGrowingFast(now, current, [{report, date: oneMonthAgo, entity: previous}], 10, 10, 2, 0.1, 0.01))
            .toEqual({date: oneMonthAgo, report, current, previous, kind: 'rows', diff: 500, growth: 0.5, period: oneMonth, daily: 0.016666666666666666, monthly: 0.5, yearly: 6.083333333333334})
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1500}}]}
        const history = [{report, date: oneMonthAgo, database: {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1000}}]}, queries: []}]
        expect(entityGrowFastRule.analyze({...ruleConf, minRows: 1000, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01}, now, db, [], history).map(v => v.message)).toEqual([
            'Entity users has grown by 50% (500 rows) since 2024-04-25 (2% daily).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1500}},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], stats: {size: 30 * Mo}},
        ]}
        const history = [{report, date: oneMonthAgo, database: {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rows: 1000}},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], stats: {size: 15 * Mo}},
        ]}, queries: []}]
        expect(entityGrowFastRule.analyze({...ruleConf, minRows: 1000, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01}, now, db, [], history).map(v => v.message)).toEqual([
            'Entity users has grown by 50% (500 rows) since 2024-04-25 (2% daily).',
            'Entity posts has grown by 100% (15 Mo) since 2024-04-25 (3% daily).',
        ])
        expect(entityGrowFastRule.analyze({...ruleConf, ignores: ['posts'], minRows: 1000, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01}, now, db, [], history).map(v => v.message)).toEqual([
            'Entity users has grown by 50% (500 rows) since 2024-04-25 (2% daily).',
        ])
    })
})
