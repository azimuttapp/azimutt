# E-commerce demo

This demo has 77 tables and 9 databases of different kind to highlight real-world capabilities of Azimutt:

- plays well with many tables (even several thousands)
- is great for documentation with layouts, memos and notes
- allows schema and data exploration, at the same time
- works with several db, but also cross-db 🤯

You can [access the demo directly on Azimutt](https://azimutt.app/45f571a6-d9b8-4752-8a13-93ac0d2b7984/c00d0c45-8db2-46b7-9b51-eba661640c3c?token=59166798-32de-4f46-a1b4-0f7327a91336) to explore the documentation about:

- global overview of the schema across all databases (PostgreSQL, MySQL, MariaDB, SQL Server, Oracle and MongoDB)
- each domain with schema & data showcase
- more documentation about use cases and a **getting started tutorial** to guide you through Azimutt features

For data exploration, you will have to [launch the databases with Docker](#launch-databases-with-docker) and start the local gateway with [npm](https://www.npmjs.com) (`npx azimutt@latest gateway`). After that, you will be able to explore the data yourself 🥳


## Launch databases with Docker

- [Referential database](#referential-database)
- [Identity database](#identity-database)
- [Inventory database](#inventory-database)
- [Catalog database](#catalog-database)
- [Shopping database](#shopping-database)
- [Billing database](#billing-database)
- [Shipping database](#shipping-database)
- [CRM database](#crm-database)
- [Analytics database](#analytics-database)

Tip: list all your containers: `docker ps -a` (see which ones are created/started)


### Referential database

Launch **SQL Server** with Docker (more details on [SQL Server connector](../../libs/connector-sqlserver/README.md#local-setup)):

```bash
docker run --name mssql_sample -p 1433:1433 -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=azimutt_42 -e MSSQL_PID=Evaluation mcr.microsoft.com/mssql/server:2022-latest
```

Then connect to it using `sqlserver://sa:azimutt_42@localhost:1433/Referential` and run the [source_01_referential_sqlserver.sql](./source_01_referential_sqlserver.sql) loading script.

If already created, start the container with `docker start mssql_sample`.


### Identity database

Launch **MariaDB** with Docker (more details on [MariaDB connector](../../libs/connector-mariadb/README.md#local-setup)):

```bash
docker run --name mariadb_sample -p 3307:3306 -e MARIADB_ROOT_PASSWORD=mariadb -e MARIADB_USER=azimutt -e MARIADB_PASSWORD=azimutt -e MARIADB_DATABASE=mariadb_sample mariadb:latest
```

Then connect to it using `mariadb://root:mariadb@localhost:3307/identity` and run the [source_02_identity_mariadb.sql](./source_02_identity_mariadb.sql) loading script.

If already created, start the container with `docker start mariadb_sample`.


### Inventory database

Launch **Oracle** with Docker (more details on [Oracle connector](../../libs/connector-oracle/README.md#local-setup)):

```bash
docker run --name oracle_sample -p 1521:1521 -e ORACLE_PWD=oracle container-registry.oracle.com/database/free:23.4.0.0-lite
```

Then connect to it using `oracle:thin:C##INVENTORY/inventory@localhost:1521/FREE` and run the [source_03_inventory_oracle.sql](./source_03_inventory_oracle.sql) loading script.

If already created, start the container with `docker start oracle_sample`.


### Catalog database

Launch **PostgreSQL** with Docker (more details on [PostgreSQL connector](../../libs/connector-postgres/README.md#local-setup)):

```bash
docker run --name postgres_sample -p 5433:5432 -e POSTGRES_PASSWORD=postgres postgres:latest
```

Then connect to it using `postgresql://postgres:postgres@localhost:5433/postgres?schema=catalog` and run the [source_04_catalog_postgres.sql](./source_04_catalog_postgres.sql) loading script.

If already created, start the container with `docker start postgres_sample`.


### Shopping database

Launch **PostgreSQL** with Docker (more details on [PostgreSQL connector](../../libs/connector-postgres/README.md#local-setup)):

```bash
docker run --name postgres_sample -p 5433:5432 -e POSTGRES_PASSWORD=postgres postgres:latest
```

Then connect to it using `postgresql://postgres:postgres@localhost:5433/postgres?schema=shopping` and run the [source_05_shopping_postgres.sql](./source_05_shopping_postgres.sql) loading script.

If already created, start the container with `docker start postgres_sample`.


### Billing database

Launch **SQL Server** with Docker (more details on [SQL Server connector](../../libs/connector-sqlserver/README.md#local-setup)):

```bash
docker run --name mssql_sample -p 1433:1433 -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=azimutt_42 -e MSSQL_PID=Evaluation mcr.microsoft.com/mssql/server:2022-latest
```

Then connect to it using `sqlserver://sa:azimutt_42@localhost:1433/Billing` and run the [source_06_billing_sqlserver.sql](./source_06_billing_sqlserver.sql) loading script.

If already created, start the container with `docker start mssql_sample`.


### Shipping database

Launch **MongoDB** with Docker (more details on [MongoDB connector](../../libs/connector-mongodb/README.md#local-setup)):

```bash
docker run --name mongo_sample -p 27017:27017 mongo:latest
```

Then connect to it using `mongodb://localhost:27017/shipping` and run the [source_07_shipping_mongo.sql](./source_07_shipping_mongo.sql) loading script.

If already created, start the container with `docker start mongo_sample`.


### CRM database

Launch **MySQL** with Docker (more details on [MySQL connector](../../libs/connector-mysql/README.md#local-setup)):

```bash
docker run --name mysql_sample -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql -e MYSQL_USER=azimutt -e MYSQL_PASSWORD=azimutt -e MYSQL_DATABASE=mysql_sample mysql:latest
```

Then connect to it using `mysql://root:mysql@localhost:3306/crm` and run the [source_08_crm_mysql.sql](./source_08_crm_mysql.sql) loading script.

If already created, start the container with `docker start mysql_sample`.


### Analytics database

Launch **MongoDB** with Docker (more details on [MongoDB connector](../../libs/connector-mongodb/README.md#local-setup)):

```bash
docker run --name mongo_sample -p 27017:27017 mongo:latest
```

Then connect to it using `mongodb://localhost:27017/analytics` and run the [source_09_analytics_mongo.sql](./source_09_analytics_mongo.sql) loading script.

If already created, start the container with `docker start mongo_sample`.


## Improvements

Add more tables, data and database kind. Would be nice to move from 77 table to ~150-200 to show a large scale usage.

New areas:

- Devices: embedded devices for inventory employees => Couchbase
- Marketplace: what others have to sell (Merchant, ...) => Snowflake
