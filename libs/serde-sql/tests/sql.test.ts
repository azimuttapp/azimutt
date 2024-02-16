import {describe, test} from "@jest/globals";
import {parse} from "../src/sql";

describe('sql', () => {
    describe('select', () => {
        test.skip('basic', async () => {
            const sql = 'SELECT column1 FROM table2'
            const res = await parse(sql)
            console.log('res', res)
        })
    })
})
