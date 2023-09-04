In this folder we set up several databases with default schema and data to serve as example for database access & data exploration.
We could also set up some integration tests with them...

Start them with: `docker compose up -d`
Stop them with: `docker compose down`
Start only one: `docker compose up <service>`
Check which services are running: `docker ps`

Connection urls:
- Couchbase:
- MariaDB:
- MongoDB:
- MySQL: `mysql://mysql:mysql@localhost:3306/azimutt_sample`
- PostgreSQL: `postgres://postgres:postgres@localhost:5432/azimutt_sample`
- SQL Server:

Each database has an "interesting" database to experiment Azimutt features.
