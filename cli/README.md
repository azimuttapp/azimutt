# Azimutt CLI

Azimutt CLI is aimed at helping you explore databases, schema but also data.

It works with relational and document ones, such as **Couchbase**, **MariaDB**, **MongoDB**, **MySQL**, **PostgreSQL**, **SQL Server**  🎉

Use this CLI without installing it thanks to [npx](https://www.npmjs.com/package/npx): `npx azimutt@latest`.

Get the help simply by running the CLI (`npx azimutt@latest`) or for a specific command using `npx azimutt@latest help export` for example.

## Available commands

- **gateway** (`npx azimutt gateway`): launch the Gateway server locally to proxy database calls from your computer
- **explore** (`npx azimutt explore <url>`): open Azimutt in your browser with the db url already configured (& start the Gateway server)
- **export** (`npx azimutt export <url> [arguments]`): export a database schema as JSON file to import in Azimutt
  - ex: `npx azimutt export bigquery://bigquery.googleapis.com/my-project?key=key.json`
  - ex: `npx azimutt export couchbases://cb.gfn6dh493pmfh613v.cloud.couchbase.com`
  - ex: `npx azimutt export mariadb://user:password@my.host.com:3306/my_db`
  - ex: `npx azimutt export "mongodb+srv://user:password@cluster3.md7h4xp.mongodb.net"`
  - ex: `npx azimutt export mysql://user:password@my.host.com:3306/my_db`
  - ex: `npx azimutt export postgresql://postgres:postgres@localhost:5432/azimutt_dev`
  - ex: `npx azimutt export snowflake://user:password@account.snowflakecomputing.com?db=my_db`
  - ex: `npx azimutt export Server=host.com,1433;Database=db;User Id=user;Password=pass`
  - `url` the database connection url, must contain everything needed (user, pass, port...)
  - `--database` is optional, restrict extraction to this database or database pattern (using %)
  - `--catalog` is optional, restrict extraction to this catalog or catalog pattern (using %)
  - `--bucket` is optional, restrict extraction to this bucket or bucket pattern (using %)
  - `--schema` is optional, restrict extraction to this schema or schema pattern (using %)
  - `--entity` is optional, restrict extraction to this entity or entity pattern (using %)
  - `--sample-size` is optional, defines how many items are used to infer a schema (for document databases or json fields)
  - `--mixed-json` is optional, split collections given the specified json field (if you have several kind of documents in the same collection)
  - `--infer-json-attributes` is optional, if JSON fields should be fetched to infer their schema
  - `--infer-polymorphic-relations` is optional, if kind field on polymorphic relations should be fetched to know all relations
  - `--infer-relations` build relations based on column names, for example a `user_id` will have a relation if a table `users` has an `id` column
  - `--ignore-errors` is optional, do not stop export on errors, just log them
  - `--log-queries` is optional, log queries when executing them
  - `--format` is optional, default to `json` but for relational database it could also be `sql`
  - `--output` is optional, database name will be inferred from url and prefixed by the timestamp
  - `--debug` allows to see the full stack trace of the error (can be helpful to debug)

## Developing

Start with `pnpm install` to install dependencies and set up the CLI, then you have:

- `pnpm run exec` launch the CLI (use `-- args` for CLI args, ex: `pnpm run exec -- export postgresql://postgres:postgres@localhost:5432/azimutt_dev`), or `pnpm run build && pnpm run exec`
- `pnpm run start` to launch it with live reload (same, use `-- args` to pass arguments to the CLI)
- `pnpm run test` to launch tests

## Publish

- update `package.json` and `src/version.ts` version
- update lib versions (`pnpm -w run update` + manual) 
- test with `pnpm run dry-publish` and check `azimutt-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks`

View it on [npm](https://www.npmjs.com/package/azimutt).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add "@azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
