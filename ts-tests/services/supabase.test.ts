import {Supabase} from "../../ts-src/services/supabase";
import jiff from "jiff";

function sum(a: number, b: number): number {
    return a + b;
}

describe('JSON patch', () => {
    test('should work', () => {
        const initial = {name: 'a', value: 'a', updatedAt: 1}
        const current = {name: 'b', value: 'a', updatedAt: 2}
        const saving = {name: 'a', value: 'b', updatedAt: 1}

        const patch = jiff.diff(initial, saving)
        const patched = jiff.patch(patch, current)

        expect(patched).toEqual({name: 'b', value: 'b', updatedAt: 2});
    })
})
