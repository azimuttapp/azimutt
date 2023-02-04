# Azimutt CLI

This CLI is aimed at helping work with Azimutt and extend its capabilities.

## Commands

- **export**, ex: `azimutt export --url "mongodb://mongodb0.example.com:27017" --flatten 1 --infer-relations --output ~/azimutt.json`
  - for now, it **only works with PostgreSQL & MongoDB**, but could be expanded on demand ;)
  - `kind` is optional, can be inferred from `url`
  - `database` is optional, restrict schema extraction to this database
  - `schema` is optional, restrict schema extraction to this schema
  - `bucket` is optional, restrict schema extraction to this bucket
  - `sample-size` defines how many items are used to infer a schema
  - `raw-schema` writes another file with the intermediary representation of the database schema (more details & specificities)
  - `flatten` nested objects in specified levels, may be useful for document databases
  - `infer-relations` flag build relations based on column names, for example a `user_id` will have a relation if a table `users` has an `id` column
  - `format` is optional, default to `json` but for relational database it could also be `sql`
  - `output` is optional, database name will be inferred from url and prefixed by the timestamp

## Developing

Start with `npm run init` to install dependencies and set up the CLI, then you have:

- `npm run exec` to compile and launch the CLI (use `-- args` for CLI args, ex: `npm run exec -- --url mongodb://mongodb0.example.com:27017`), or `npm run build && node lib/index.js`
- `npm run start` to launch it with live reaload (same, use `-- args` to pass arguments to the CLI)
- `npm run test` to launch tests
