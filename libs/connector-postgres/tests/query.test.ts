import {describe, expect, test} from "@jest/globals";
import {url} from "./constants";
import {query} from "../src";

describe('query', () => {
    test.skip('query', async () => {
        const result = await query(url, 'SELECT * FROM users LIMIT 2;')
        expect(result.rows.length).toEqual(2)
    })
})
