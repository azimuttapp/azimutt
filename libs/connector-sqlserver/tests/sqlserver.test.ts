import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {formatSchema, getSchema, SqlserverSchema} from "../src/sqlserver";
import mssql, {config, ConnectionPool, IOptions} from "mssql";

describe('sqlserver', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('connect', async () => {
        // const connection: ConnectionPool = await mssql.connect('Server=host.com,1433;Database=db;User Id=user;Password=pass')
        const opts: IOptions = {
            trustedConnection: true,
            encrypt: true
        }
        const conf: config = {
            // driver: '',
            server: 'host.com',
            port: 1433,
            user: 'user',
            password: 'pass',
            // domain: '',
            database: 'db',
            options: opts
        }
        const connection: ConnectionPool = await mssql.connect(conf)
        const res = await connection.query("SELECT * FROM Departments WHERE DepartmentCode='DS';").then(result => result.recordset)
        console.log('res', res)
        await connection.close()
    })
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM Departments WHERE DepartmentCode='DS';", []))
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(undefined, 10, logger))
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(32)
    })
    test('formatSchema', () => {
        const rawSchema: SqlserverSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, false)).toEqual(expectedSchema)
    })
})
