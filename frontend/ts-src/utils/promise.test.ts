import {sequence, sequenceSafe, successes} from "./promise";

describe('promise', () => {
    test('sequence', async () => {
        await expect(sequence([1, 2, 3], inc)).resolves.toEqual([2, 3, 4])
        await expect(sequence([1, 2, 3], isEven)).rejects.toEqual('bad')
    })
    test('sequenceSafe', async () => {
        await expect(sequenceSafe([1, 2, 3], inc)).resolves.toEqual([[], [2, 3, 4]])
        await expect(sequenceSafe([1, 2, 3], isEven)).resolves.toEqual([[[1, 'bad'], [3, 'bad']], [2]])
    })
    test('successes', async () => {
        await expect(successes([1, 2, 3].map(inc))).resolves.toEqual([2, 3, 4])
        await expect(successes([1, 2, 3].map(isEven))).resolves.toEqual([2])
    })

    function inc(i: number): Promise<number> {
        return Promise.resolve(i + 1)
    }

    function isEven(i: number): Promise<number> {
        return i % 2 === 0 ? Promise.resolve(i) : Promise.reject('bad')
    }
})
