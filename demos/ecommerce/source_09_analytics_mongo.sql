use analytics;

// drop everything
db.Events.drop();
db.Entities.drop();


// create the collections
db.createCollection('Events', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["id", "name", "source", "createdAt"],
            properties: {
                id: { bsonType: "binData", description: "UUIDv7" },
                name: { bsonType: "string", description: "Name of the event in form of `$context__$object__$action`" },
                source: { bsonType: "string", enum: ["website", "app", "admin", "job"], description: "The name of the system which emitted this event" },
                details: { bsonType: "object", description: "Additional info for the event in JSON format" },
                entities: {
                    bsonType: "object",
                    description: "Entities related to the event in JSON format",
                    additionalProperties: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["id", "name"],
                            properties: {
                                id: { bsonType: "string" },
                                name: { bsonType: "string" }
                            }
                        }
                    }
                },
                createdAt: { bsonType: "date", description: "Timestamp when the event was created" }
            }
        }
    }
});

db.createCollection('Entities', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["kind", "id", "name", "properties", "createdAt", "updatedAt"],
            properties: {
                kind: { bsonType: "string", description: "Type of the entity" },
                id: { bsonType: "string", description: "Unique identifier for the entity, for its kind" },
                name: { bsonType: "string", description: "Name of the entity" },
                properties: { bsonType: "object", description: "Additional properties for the entity in JSON format" },
                createdAt: { bsonType: "date", description: "Timestamp when the entity was created" },
                updatedAt: { bsonType: "date", description: "Timestamp when the entity was last updated" }
            }
        }
    }
});


// insert some data
db.Events.insertMany([
    {
        id: UUID(),
        name: "user__login__success",
        source: "website",
        details: { ip: "192.168.1.1", browser: "Chrome" },
        entities: { user: [{ id: "1", name: "Loïc Knuchel", email: "loic@azimutt.app" }] },
        createdAt: new Date()
    },
    {
        id: UUID(),
        name: "order__purchase__completed",
        source: "app",
        details: { amount: 200 },
        entities: {
            user: [{ id: "1", name: "Loïc Knuchel" }],
            cart: [{ id: "1", name: "Cart 1", items: 2 }],
            invoice: [{ id: "1", name: "INV-001", price: 200, currency: "USD", lines: 1 }],
        },
        createdAt: new Date()
    }
]);

db.Entities.insertMany([
    {
        kind: "user",
        id: "1",
        name: "Loïc Knuchel",
        properties: { email: "loic@azimutt.app" },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        kind: "cart",
        id: "1",
        name: "Cart 1",
        properties: { items: 2 },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        kind: "invoice",
        id: "1",
        name: "INV-001",
        properties: { price: 200, currency: "USD", lines: 1 },
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);
