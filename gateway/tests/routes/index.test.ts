import {describe, expect, test} from "vitest"
import {version} from "../../src/version";
import {startServer} from "../../src";
import {configFromEnv} from "../../src/plugins/config";

describe('GET /', async () => {
    const server = await startServer(configFromEnv())
    test('Should return hello world', async () => {
        const response = await server.inject({method: 'GET', path: '/'})
        expect(response.statusCode).eq(200)
        expect(response.json()).deep.eq({status: 200, version})
    })
})
