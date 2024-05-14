import {Click, MouseDown} from "./ports";

/**
 * FAIL  ts-src/types/ports.test.ts
 *   ● Test suite failed to run
 *
 *     this environment is missing the following Web Fetch API type: fetch is not defined. You may need to use polyfills
 *
 *       1 | import {z} from "zod";
 *     > 2 | import "openai/shims/web";
 *         | ^
 *       3 | import OpenAI from "openai";
 *       4 | import {Logger} from "@azimutt/utils";
 *       5 |
 *
 * Can't mock fetch with:
 * global.fetch = jest.fn((): Promise<Response> => Promise.reject('mock'))
 */

describe('ports', () => {
    test('Click', () => {
        const data = { kind: 'Click', id: 'header' }
        const res: Click = Click.parse(data) // make sure parser result is aligned with TS type!
        expect(res).toEqual(data)
    })
    test('MouseDown', () => {
        const data = { kind: 'MouseDown', id: 'header' }
        const res: MouseDown = MouseDown.parse(data) // make sure parser result is aligned with TS type!
        expect(res).toEqual(data)
    })
    // TODO: to be continued...
})
