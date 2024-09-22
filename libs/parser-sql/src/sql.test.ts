import {describe, test} from "@jest/globals";
import {parseSql} from "./sql";

describe('sql', () => {
    describe('select', () => {
        test.skip('basic', async () => {
            const sql = 'SELECT column1 FROM table2'
            const res = parseSql(sql, 'postgres')
            console.log('res', res)
        })
    })
})
