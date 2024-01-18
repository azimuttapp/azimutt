# SQL parser

This library parses SQL queries and format them in JSON for Azimutt.
The goal is not to make an exhaustive parser but to extract meaningful information.
Feel free to suggest improvements or submit PR.

## Publish

- update `package.json` version
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-parser-sql-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/parser-sql).
