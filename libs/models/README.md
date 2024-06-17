# @azimutt/models

A library defining common models and utilities for Azimutt.

Main models:

- [database](src/database.ts): defines a generic database infos (structure & stats), used for every connector and serde
- [project](src/project.ts): defines an Azimutt project, holding everything
- [connector](src/interfaces/connector.ts): defines the interface to connect to any database
- [serde](src/interfaces/serde.ts): defines the interface to parse and generate database schema

Here are the main utilities:

- [infer schema](src/inferSchema.ts): infer a schema from a list of JSON objects
- [infer relations](src/inferRelations.ts): infer relations between tables based on column names and values

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-models-x.y.z.tgz` content
- launch `pnpm publish azimutt-models-x.y.z.tgz --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/models).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/utils`
- "Publish" lib locally by building it: `pnpm run build`
