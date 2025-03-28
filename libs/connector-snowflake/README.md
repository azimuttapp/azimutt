# Snowflake connector

This library allows to connect to [Snowflake](https://www.snowflake.com), extract its schema and more...

It lists all schemas, tables, columns and relations and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their Snowflake database.
It's accessible through the [Desktop app](../../extensions/desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [Snowflake queries](./src/snowflake.ts) (look at `getSchema` function)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual) 
- test with `pnpm run dry-publish` and check `azimutt-connector-snowflake-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-snowflake).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
