# @azimutt/database-types

A library allowing to infer the schema for a list of JSON documents.

It's used in Azimutt to extract schema from document databases such a Couchbase and MongoDB.

## Publish

- update `package.json` version
- update lib versions & run `npm install`
- test with `npm run dry-publish` and check `azimutt-database-types-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/database-types).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `npm install <path>`, ex: `npm install ../utils`
- "Publish" lib locally by building it: `npm run build`
