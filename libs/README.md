# Azimutt libs

Published libs used in Azimutt:

- [utils](./utils): basic helpers functions on basic objects (string, array, object, promise...) (`npm i @azimutt/utils`)
- [models](./models): define shared models for Azimutt (database, project), interfaces (connector, serde) and utils (infer schema, infer relations) (`npm i @azimutt/models`)
- [aml](./aml): simple DSL to define database schemas (parser/generator) (`npm i @azimutt/aml`)
- [connector-*](./connector-postgres): database specific connector following [connector](./models/src/interfaces/connector.ts) interface (`npm i @azimutt/connector-postgres`)
- [serde-*](./serde-dbml): parser/generator for other languages following [serde](./models/src/interfaces/serde.ts) interface (`npm i @azimutt/serde-dbml`)

More details in each lib README, feel free to contribute ;)
