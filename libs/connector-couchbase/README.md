# Couchbase connector

This library is able to connect to [Couchbase](https://www.couchbase.com) and extract its schema.

It browses all buckets, scopes and collections, fetch a sample of documents and then [infer](../json-infer-schema) a schema from them.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their Couchbase database. It's accessible through the [Desktop app](../../desktop), the [CLI](../../cli) or even the website using a gateway server.

**Feel free to use it and even submit PR to improve it:**

- improve [Couchbase queries](./src/couchbase.ts) (look at `getSchema` function)
- improve [schema inference](../json-infer-schema)

## Set up a sample Couchbase database

- Go on https://www.couchbase.com and click on "Explore Now" and then "Get Started" to create your Capella account (Couchbase in the cloud)
- Once your account is created, you have 2 needed configurations:
  - In `Settings > Internet`: Allow you IP address
  - In `Settings > Database Access`: Create database access
- Build you connection url: `couchbases://<user>:<password>@<connection string>`, ex: `couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com`
