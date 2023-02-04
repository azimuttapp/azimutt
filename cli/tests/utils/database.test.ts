import {describe, expect, test} from "@jest/globals";
import {parseUrl} from "../../src/utils/database";

describe('utils/database', () => {
    test('parse mongo url', () => {
        expect(parseUrl('mongodb://mongodb0.example.com')).toEqual({
            full: 'mongodb://mongodb0.example.com',
            kind: 'mongodb',
            host: 'mongodb0.example.com'
        })
        expect(parseUrl('mongodb+srv://user:pass@mongodb0.example.com:27017/my_db?secure=true')).toEqual({
            full: 'mongodb+srv://user:pass@mongodb0.example.com:27017/my_db?secure=true',
            kind: 'mongodb',
            user: 'user',
            pass: 'pass',
            host: 'mongodb0.example.com',
            port: 27017,
            db: 'my_db',
            options: 'secure=true'
        })
    })
    test('parse postgres url', () => {
        expect(parseUrl('postgres://postgres0.example.com')).toEqual({
            full: 'postgres://postgres0.example.com',
            kind: 'postgres',
            host: 'postgres0.example.com'
        })
        expect(parseUrl('jdbc:postgresql://user:pass@postgres0.example.com:5432/my_db')).toEqual({
            full: 'jdbc:postgresql://user:pass@postgres0.example.com:5432/my_db',
            kind: 'postgres',
            user: 'user',
            pass: 'pass',
            host: 'postgres0.example.com',
            port: 5432,
            db: 'my_db',
        })
    })
})
