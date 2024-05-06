import {describe, test} from "vitest"
import {track} from "./tracking";

describe('tracking', () => {
    test.skip('test', async () => {
        await track('test', {}, 'azimutt-test')
    })
})
