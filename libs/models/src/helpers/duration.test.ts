import {describe, expect, test} from "@jest/globals";
import {showDuration} from "./duration";

describe('duration', () => {
    test('showDuration', () => {
        expect(showDuration(10.12)).toEqual('10 ms')
        expect(showDuration(9410.12)).toEqual('9410 ms')
        expect(showDuration(12835.12)).toEqual('13 secs')
        expect(showDuration(104835.12)).toEqual('105 secs')
        expect(showDuration(894835.12)).toEqual('15 mins')
        expect(showDuration(5294835.12)).toEqual('88 mins')
        expect(showDuration(23894835.12)).toEqual('7 hours')
        expect(showDuration(133894835.12)).toEqual('37 hours')
        expect(showDuration(523894835.12)).toEqual('6 days')
        expect(showDuration(1123894835.12)).toEqual('13 days')
        expect(showDuration(1823894835.12)).toEqual('3 weeks')
        expect(showDuration(5123894835.12)).toEqual('8 weeks')
        expect(showDuration(7523894835.12)).toEqual('3 months')
        expect(showDuration(37523894835.12)).toEqual('14 months')
        expect(showDuration(137523894835.12)).toEqual('4 years')
        expect(showDuration(537523894835.12)).toEqual('17 years')
    })
})
