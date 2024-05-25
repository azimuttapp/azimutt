import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {entityNotCleanRule, isEntityNotClean} from "./entityNotClean";
import {ruleConf} from "../rule.test";

describe('entityNotClean', () => {
    const now = Date.now()
    const oneDayMs = 24 * 60 * 60 * 1000
    const twoDaysAgo = new Date(now - (2 * oneDayMs)).toISOString()
    const maxDeadRows = 30000
    const maxVacuumLag = 30000
    const maxAnalyzeLag = 30000
    const maxVacuumDelayMs = oneDayMs
    const maxAnalyzeDelayMs = oneDayMs

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
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rowsDead: 42000}},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], stats: {vacuumLag: 41000}}
        ]}
        expect(entityNotCleanRule.analyze({...ruleConf, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs}, db, []).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
            'Entity posts has high vacuum lag (41000).',
        ])
        expect(entityNotCleanRule.analyze({...ruleConf, ignores: ['posts'], maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs}, db, []).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
        ])
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {rowsDead: 42000}}]}
        expect(entityNotCleanRule.analyze({...ruleConf, maxDeadRows, maxVacuumLag, maxAnalyzeLag, maxVacuumDelayMs, maxAnalyzeDelayMs}, db, []).map(v => v.message)).toEqual([
            'Entity users has many dead rows (42000).',
        ])
    })
})
