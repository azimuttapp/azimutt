import {describe, test} from "@jest/globals";
import {parseSql} from "./sql";

/*
SQLite:
https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Main/Database/Database%20schema/Schema.sql
https://github.com/wikimedia/mediawiki/blob/0c37286a6f418e78ccd896020d9bd1c4d041f5e9/maintenance/tables-generated.sql
Prisma:
https://github.com/formbricks/formbricks/blob/main/packages/database/schema.prisma
https://github.com/useplunk/plunk/blob/main/prisma/schema.prisma
https://github.com/AmruthPillai/Reactive-Resume/blob/main/tools/prisma/schema.prisma
https://github.com/umami-software/umami/blob/master/db/postgresql/schema.prisma
 */
describe('sql', () => {
    describe('select', () => {
        test.skip('basic', async () => {
            const sql = 'SELECT column1 FROM table2'
            const res = parseSql(sql, 'postgres')
            console.log('res', res)
        })
    })
})
