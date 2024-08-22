# MongoDB connector

This library allows to connect to [MongoDB](https://www.mongodb.com), extract its schema and more...

It browses all databases and collections, fetch a sample of documents and then infer a schema from them.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their MongoDB database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [MongoDB queries](./src/mongodb.ts) (look at `getSchema` function)
- improve [schema inference](../models/src/inferSchema.ts)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-connector-mongodb-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-mongodb).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`

## Local Setup

You can use the [MongoDB Official image](https://hub.docker.com/_/mongo):

```bash
docker run --name mongo_sample -p 27017:27017 mongo:latest
```

Connect with host (`localhost`), port (`27017`) (no user/pass) or using `mongodb://localhost:27017/mongo_sample`, then add some tables and data:

```mongo
use mongo_sample;

db.createCollection('users', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            title: "User Object Validation",
            required: ["id", "name", "role", "email", "emailConfirmed", "createdAt"],
            properties: {
                id: {bsonType: "int", minimum: 1, description: "'id' is required and must be an int"},
                name: {bsonType: "string", description: "'name' is required and must be a string"},
                role: {enum: ["admin", "guest"], description: "'role' is required and must be 'admin' or 'guest'"},
                email: {bsonType: "string", description: "'email' is required and must be a string"},
                emailConfirmed: {bsonType: "bool", description: "'emailConfirmed' is required and must be a boolean"},
                settings: {bsonType: "object", description: "'settings' must be an object is present"},
                createdAt: {bsonType: "date", description: "'createdAt' is required and must be a date"},
            }
        }
    }
});
db.createCollection('posts', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            title: "Post Object Validation",
            required: ["id", "title", "createdAt", "createdBy"],
            properties: {
                id: {bsonType: "int", minimum: 1, description: "'id' is required and must be an int"},
                title: {bsonType: "string", description: "'title' is required and must be a string"},
                content: {bsonType: "string", description: "'content' must be a string if present"},
                createdAt: {bsonType: "date", description: "'createdAt' is required and must be a date"},
                createdBy: {bsonType: "int", minimum: 1, description: "'createdBy' is required and must be an int"},
                authors: {bsonType: "array", additionalProperties: false, items: {
                    bsonType: "object",
                    additionalProperties: false,
                    required: ["userId"],
                    properties: {
                        userId: {bsonType: "int", minimum: 1, description: "'userId' is required and must be an int"},
                        role: {enum: ["author", "editor"], description: "'role' must be 'author' or 'editor' if present"},
                    },
                }}
            }
        }
    }
});
db.createCollection('ratings', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            title: "Rating Object Validation",
            required: ["userId", "itemKind", "itemId", "rating"],
            properties: {
                userId: {bsonType: "int", minimum: 1, description: "'userId' is required and must be an int"},
                itemKind: {enum: ["posts", "users"], description: "'itemKind' is required and must be 'posts' or 'users'"},
                itemId: {bsonType: "int", minimum: 1, description: "'itemId' is required and must be an int"},
                rating: {bsonType: "int", minimum: 0, maximum: 5, description: "'rating' is required and must be an int between 0 and 5"},
                review: {bsonType: "string", description: "'review' must be a string if present"},
            }
        }
    }
});


// Insert data
db.users.insertOne({id: 1, name: "Loïc", role: "admin", email: "loic@mail.com", emailConfirmed: true, settings: {"color": "red", "plan": {"id": 1, "name": "pro"}}, createdAt: new Date()});
db.users.insertOne({id: 2, name: "Jean", role: "guest", email: "jean@mail.com", emailConfirmed: false, createdAt: new Date()});
db.users.insertOne({id: 3, name: "Luc", role: "guest", email: "luc@mail.com", emailConfirmed: true, createdAt: new Date()});
db.posts.insertOne({id: 1, title: "MongoDB connector", createdAt: new Date(), createdBy: 1, authors: [{userId: 1, role: "author"}, {userId: 2}]});
db.ratings.insertOne({userId: 3, itemKind: "posts", itemId: 1, rating: 4});
db.ratings.insertOne({userId: 3, itemKind: "users", itemId: 1, rating: 5});
```

Remove everything with:

```mongo
db.ratings.drop();
db.posts.drop();
db.users.drop();
```

## Cloud Setup

- Go on https://www.mongodb.com and click on "Try free" to create your Atlas account (MongoDB in the cloud)
- Follow the onboarding to create a database user and whitelist your IP, if you missed them, go on:
  - In `Data Services > Database Access`: Create database user
  - In `Data Services > Network Access`: Allow your IP address
- Get your connection url with the "Connect" button, ex: `mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net`
- Load sample dataset (as suggested in the UI)
