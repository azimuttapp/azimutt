# MySQL connector

This library allows to connect to [MySQL](https://www.mysql.com), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their MySQL database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [MySQL queries](./src/mysql.ts) (look at `getSchema` function)

## Set up a sample MySQL database

- Go on https://www.freemysqlhosting.net and click on "Start my Free Account"
- Follow the onboarding:
    - Reset password and login
    - Click on "MySQL Hosting" in to top menu
    - Create your database
- Get your credentials by email and build the url like: `mysql://<user>:<pass>@<host>:<port>/<db>` ("Server" is the host, "Name" is the db name)
- Load data in your instance, if you don't have, you can use schemas from [Prisma schema examples](https://github.com/prisma/database-schema-examples/blob/main/mysql)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-connector-mysql-x.y.z.tgz` content
- launch `pnpm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-mysql).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
