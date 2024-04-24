# @azimutt/serde-sql

This lib is able to parse and generate SQL from/to a [database model](../models).

It's not meant to be an exhaustive parser but to extract and generate meaningful information.

It supports several dialects.

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual) 
- test with `pnpm run dry-publish` and check `azimutt-serde-sql-x.y.z.tgz` content
- launch `pnpm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/serde-sql).
