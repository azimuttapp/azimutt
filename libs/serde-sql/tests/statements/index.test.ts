import {expect, describe, test} from "@jest/globals";
import {SqlStatement} from "../../src/statements";

describe('SqlStatement', () => {
    test('have shared fields', () => {
        const statements: SqlStatement[] = [{
            command: 'ROLLBACK',
            language: 'TCL',
            operation: 'transaction',
        }]
        // TypeScript will fail if fields are not present in all commands
        expect(statements[0].command).toEqual('ROLLBACK')
        expect(statements[0].language).toEqual('TCL')
        expect(statements[0].operation).toEqual('transaction')
    })
})
