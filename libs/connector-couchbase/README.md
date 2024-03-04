# Couchbase connector

This library allows to connect to [Couchbase](https://www.couchbase.com), extract its schema and more...

It browses all buckets, scopes and collections, fetch a sample of documents and then infer a schema from them.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their Couchbase database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [Couchbase queries](./src/couchbase.ts) (look at `getSchema` function)
- improve [schema inference](../database-types/src/inferSchema.ts)

## Set up a sample Couchbase database

- Go on https://www.couchbase.com and click on "Explore Now" and then "Get Started" to create your Capella account (Couchbase in the cloud)
- Once your account is created, you have 2 needed configurations:
  - In `Settings > Internet`: Allow your IP address
  - In `Settings > Database Access`: Create database access
- Build you connection url: `couchbases://<user>:<password>@<connection string>`, ex: `couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com`

## Publish

- update `package.json` version
- update lib versions (`npm run update` + manual) & run `npm install`
- test with `npm run dry-publish` and check `azimutt-connector-couchbase-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-couchbase).
