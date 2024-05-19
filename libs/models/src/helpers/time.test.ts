import {describe, expect, test} from "@jest/globals";
import {formatMs} from "./time";

describe('time', () => {
    test('formatMs', () => {
        expect(formatMs(10.12)).toEqual('10 ms')
        expect(formatMs(9410.12)).toEqual('9410 ms')
        expect(formatMs(12835.12)).toEqual('13 secs')
        expect(formatMs(104835.12)).toEqual('105 secs')
        expect(formatMs(894835.12)).toEqual('15 mins')
        expect(formatMs(5294835.12)).toEqual('88 mins')
        expect(formatMs(23894835.12)).toEqual('7 hours')
        expect(formatMs(133894835.12)).toEqual('37 hours')
        expect(formatMs(523894835.12)).toEqual('6 days')
        expect(formatMs(1123894835.12)).toEqual('13 days')
        expect(formatMs(1823894835.12)).toEqual('3 weeks')
        expect(formatMs(5123894835.12)).toEqual('8 weeks')
        expect(formatMs(7523894835.12)).toEqual('3 months')
        expect(formatMs(37523894835.12)).toEqual('14 months')
        expect(formatMs(137523894835.12)).toEqual('4 years')
        expect(formatMs(537523894835.12)).toEqual('17 years')
    })
})
