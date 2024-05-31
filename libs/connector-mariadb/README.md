# MariaDB connector

This library allows to connect to [MariaDB](https://mariadb.com), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their MariaDB database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [MariaDB queries](./src/mariadb.ts) (look at `getSchema` function)

## Set up a sample MariaDB database

- Go on https://mariadb.com and click on "Start in the cloud" (top right)
- Follow the onboarding
- Create a cloud database
- In manage click on "Security access" to allow your IP (if it doesn't work, check your adblock ^^)
- Then click on "connect to get your credentials" and build an url like: `mariadb://<user>:<pass>@<host>:<port>/<db>` (db is the one you created)
- Load data in your instance, if you don't have, you can use schemas from [here](https://dataedo.com/kb/databases/mariadb/sample-databases) or [there](https://github.com/mariadb-corporation/dev-example-bookings)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-connector-mariadb-x.y.z.tgz` content
- launch `pnpm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-mariadb).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
