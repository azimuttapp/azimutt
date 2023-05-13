import server from '../../src/server';
import { describe, test, expect } from 'vitest';

describe('GET /', () => {
  test('Should return hello world', async () => {
    const response = await server.inject({
      method: 'GET',
      path: '/',
    });
    expect(response.statusCode).eq(200);
    expect(response.json()).deep.eq({ hello: 'world' });
  });
});
