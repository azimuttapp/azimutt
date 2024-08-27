# E-commerce demo

This is a medium demo (~80 tables) showcasing Azimutt ability to explore large schemas, even with several databases (micro-services for examples).

You can find this project directly on [Azimutt](https://azimutt.app...) and explore it yourself, you will see:

- an overview of the schema across several databases
- showcases per domain with sample rows
- documentation layouts

The project will let you access the schema and loaded data but if you want to dig into the data, you will have to set up the databases you want using Docker:

- **Referential** needs [SQL Server](../../libs/connector-sqlserver/README.md#local-setup) with [referential script](./source_01_referential_sqlserver.sql) (url `sqlserver://sa:azimutt_42@localhost:1433/Referential`)
- **Identity** needs [MariaDB](../../libs/connector-mariadb/README.md#local-setup) with [identity script](./source_02_identity_mariadb.sql) (url `mariadb://root:mariadb@localhost:3307/identity`)
- **Inventory** needs [Oracle](../../libs/connector-oracle/README.md#local-setup) with [inventory script](./source_03_inventory_oracle.sql) (url `oracle:thin:C##INVENTORY/inventory@localhost:1521/FREE`)
- **Catalog** needs [PostgreSQL](../../libs/connector-postgres/README.md#local-setup) with [catalog script](./source_04_catalog_postgres.sql) (url `postgresql://postgres:postgres@localhost:5433/postgres?schema=catalog`)
- **Shopping** needs [PostgreSQL](../../libs/connector-postgres/README.md#local-setup) with [shopping script](./source_05_shopping_postgres.sql) (url `postgresql://postgres:postgres@localhost:5433/postgres?schema=shopping`)
- **Billing** needs [SQL Server](../../libs/connector-sqlserver/README.md#local-setup) with [billing script](./source_06_billing_sqlserver.sql) (url `sqlserver://sa:azimutt_42@localhost:1433/Billing`)
- **Shipping** needs [MongoDB](../../libs/connector-mongodb/README.md#local-setup) with [shipping script](./source_07_shipping_mongo.sql) (url `mongodb://localhost:27017/shipping`)
- **CRM** needs [MySQL](../../libs/connector-mysql/README.md#local-setup) with [crm script](./source_08_crm_mysql.sql) (url `mysql://root:mysql@localhost:3306/crm`)
- **Analytics** needs [MongoDB](../../libs/connector-mongodb/README.md#local-setup) with [analytics script](./source_09_analytics_mongo.sql) (url `mongodb://localhost:27017/analytics`)

Once your database(s) are set up, you can launch the local gateway (`npx azimutt@latest gateway`) and navigate the project data or set up your own.
