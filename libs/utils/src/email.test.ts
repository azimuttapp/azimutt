import {describe, expect, test} from "@jest/globals";
import {emailParse} from "./email";

describe('email', () => {
    test('emailParse', () => {
        expect(emailParse('bad')).toEqual({full: 'bad'})
        expect(emailParse('loic@azimutt.app')).toEqual({full: 'loic@azimutt.app', domain: 'azimutt.app'})
        expect(emailParse('loic@test.azimutt.app')).toEqual({full: 'loic@test.azimutt.app'})
    })
})
