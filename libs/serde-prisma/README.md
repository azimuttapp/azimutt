# @azimutt/serde-prisma

This lib is able to parse and generate [Prisma Schema](https://www.prisma.io/docs/orm/prisma-schema) from/to an [Azimutt database model](../models).

**Feel free to use it and even submit PR to improve it:**

- improve [Prisma parser & generator](./src/prisma.ts) (look at `parse` and `generate` functions)

## Publish

- update `package.json` version
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-serde-prisma-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/serde-prisma).
