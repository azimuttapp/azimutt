use shipping;

// drop everything
db.ShipmentItems.drop();
db.Shipments.drop();
db.Carriers.drop();


// create the collections
db.createCollection('Carriers', {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["id", "registration", "licensePlate", "cargoWidth", "cargoLength", "cargoHeight", "cargoWeight", "createdAt", "updatedAt"],
            properties: {
                id: { bsonType: "number" },
                registration: { bsonType: "string" },
                licensePlate: { bsonType: "string" },
                cargoWidth: { bsonType: "number", description: "inner cargo width in millimeters" },
                cargoLength: { bsonType: "number", description: "inner cargo length in millimeters" },
                cargoHeight: { bsonType: "number", description: "inner cargo height in millimeters" },
                cargoWeight: { bsonType: "number", description: "maximum weight for the cargo, in kilograms" },
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
db.Carriers.createIndex({ registration: 1 });

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
                deliveredTo: { bsonType: "number", description: "the User who got the delivered package" }
            }
        }
    }
});
db.ShipmentItems.createIndex({ shipmentId: 1 });
db.ShipmentItems.createIndex({ invoiceId: 1 });


// insert some data
db.Carriers.insertMany([
    {_id: ObjectId("66cb179dfdd0405e567c1938"), id: 1, registration: "KR123456789", licensePlate: "KR-PLATE-001", cargoWidth: 2500, cargoLength: 12000, cargoHeight: 3000, cargoWeight: 24000, createdAt: new Date(), createdBy: 24, updatedAt: new Date(), updatedBy: 24},
    {_id: ObjectId("66cb179dfdd0405e567c1939"), id: 2, registration: "KR987654321", licensePlate: "KR-PLATE-002", cargoWidth: 2600, cargoLength: 13000, cargoHeight: 3200, cargoWeight: 25000, createdAt: new Date(), createdBy: 24, updatedAt: new Date(), updatedBy: 24},
    {_id: ObjectId("66cb179dfdd0405e567c193a"), id: 3, registration: "KR112233445", licensePlate: "KR-PLATE-003", cargoWidth: 2400, cargoLength: 11500, cargoHeight: 2900, cargoWeight: 23000, createdAt: new Date(), createdBy: 24, updatedAt: new Date(), updatedBy: 24},
    {_id: ObjectId("66cb179dfdd0405e567c193b"), id: 4, registration: "KR556677889", licensePlate: "KR-PLATE-004", cargoWidth: 2550, cargoLength: 12500, cargoHeight: 3100, cargoWeight: 24500, createdAt: new Date(), createdBy: 24, updatedAt: new Date(), updatedBy: 24},
]);

db.Shipments.insertMany([
    {_id: ObjectId("66cb17a0fdd0405e567c193d"), id: 1, carrierId: 1, createdAt: new Date(), collectedAt: new Date(), collectedBy: 14, packagedAt: new Date(), packagedBy: 14, loadedAt: new Date(), loadedBy: 24, deliveredAt: new Date(), deliveredBy: 24},
]);

db.ShipmentItems.insertMany([
    {_id: ObjectId("66cb17a3fdd0405e567c193f"), shipmentId: 1, physicalProductId: 1, invoiceId: 1, invoiceLine: 1, deliveredAt: new Date(), deliveredTo: 102},
    {_id: ObjectId("66cb17a3fdd0405e567c1940"), shipmentId: 1, physicalProductId: 4, invoiceId: 1, invoiceLine: 2, deliveredAt: new Date(), deliveredTo: 102},
    {_id: ObjectId("66cb17a3fdd0405e567c1941"), shipmentId: 1, physicalProductId: 12, invoiceId: 1, invoiceLine: 3, deliveredAt: new Date(), deliveredTo: 102},
    {_id: ObjectId("66cb17a3fdd0405e567c1942"), shipmentId: 1, physicalProductId: 17, invoiceId: 1, invoiceLine: 4, deliveredAt: new Date(), deliveredTo: 102},
]);
