import {describe, expect, test} from "vitest"
import server from "../../src/start"

describe('GET /', () => {
    test('Should return hello world', async () => {
        const response = await server.inject({
            method: 'GET',
            path: '/',
        })
        expect(response.statusCode).eq(200)
        expect(response.json()).deep.eq({hello: 'world'})
    })
})
