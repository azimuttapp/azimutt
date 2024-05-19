import {describe, expect, test} from "@jest/globals";
import {pathParent} from "./file";

// to have at least one test in every module ^^
describe('file', () => {
    test('pathParent', () => {
        expect(pathParent('~/.azimutt/analyze/conf.json')).toEqual('~/.azimutt/analyze')
    })
})
