# Azimutt CLI

This CLI is aimed at helping you work with databases, and more specifically (for now) exploring their schema.
It works with SQL ones like **PostgreSQL** but also document ones like **MongoDB** or **Couchbase** 🎉

The schema can be easily imported to [Azimutt](https://azimutt.app) to explore it seamlessly.

Use this CLI without installing it thanks to [npx](https://www.npmjs.com/package/npx): `npx azimutt`.

Get the help simply by running the CLI (`npx azimutt`) or for a specific command using `npx azimutt help export` for example.

## Available commands

- **export** (`npx azimutt export <kind> <url> [arguments]`)
  - ex: `npx azimutt export couchbase couchbases://cb.gfn6dh493pmfh613v.cloud.couchbase.com`
  - ex: `npx azimutt export mongodb "mongodb+srv://user:password@cluster3.md7h4xp.mongodb.net"`
  - ex: `npx azimutt export postgres postgresql://postgres:postgres@localhost:5432/azimutt_dev`
  - `kind` the database type you want to export (postgres, mongodb or couchbase)
  - `url` the database connection url, must contain everything needed (user, pass, port...)
  - `--database` is optional, restrict schema extraction to this database
  - `--schema` is optional, restrict schema extraction to this schema
  - `--bucket` is optional, restrict schema extraction to this bucket
  - `--sample-size` defines how many items are used to infer a schema (for document databases)
  - `--infer-relations` build relations based on column names, for example a `user_id` will have a relation if a table `users` has an `id` column
  - `--format` is optional, default to `json` but for relational database it could also be `sql`
  - `--output` is optional, database name will be inferred from url and prefixed by the timestamp
  - `--debug` allows to see the full stack trace of the error (can be helpful to debug)

## Developing

Start with `npm run setup` to install dependencies and set up the CLI, then you have:

- `npm run exec` to compile and launch the CLI (use `-- args` for CLI args, ex: `npm run exec -- export postgres postgresql://postgres:postgres@localhost:5432/azimutt_dev`), or `npm run build && node lib/index.js`
- `npm run start` to launch it with live reload (same, use `-- args` to pass arguments to the CLI)
- `npm run test` to launch tests

## Publish

- connect to npm account
- update `package.json` version
- test with `npm run drypublish` and check `azimutt-x.y.z.tgz` content
- launch `npm publish`
