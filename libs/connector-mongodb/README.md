# MongoDB connector

This library is able to connect to [MongoDB](https://www.mongodb.com) and extract its schema.

It browses all databases and collections, fetch a sample of documents and then [infer](../json-infer-schema) a schema from them.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their MongoDB database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using a the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [MongoDB queries](./src/mongodb.ts) (look at `getSchema` function)
- improve [schema inference](../json-infer-schema)

## Set up a sample MongoDB database

- Go on https://www.mongodb.com and click on "Try free" to create your Atlas account (MongoDB in the cloud)
- Follow the onboarding to create a database user and whitelist your IP, if you missed them, go on:
  - In `Data Services > Database Access`: Create database user
  - In `Data Services > Network Access`: Allow you IP address
- Get your connection url with the "Connect" button, ex: `mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net`
- Load sample dataset (as suggested in the UI)

## Publish

- update `package.json` version
- test with `npm run dry-publish` and check `azimutt-connector-mongodb-x.y.z.tgz` content
- launch `npm publish --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-mongodb).
