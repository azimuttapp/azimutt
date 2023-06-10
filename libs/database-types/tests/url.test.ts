import {describe, expect, test} from "@jest/globals";
import {parseDatabaseUrl} from "../src";

describe('url', () => {
    test('parse couchbase url', () => {
        expect(parseDatabaseUrl('couchbases://cb.id.cloud.couchbase.com')).toEqual({
            full: 'couchbases://cb.id.cloud.couchbase.com',
            kind: 'couchbase',
            host: 'cb.id.cloud.couchbase.com'
        })
        expect(parseDatabaseUrl('couchbases://user:pass@cb.id.cloud.couchbase.com:4567/bucket')).toEqual({
            full: 'couchbases://user:pass@cb.id.cloud.couchbase.com:4567/bucket',
            kind: 'couchbase',
            user: 'user',
            pass: 'pass',
            host: 'cb.id.cloud.couchbase.com',
            port: 4567,
            db: 'bucket',
        })
    })
    test('parse mongo url', () => {
        expect(parseDatabaseUrl('mongodb://mongodb0.example.com')).toEqual({
            full: 'mongodb://mongodb0.example.com',
            kind: 'mongodb',
            host: 'mongodb0.example.com'
        })
        expect(parseDatabaseUrl('mongodb+srv://user:pass@mongodb0.example.com:27017/my_db?secure=true')).toEqual({
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
    test('parse mysql url', () => {
        expect(parseDatabaseUrl('jdbc:mysql://user:pass@host.com:3306/db')).toEqual({
            full: 'jdbc:mysql://user:pass@host.com:3306/db',
            kind: 'mysql',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 3306,
            db: 'db',
        })
    })
    test('parse postgres url', () => {
        expect(parseDatabaseUrl('postgres://postgres0.example.com')).toEqual({
            full: 'postgres://postgres0.example.com',
            kind: 'postgres',
            host: 'postgres0.example.com'
        })
        expect(parseDatabaseUrl('jdbc:postgresql://user:pass@postgres0.example.com:5432/my_db')).toEqual({
            full: 'jdbc:postgresql://user:pass@postgres0.example.com:5432/my_db',
            kind: 'postgres',
            user: 'user',
            pass: 'pass',
            host: 'postgres0.example.com',
            port: 5432,
            db: 'my_db',
        })
    })
    test('parse sqlserver url', () => {
        expect(parseDatabaseUrl('jdbc:sqlserver://user:pass@host.com:1433/db')).toEqual({
            full: 'jdbc:sqlserver://user:pass@host.com:1433/db',
            kind: 'sqlserver',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 1433,
            db: 'db',
        })
        expect(parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')).toEqual({
            full: 'Server=host.com,1433;Database=db;User Id=user;Password=pass',
            kind: 'sqlserver',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 1433,
            db: 'db',
        })
        expect(parseDatabaseUrl('User Id=user;Password=pass;Server=host.com,1433;Database=db')).toEqual({
            full: 'User Id=user;Password=pass;Server=host.com,1433;Database=db',
            kind: 'sqlserver',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 1433,
            db: 'db',
        })
    })
})
