import {describe, expect, test} from "@jest/globals";
import {showBytes} from "./bytes";

describe('bytes', () => {
    test('showBytes', () => {
        expect(showBytes(42)).toEqual('42 bytes')
        expect(showBytes(4056)).toEqual('4.1 ko')
        expect(showBytes(5872025)).toEqual('5.9 Mo')
        expect(showBytes(3435973836)).toEqual('3.4 Go')
        expect(showBytes(13194139530000)).toEqual('13 To')
        expect(showBytes(385057768100000000)).toEqual('385 Po')
    })
})
