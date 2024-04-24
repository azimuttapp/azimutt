import {describe, expect, test} from "vitest"
import {version} from "../version";
import {NodeEnv, startServer} from "../index";
import {buildConfig} from "../plugins/config";

describe('GET /', async () => {
    const server = await startServer(buildConfig({
        NODE_ENV: NodeEnv.development,
        LOG_LEVEL: 'info',
        API_HOST: 'localhost',
        API_PORT: '1234',
        CORS_ALLOW_ORIGIN: 'http://localhost:4000',
    }))
    test('Should return hello world', async () => {
        const response = await server.inject({method: 'GET', path: '/'})
        expect(response.statusCode).eq(200)
        expect(response.json()).deep.eq({status: 200, version})
    })
})
