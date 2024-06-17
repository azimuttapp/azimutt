# @azimutt/serde-dbml

This lib is made to parse and generate [DBML](https://dbml.dbdiagram.io) from/to the Azimutt [database model](../models).

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-serde-dbml-x.y.z.tgz` content
- launch `pnpm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/serde-dbml).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
