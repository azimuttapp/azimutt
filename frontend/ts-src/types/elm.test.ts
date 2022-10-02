import {Click, MouseDown} from "./elm";

describe('elm', () => {
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
