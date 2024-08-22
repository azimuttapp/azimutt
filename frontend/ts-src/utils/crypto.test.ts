import {base64Decode, aesDecrypt, base64Encode, aesEncrypt, base64Valid} from "./crypto";

describe('crypto', () => {
    beforeAll(async () => {
        global.TextEncoder = require('util').TextEncoder
        global.TextDecoder = require('util').TextDecoder
    })

    // miss `crypto.subtle` in jest jsdom :/
    test.skip('aes', async () => {
        const key = 'key'
        const text = '123'
        const cipher = '123'
        expect(await aesEncrypt(key, text)).toEqual(cipher)
        expect(await aesDecrypt(key, cipher)).toEqual(text)
    })
    test('base64', () => {
        const text = 'azimutt'
        const base64 = 'YXppbXV0dA=='
        expect(base64Encode(text)).toEqual(base64)
        expect(base64Decode(base64)).toEqual(text)
        expect(base64Valid(base64)).toEqual(true)
    })
})
