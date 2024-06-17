import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {oneDay} from "../../helpers/duration";
import {entityNotCleanRule, isEntityNotClean} from "./entityNotClean";
import {ruleConf} from "../rule.test";

describe('entityNotClean', () => {
    const now = Date.now()
    const twoDaysAgo = new Date(now - (2 * oneDay)).toISOString()
    const maxDeadRows = 30000
    const maxVacuumLag = 30000
    const maxAnalyzeLag = 30000
    const maxVacuumDelayMs = oneDay
    const maxAnalyzeDelayMs = oneDay
    const conf = {...ruleConf, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs}

    test('entity with many dead rows', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rowsDead: 42000}}
        expect(isEntityNotClean(users, now, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs)).toEqual('many dead rows')
    })
    test('entity with high vacuum lag', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {vacuumLag: 42000}}
        expect(isEntityNotClean(users, now, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs)).toEqual('high vacuum lag')
    })
    test('entity with high analyze lag', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {analyzeLag: 42000}}
        expect(isEntityNotClean(users, now, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs)).toEqual('high analyze lag')
    })
    test('entity with old vacuum', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {vacuumLast: twoDaysAgo}}
        expect(isEntityNotClean(users, now, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs)).toEqual('old vacuum')
    })
    test('entity with old analyze', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {analyzeLast: twoDaysAgo}}
        expect(isEntityNotClean(users, now, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs)).toEqual('old analyze')
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rowsDead: 42000}}]}
        expect(entityNotCleanRule.analyze(conf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rowsDead: 42000}},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], stats: {vacuumLag: 41000}}
        ]}
        expect(entityNotCleanRule.analyze(conf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
            'Entity posts has high vacuum lag (41000).',
        ])
        expect(entityNotCleanRule.analyze({...conf, ignores: ['posts']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
        ])
        expect(entityNotCleanRule.analyze(conf, now, db, [], [], [{message: '', entity: {entity: 'posts'}}]).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
        ])
    })
})
