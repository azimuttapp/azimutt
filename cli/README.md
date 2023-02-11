# Azimutt CLI

This CLI is aimed at helping work with [Azimutt](https://azimutt.app), a database exploration tool.

For now, it focuses on allowing you to export several databases in order to explore their schema in Azimutt.
The CLI supports: PostgreSQL, MongoDB and Couchbase.

Use this CLI without installing it thanks to [npx](https://www.npmjs.com/package/npx): `npx azimutt-cli`.

Get the help simply by running the CLI (`npx azimutt-cli`) or for a specific command: `npx azimutt-cli help export` for example.

## Available commands

- **export** (`npx azimutt-cli export <kind> <url>`)
  - ex: `npx azimutt-cli export mongodb mongodb://mongodb0.example.com:27017`
  - `kind` the database type you want to export (postgres, mongodb or couchbase)
  - `url` the database connection url, must contain everything needed (user, pass, port...)
  - `database` is optional, restrict schema extraction to this database
  - `schema` is optional, restrict schema extraction to this schema
  - `bucket` is optional, restrict schema extraction to this bucket
  - `sample-size` defines how many items are used to infer a schema (for document databases)
  - `raw-schema` writes another file with the intermediary representation of the database schema (more details & specificities)
  - `infer-relations` build relations based on column names, for example a `user_id` will have a relation if a table `users` has an `id` column
  - `flatten` nested objects in specified levels, may be useful for document databases
  - `format` is optional, default to `json` but for relational database it could also be `sql`
  - `output` is optional, database name will be inferred from url and prefixed by the timestamp
  - `debug` allows to see the full stack trace of the error (can be helpful to debug)

## Developing

Start with `npm run init` to install dependencies and set up the CLI, then you have:

- `npm run exec` to compile and launch the CLI (use `-- args` for CLI args, ex: `npm run exec -- --url mongodb://mongodb0.example.com:27017`), or `npm run build && node lib/index.js`
- `npm run start` to launch it with live reaload (same, use `-- args` to pass arguments to the CLI)
- `npm run test` to launch tests

## Publish

- connect to npm account
- update `package.json` version
- test with `npm run prepublish` and check `azimutt-cli-x.y.z.tgz` content
- launch `npm publish`
