# Azimutt libs

Shared libraries across several projects that could be published some time.
For now, we depend on them using local dependencies (ex: `npm install ../libs/utils`) to use them in several projects (cli, desktop, frontend...).

When developing, they need to be constructed, for this run `npm run setup`, or to build all at once, use `npm run libs:setup` from the root folder.

For each lib, look at `package.json` description to see what it does, but in short:

- `utils`: convenient additional function on base objects (array, object, promise...)
- `database-types`: basic types around the database, it's used in most other libs and projects
- `shared`: code that is not meant to be release but needs to be shared between several projects
- `json-infer-schema`: a library to infer a schema from a list of json objects
- `connector-couchbase`: extract database schema for Couchbase
- `connector-mongodb`: extract database schema for MongoDB
- `connector-mysql`: extract database schema for MySQL
- `connector-postgres`: extract database schema for PostgreSQL

If you want to improve connectors, feel free ;)
You can also create other connectors to integrate into Azimutt (MySQL, SQL Server, Oracle, SQLite...).
If you want to use such libraries in your own projects, reach at us, we can publish them on npm.

Other libs that will come:

- `parser-aml`: to parse AML language
- `parser-sql`: to parse SQL language

If you think more would be useful, again, reach out to us, we are open to extend them.
