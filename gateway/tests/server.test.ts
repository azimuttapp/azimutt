import {describe, expect, test} from 'vitest';
import server from '../src/start';

describe('Server', () => {
    test('Should return server instance', async () => {
        expect(typeof server).eq('object')
    })
})
