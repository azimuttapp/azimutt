import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {oneDay, oneHour} from "../../helpers/duration";
import {entityUnusedRule, isEntityUnused} from "./entityUnused";
import {ruleConf} from "../rule.test";

describe('entityUnused', () => {
    const now = 1716654244967
    const twoDaysAgo = now - (2 * oneDay)
    const threeDaysAgo = now - (3 * oneDay)
    const report = 'report_2024-05-25T16-24-04-967Z.azimutt.json'
    test('no stats', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isEntityUnused(now, current, [], 1)).toEqual(undefined)
    })
    test('used entity last date', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeqLast: new Date(now - oneHour).toISOString()}}
        expect(isEntityUnused(now, current, [], 1)).toEqual(undefined)
    })
    test('unused entity last date', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeqLast: new Date(twoDaysAgo).toISOString()}}
        expect(isEntityUnused(now, current, [], 1)).toEqual({date: twoDaysAgo, current})
    })
    test('used entity count', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeq: 12}}
        const previous: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeq: 10}}
        expect(isEntityUnused(now, current, [{report, date: twoDaysAgo, entity: previous}], 1)).toEqual(undefined)
    })
    test('unused entity count', () => {
        const current: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeq: 10}}
        const previous: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeq: 10}}
        expect(isEntityUnused(now, current, [{report, date: twoDaysAgo, entity: previous}], 1)).toEqual({date: twoDaysAgo, current, previous, report})
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeqLast: new Date(twoDaysAgo).toISOString()}}]}
        expect(entityUnusedRule.analyze({...ruleConf, minDays: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users is unused since 2024-05-23 (check all instances to be sure!).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeqLast: new Date(twoDaysAgo).toISOString()}},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], stats: {scanSeqLast: new Date(threeDaysAgo).toISOString()}},
        ]}
        expect(entityUnusedRule.analyze({...ruleConf, minDays: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users is unused since 2024-05-23 (check all instances to be sure!).',
            'Entity posts is unused since 2024-05-22 (check all instances to be sure!).',
        ])
        expect(entityUnusedRule.analyze({...ruleConf, minDays: 1, ignores: ['posts']}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users is unused since 2024-05-23 (check all instances to be sure!).',
        ])
    })
})
