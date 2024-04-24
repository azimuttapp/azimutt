import {describe, test} from "@jest/globals";
import {parseDatabase} from "./sql";

describe('sql', () => {
    describe('select', () => {
        test.skip('basic', async () => {
            const sql = 'SELECT column1 FROM table2'
            const res = await parseDatabase(sql)
            console.log('res', res)
        })
    })
})
