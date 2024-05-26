import {describe, expect, test} from "@jest/globals";
import {Database, Entity, Index} from "../../database";
import {Mo} from "../../helpers/bytes";
import {oneDay, oneMonth} from "../../helpers/date";
import {indexGrowFastRule, isIndexGrowingFast} from "./indexGrowFast";
import {ruleConf} from "../rule.test";

describe('indexGrowFast', () => {
    const now = 1716654244967
    const oneMonthAgo = now - oneMonth - oneDay
    const report = 'report_2024-04-24T16-24-04-967Z.azimutt.json'
    test('no stats', () => {
        const index: Index = {attrs: [['id']]}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}
        expect(isIndexGrowingFast(now, current, [], 10, 2, 0.1, 0.01)).toEqual(undefined)
    })
    test('slow index growth', () => {
        const index: Index = {attrs: [['id']], stats: {size: 1010}}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}

        const hIndex: Index = {attrs: [['id']], stats: {size: 1000}}
        const hEntity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const previous = {entity: hEntity, index: hIndex}

        expect(isIndexGrowingFast(now, current, [{report, date: oneMonthAgo, value: previous}], 10, 2, 0.1, 0.01)).toEqual(undefined)
    })
    test('fast index growth', () => {
        const index: Index = {attrs: [['id']], stats: {size: 1500}}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}

        const hIndex: Index = {attrs: [['id']], stats: {size: 1000}}
        const hEntity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const previous = {entity: hEntity, index: hIndex}

        expect(isIndexGrowingFast(now, current, [{report, date: oneMonthAgo, value: previous}], 10, 2, 0.1, 0.01))
            .toEqual({date: oneMonthAgo, report, current, previous, diff: 500, growth: 0.5, period: oneMonth + oneDay, daily: 0.016129032258064516, monthly: 0.48387096774193544, yearly: 5.887096774193549})
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'users_pk', attrs: [['id']], stats: {size: 15 * Mo}}]}]}
        const history = [{report, date: oneMonthAgo, database: {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'users_pk', attrs: [['id']], stats: {size: 10 * Mo}}]}]}, queries: []}]
        expect(indexGrowFastRule.analyze({...ruleConf, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01}, now, db, [], history).map(v => v.message)).toEqual([
            'Index users_pk(id) on users has grown by 50% (5 Mo) since 2024-04-24 (48% monthly).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'users_pk', attrs: [['id']], stats: {size: 12 * Mo}}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'posts_pk', attrs: [['id']], stats: {size: 14 * Mo}}]},
        ]}
        const history = [{report, date: oneMonthAgo, database: {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'users_pk', attrs: [['id']], stats: {size: 10 * Mo}}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'posts_pk', attrs: [['id']], stats: {size: 10 * Mo}}]},
        ]}, queries: []}]
        expect(indexGrowFastRule.analyze({...ruleConf, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01}, now, db, [], history).map(v => v.message)).toEqual([
            'Index users_pk(id) on users has grown by 20% (2 Mo) since 2024-04-24 (19% monthly).',
            'Index posts_pk(id) on posts has grown by 40% (4 Mo) since 2024-04-24 (39% monthly).',
        ])
        expect(indexGrowFastRule.analyze({...ruleConf, ignores: [{entity: 'posts', indexes: ['posts_pk']}], minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01}, now, db, [], history).map(v => v.message)).toEqual([
            'Index users_pk(id) on users has grown by 20% (2 Mo) since 2024-04-24 (19% monthly).',
        ])
    })
})
