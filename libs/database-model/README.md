# @azimutt/database-model

**/!\ Work In Progress /!\ This lib will replace `database-types`, `json-infer-schema` and `shared` libs**


A library defining a standard representation for databases and common utilities.

Here are the main utilities:

- infer schema: infer a schema from a list of JSON objects
- infer relations: infer relations between tables based on column names and values

## Publish

- update `package.json` version
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-database-model-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/database-model).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `npm install <path>`, ex: `npm install ../utils`
- "Publish" lib locally by building it: `npm run build`
