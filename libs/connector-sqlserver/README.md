# SQL Server connector

This library is able to connect to [SQL Server](https://www.microsoft.com/fr-fr/sql-server/sql-server-downloads), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their SQL Server database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [SQL Server queries](./src/sqlserver.ts) (look at `getSchema` function)

## Set up a sample SQL Server database

- Go on https://www.microsoft.com/fr-fr/sql-server/sql-server-downloads and click on "Start"
- Build your database url, like: `sqlserver://<user>:<pass>@<host>:<port>;database=<db>` or `Server=<host>,<port>;Database=<db>;User Id=<user>;Password=<pass>`
- Load data in your instance, if you don't have, you can use schemas from [Prisma schema examples](https://github.com/prisma/database-schema-examples/tree/main/mssql)

## Publish

- update `package.json` version
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-connector-sqlserver-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-sqlserver).
