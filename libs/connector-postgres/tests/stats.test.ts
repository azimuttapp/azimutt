import {describe, expect, test} from "@jest/globals";
import {application, url} from "./constants";
import {columnStats, tableStats} from "../src";

describe('index', () => {
    test.skip('tableStats', async () => {
        const stats = await tableStats(application, url, 'public.users')
        expect(stats.rows).toEqual(2)
    })
    test.skip('columnStats', async () => {
        const stats = await columnStats(application, url, {table: 'public.users', column: 'name'})
        expect(stats.rows).toEqual(2)
    })
})
