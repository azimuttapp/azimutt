use shipping;

// drop everything
db.Carriers.drop();
db.Shipments.drop();
db.ShipmentItems.drop();


// create the collections
db.createCollection('Carriers', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["id", "registration", "cargoWidth", "cargoLength", "cargoHeight", "cargoWeight", "createdAt", "updatedAt"],
            properties: {
                id: { bsonType: "number" },
                registration: { bsonType: "string" },
                cargoWidth: { bsonType: "number" },
                cargoLength: { bsonType: "number" },
                cargoHeight: { bsonType: "number" },
                cargoWeight: { bsonType: "number" },
                createdAt: { bsonType: "date" },
                createdBy: { bsonType: "number" },
                updatedAt: { bsonType: "date" },
                updatedBy: { bsonType: "number" },
                deletedAt: { bsonType: "date" },
                deletedBy: { bsonType: "number" }
            }
        }
    }
});

db.createCollection('Shipments', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["id", "createdAt"],
            properties: {
                id: { bsonType: "number" },
                carrierId: { bsonType: "number" },
                createdAt: { bsonType: "date" },
                collectedAt: { bsonType: "date" },
                collectedBy: { bsonType: "number" },
                packagedAt: { bsonType: "date" },
                packagedBy: { bsonType: "number" },
                loadedAt: { bsonType: "date" },
                loadedBy: { bsonType: "number" },
                deliveredAt: { bsonType: "date" },
                deliveredBy: { bsonType: "number" }
            }
        }
    }
});

db.createCollection('ShipmentItems', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["shipmentId", "physicalProductId", "invoiceId", "invoiceLine"],
            properties: {
                shipmentId: { bsonType: "number" },
                physicalProductId: { bsonType: "number" },
                invoiceId: { bsonType: "number" },
                invoiceLine: { bsonType: "int" },
                deliveredAt: { bsonType: "date" },
                deliveredTo: { bsonType: "number" }
            }
        }
    }
});


// insert some data
db.Carriers.insertMany([
    {
        id: 1,
        registration: "ABC123",
        cargoWidth: 2.5,
        cargoLength: 10.0,
        cargoHeight: 3.0,
        cargoWeight: 2000.0,
        createdAt: new Date(),
        createdBy: 1,
        updatedAt: new Date(),
    },
    {
        id: 2,
        registration: "XYZ789",
        cargoWidth: 2.0,
        cargoLength: 8.0,
        cargoHeight: 2.5,
        cargoWeight: 1500.0,
        createdAt: new Date(),
        createdBy: 2,
        updatedAt: new Date(),
    }
]);

db.Shipments.insertMany([
    {
        id: 1,
        carrierId: 1,
        createdAt: new Date(),
        collectedAt: new Date(),
        collectedBy: 1,
        packagedAt: new Date(),
        packagedBy: 1,
        loadedAt: new Date(),
        loadedBy: 1,
        deliveredAt: new Date(),
        deliveredBy: 1
    },
    {
        id: 2,
        carrierId: 2,
        createdAt: new Date(),
        collectedAt: new Date(),
        collectedBy: 2,
        packagedAt: new Date(),
        packagedBy: 2,
        loadedAt: new Date(),
        loadedBy: 2,
        deliveredAt: new Date(),
        deliveredBy: 2
    }
]);

db.ShipmentItems.insertMany([
    {
        shipmentId: 1,
        physicalProductId: 1,
        invoiceId: 1,
        invoiceLine: 1,
        deliveredAt: new Date(),
        deliveredTo: 1
    },
    {
        shipmentId: 2,
        physicalProductId: 2,
        invoiceId: 2,
        invoiceLine: 1,
        deliveredAt: new Date(),
        deliveredTo: 2
    }
]);
