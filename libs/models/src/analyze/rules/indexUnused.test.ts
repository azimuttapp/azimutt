import {describe, expect, test} from "@jest/globals";
import {Database, Entity, Index} from "../../database";
import {oneDay, oneHour} from "../../helpers/duration";
import {indexUnusedRule, isIndexUnused} from "./indexUnused";
import {ruleConf} from "../rule.test";

describe('indexUnused', () => {
    const now = 1716654244967
    const twoDaysAgo = now - (2 * oneDay)
    const threeDaysAgo = now - (3 * oneDay)
    const report = 'report_2024-05-25T16-24-04-967Z.azimutt.json'
    test('no stats', () => {
        const index: Index = {attrs: [['id']]}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}
        expect(isIndexUnused(now, current, [], 1)).toEqual(undefined)
    })
    test('used index last date', () => {
        const index: Index = {attrs: [['id']], stats: {scansLast: new Date(now - oneHour).toISOString()}}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}
        expect(isIndexUnused(now, current, [], 1)).toEqual(undefined)
    })
    test('unused index last date', () => {
        const index: Index = {attrs: [['id']], stats: {scansLast: new Date(twoDaysAgo).toISOString()}}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}
        expect(isIndexUnused(now, current, [], 1)).toEqual({date: twoDaysAgo, current})
    })
    test('used index count', () => {
        const index: Index = {attrs: [['id']], stats: {scans: 12}}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}

        const hIndex: Index = {attrs: [['id']], stats: {scans: 10}}
        const hEntity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const previous = {entity: hEntity, index: hIndex}

        expect(isIndexUnused(now, current, [{report, date: twoDaysAgo, value: previous}], 1)).toEqual(undefined)
    })
    test('unused index count', () => {
        const index: Index = {attrs: [['id']], stats: {scans: 10}}
        const entity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const current = {entity, index}

        const hIndex: Index = {attrs: [['id']], stats: {scans: 10}}
        const hEntity: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [index]}
        const previous = {entity: hEntity, index: hIndex}

        expect(isIndexUnused(now, current, [{report, date: twoDaysAgo, value: previous}], 1)).toEqual({date: twoDaysAgo, current, previous, report})
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'users_pk', attrs: [['id']], stats: {scansLast: new Date(twoDaysAgo).toISOString()}}]}]}
        expect(indexUnusedRule.analyze({...ruleConf, minDays: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Index users_pk(id) on users is unused since 2024-05-23 (check all instances to be sure!).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'users_pk', attrs: [['id']], stats: {scansLast: new Date(twoDaysAgo).toISOString()}}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], indexes: [{name: 'posts_pk', attrs: [['id']], stats: {scansLast: new Date(threeDaysAgo).toISOString()}}]},
        ]}
        expect(indexUnusedRule.analyze({...ruleConf, minDays: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Index users_pk(id) on users is unused since 2024-05-23 (check all instances to be sure!).',
            'Index posts_pk(id) on posts is unused since 2024-05-22 (check all instances to be sure!).',
        ])
        expect(indexUnusedRule.analyze({...ruleConf, minDays: 1, ignores: [{entity: 'posts', indexes: ['posts_pk']}]}, now, db, [], []).map(v => v.message)).toEqual([
            'Index users_pk(id) on users is unused since 2024-05-23 (check all instances to be sure!).',
        ])
    })
})
