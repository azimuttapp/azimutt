import {describe, expect, test} from "@jest/globals";
import {getDuplicatedIndexes} from "./indexDuplicated";

describe('indexDuplicated', () => {
    test('empty', () => {
        expect(getDuplicatedIndexes({name: 'users', attrs: []})).toEqual([])
        expect(getDuplicatedIndexes({name: 'users', attrs: [], indexes: []})).toEqual([])
    })
    test('no duplicates', () => {
        expect(getDuplicatedIndexes({name: 'users', attrs: [], indexes: [
            {attrs: [['first_name', 'last_name']]},
            {attrs: [['email']], unique: true},
            {attrs: [['createdAt']]},
        ]})).toEqual([])
    })
    test('with duplicates', () => {
        const users = {name: 'users', attrs: [], indexes: [
            {attrs: [['first_name', 'last_name']]},
            {attrs: [['first_name']]},
            {attrs: [['last_name']]},
        ]}
        expect(getDuplicatedIndexes(users)).toEqual([
            {entity: users, index: {attrs: [['first_name']]}, coveredBy: [{attrs: [['first_name', 'last_name']]}]}
        ])
    })
})
