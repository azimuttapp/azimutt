import server from '../src/server.js';
import { test, describe, expect } from 'vitest';


describe('Server', () => {
  test('Should return server instance', async () => {
    expect(typeof server).eq('object');
    await server.close();
  });
});
