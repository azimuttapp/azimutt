import {describe, expect, test} from "@jest/globals";
import {application, url} from "./constants";
import {getColumnStats, getTableStats} from "../src";

describe('index', () => {
    test.skip('getTableStats', async () => {
        const stats = await getTableStats(application, url, 'public.users')
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await getColumnStats(application, url, {table: 'public.users', column: 'name'})
        expect(stats.rows).toEqual(2)
    })
})
