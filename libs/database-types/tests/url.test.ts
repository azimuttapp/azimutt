import {describe, expect, test} from "@jest/globals";
import {parseDatabaseOptions, parseDatabaseUrl} from "../src";

describe('url', () => {
    test('parse bigquery url', () => {
        expect(parseDatabaseUrl('bigquery://?key=.bq/key.json')).toEqual({
            full: 'bigquery://?key=.bq/key.json',
            kind: 'bigquery',
            pass: '.bq/key.json'
        })
        expect(parseDatabaseUrl('bigquery://bigquery.googleapis.com?key=.bq/key.json&dataset=relational')).toEqual({
            full: 'bigquery://bigquery.googleapis.com?key=.bq/key.json&dataset=relational',
            kind: 'bigquery',
            host: 'bigquery.googleapis.com',
            pass: '.bq/key.json',
            options: 'dataset=relational'
        })
        expect(parseDatabaseUrl('jdbc:bigquery://account@service.com:.bq/key.json@https://bigquery.googleapis.com:443/my-project')).toEqual({
            full: 'jdbc:bigquery://account@service.com:.bq/key.json@https://bigquery.googleapis.com:443/my-project',
            kind: 'bigquery',
            host: 'bigquery.googleapis.com',
            port: 443,
            user: 'account@service.com',
            pass: '.bq/key.json',
            db: 'my-project'
        })
        expect(parseDatabaseUrl('jdbc:bigquery://https://bigquery.googleapis.com:443?project=my-project&email=account@service.com&key=.bq/key.json')).toEqual({
            full: 'jdbc:bigquery://https://bigquery.googleapis.com:443?project=my-project&email=account@service.com&key=.bq/key.json',
            kind: 'bigquery',
            host: 'bigquery.googleapis.com',
            port: 443,
            user: 'account@service.com',
            pass: '.bq/key.json',
            db: 'my-project'
        })
    })
    test('parse couchbase url', () => {
        expect(parseDatabaseUrl('couchbases://cb.id.cloud.couchbase.com')).toEqual({
            full: 'couchbases://cb.id.cloud.couchbase.com',
            kind: 'couchbase',
            host: 'cb.id.cloud.couchbase.com',
        })
        expect(parseDatabaseUrl('couchbases://user:pass@cb.id.cloud.couchbase.com:4567/bucket?option1=abc')).toEqual({
            full: 'couchbases://user:pass@cb.id.cloud.couchbase.com:4567/bucket?option1=abc',
            kind: 'couchbase',
            user: 'user',
            pass: 'pass',
            host: 'cb.id.cloud.couchbase.com',
            port: 4567,
            db: 'bucket',
            options: 'option1=abc',
        })
    })
    test('parse mariadb url', () => {
        expect(parseDatabaseUrl('mariadb://user:pass@host.com:3306/db?option1=abc')).toEqual({
            full: 'mariadb://user:pass@host.com:3306/db?option1=abc',
            kind: 'mariadb',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 3306,
            db: 'db',
            options: 'option1=abc',
        })
    })
    test('parse mongo url', () => {
        expect(parseDatabaseUrl('mongodb://mongodb0.example.com')).toEqual({
            full: 'mongodb://mongodb0.example.com',
            kind: 'mongodb',
            host: 'mongodb0.example.com',
        })
        expect(parseDatabaseUrl('mongodb+srv://user:pass@mongodb0.example.com:27017/my_db?secure=true')).toEqual({
            full: 'mongodb+srv://user:pass@mongodb0.example.com:27017/my_db?secure=true',
            kind: 'mongodb',
            user: 'user',
            pass: 'pass',
            host: 'mongodb0.example.com',
            port: 27017,
            db: 'my_db',
            options: 'secure=true',
        })
    })
    test('parse mysql url', () => {
        expect(parseDatabaseUrl('jdbc:mysql://user:pass@host.com:3306/db?option1=abc')).toEqual({
            full: 'jdbc:mysql://user:pass@host.com:3306/db?option1=abc',
            kind: 'mysql',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 3306,
            db: 'db',
            options: 'option1=abc',
        })
    })
    test('parse postgres url', () => {
        expect(parseDatabaseUrl('postgres://postgres0.example.com')).toEqual({
            full: 'postgres://postgres0.example.com',
            kind: 'postgres',
            host: 'postgres0.example.com',
        })
        expect(parseDatabaseUrl('postgres://user:@postgres0.example.com')).toEqual({
            full: 'postgres://user:@postgres0.example.com',
            kind: 'postgres',
            user: 'user',
            pass: '',
            host: 'postgres0.example.com',
        })
        expect(parseDatabaseUrl('jdbc:postgresql://user:pass@postgres0.example.com:5432/my_db?ssmode=require')).toEqual({
            full: 'jdbc:postgresql://user:pass@postgres0.example.com:5432/my_db?ssmode=require',
            kind: 'postgres',
            user: 'user',
            pass: 'pass',
            host: 'postgres0.example.com',
            port: 5432,
            db: 'my_db',
            options: 'ssmode=require',
        })
    })
    test('parse snowflake url', () => {
        expect(parseDatabaseUrl('https://orgname-account_name.snowflakecomputing.com')).toEqual({
            full: 'https://orgname-account_name.snowflakecomputing.com',
            kind: 'snowflake',
            host: 'orgname-account_name.snowflakecomputing.com',
        })
        expect(parseDatabaseUrl('https://accountlocator.region.cloud.snowflakecomputing.com')).toEqual({
            full: 'https://accountlocator.region.cloud.snowflakecomputing.com',
            kind: 'snowflake',
            host: 'accountlocator.region.cloud.snowflakecomputing.com',
        })
        expect(parseDatabaseUrl('https://user:pass@orgname-account_name.privatelink.snowflakecomputing.com:443/db')).toEqual({
            full: 'https://user:pass@orgname-account_name.privatelink.snowflakecomputing.com:443/db',
            kind: 'snowflake',
            user: 'user',
            pass: 'pass',
            host: 'orgname-account_name.privatelink.snowflakecomputing.com',
            port: 443,
            db: 'db',
        })
        expect(parseDatabaseUrl('snowflake://accountlocator.region.cloud.privatelink.snowflakecomputing.com?db=db&user=user')).toEqual({
            full: 'snowflake://accountlocator.region.cloud.privatelink.snowflakecomputing.com?db=db&user=user',
            kind: 'snowflake',
            user: 'user',
            host: 'accountlocator.region.cloud.privatelink.snowflakecomputing.com',
            db: 'db',
        })
        expect(parseDatabaseUrl('jdbc:snowflake://user:pass@orgname-account_name.snowflakecomputing.com:443?db=db')).toEqual({
            full: 'jdbc:snowflake://user:pass@orgname-account_name.snowflakecomputing.com:443?db=db',
            kind: 'snowflake',
            user: 'user',
            pass: 'pass',
            host: 'orgname-account_name.snowflakecomputing.com',
            port: 443,
            db: 'db',
        })
    })
    test('parse sqlserver url', () => {
        expect(parseDatabaseUrl('jdbc:sqlserver://user:pass@host.com:1433/db?option1=abc')).toEqual({
            full: 'jdbc:sqlserver://user:pass@host.com:1433/db?option1=abc',
            kind: 'sqlserver',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 1433,
            db: 'db',
            options: 'option1=abc',
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
        expect(parseDatabaseUrl('data source=host.com,1433;initial catalog=db;persist security info=True;user id=user;password=pass;MultipleActiveResultSets=False;TrustServerCertificate=True;App=azimutt')).toEqual({
            full: 'data source=host.com,1433;initial catalog=db;persist security info=True;user id=user;password=pass;MultipleActiveResultSets=False;TrustServerCertificate=True;App=azimutt',
            kind: 'sqlserver',
            user: 'user',
            pass: 'pass',
            host: 'host.com',
            port: 1433,
            db: 'db',
            options: 'persist security info=True&multipleactiveresultsets=False&trustservercertificate=True&app=azimutt'
        })
    })
    test('parse options', () => {
        expect(parseDatabaseOptions('user=test&security info=true')).toEqual({user: 'test', 'security info': 'true'})
    })
})
