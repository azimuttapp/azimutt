# Azimutt full demo

Here are some technical explanations to setup the [e-commerce micro-services demo](https://azimutt.app/fe9aef15-febe-490b-a631-225367749278/91395eb9-bd5d-4205-a8d6-d03bd1968ec4) of Azimutt.

Have a look to the [associated blog](https://azimutt.app/blob/ecommerce-database-with-microservices-demo) post for more explanations of how to use it and what to look ;)

Each domain has its own database, here is how to set them up:

# Domains

## Referential

This domain is for general data.

Import it in a [SQL Server database](../../libs/connector-sqlserver/README.md#local-setup) with the [source_01_referential_sqlserver.sql](./source_01_referential_sqlserver.sql).
You will have it at this url: `sqlserver://sa:azimutt_42@localhost:1433/Referential`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Identity

This domain is user identity: who they are, what they can do.

Import it in a [MariaDB database](../../libs/connector-mariadb/README.md#local-setup) with the [source_02_identity_mariadb.sql](./source_02_identity_mariadb.sql).
You will have it at this url: `mariadb://root:mariadb@localhost:3307/identity`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Inventory

Import it in a [Oracle database](../../libs/connector-oracle/README.md#local-setup) with the [source_03_inventory_oracle.sql](./source_03_inventory_oracle.sql).
You will have it at this url: `oracle:thin:C##INVENTORY/inventory@localhost:1521/FREE`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Catalog

Import it in a [PostgreSQL database](../../libs/connector-postgres/README.md#local-setup) with the [source_04_catalog_postgres.sql](./source_04_catalog_postgres.sql).
You will have it at this url: `postgresql://postgres:postgres@localhost:5433/postgres?schema=catalog`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Shopping

Import it in a [PostgreSQL database](../../libs/connector-postgres/README.md#local-setup) with the [source_05_shopping_postgres.sql](./source_05_shopping_postgres.sql).
You will have it at this url: `postgresql://postgres:postgres@localhost:5433/postgres?schema=shopping`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Billing

Import it in a [SQL Server database](../../libs/connector-sqlserver/README.md#local-setup) with the [source_06_billing_sqlserver.sql](./source_06_billing_sqlserver.sql).
You will have it at this url: `sqlserver://sa:azimutt_42@localhost:1433/Billing`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Shipping

Import it in a [MongoDB database](../../libs/connector-mongodb/README.md#local-setup) with the [source_07_shipping_mongo.sql](./source_07_shipping_mongo.sql).
You will have it at this url: `mongodb://localhost:27017/shipping`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## CRM

Import it in a [MySQL database](../../libs/connector-mysql/README.md#local-setup) with the [source_08_crm_mysql.sql](./source_08_crm_mysql.sql).
You will have it at this url: `mysql://root:mysql@localhost:3306/crm`

You can then import it in your Azimutt project or explore it with the e-commerce demo after starting your local gateway (`npx azimutt@latest gateway`)

## Analytics
