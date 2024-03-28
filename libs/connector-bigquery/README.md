# BigQuery connector

This library allows to connect to [BigQuery](https://cloud.google.com/bigquery), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their BigQuery database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [BigQuery queries](./src/bigquery.ts) (look at `getSchema` function)

## Publish

- update `package.json` version
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-connector-bigquery-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-bigquery).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but revert & publish before commit.

- Depend on a local lib: `npm install <path>`, ex: `npm install ../database-types`
- "Publish" lib locally by building it: `npm run build`
