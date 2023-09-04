# PostgreSQL connector

This library is able to connect to [PostgreSQL](https://www.postgresql.org), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their PostgreSQL database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [PostgreSQL queries](./src/postgres.ts) (look at `getSchema` function)

## Publish

- update `package.json` version
- update lib versions `npm run update` & run `npm install`
- test with `npm run dry-publish` and check `azimutt-connector-postgres-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-postgres).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `npm install <path>`, ex: `npm install ../database-types`
- "Publish" lib locally by building it: `npm run build`
