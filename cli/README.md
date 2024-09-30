<p align="center">
    <a href="https://azimutt.app" target="_blank" rel="noopener">
        <picture>
          <source media="(prefers-color-scheme: dark)" srcset="assets/logo-white.png">
          <source media="(prefers-color-scheme: light)" srcset="assets/logo.png">
          <img alt="Azimutt logo" src="assets/logo.png" width="500">
        </picture>
    </a>
</p>

<p align="center">
  <a href="https://azimutt.app" target="_blank" rel="noopener">Home page</a> •
  <a href="https://www.npmjs.com/package/azimutt" target="_blank" rel="noopener">npm package</a>
</p>

Azimutt CLI ease your work with databases 😎

It works with **PostgreSQL**, **MySQL**, **MariaDB**, **SQL Server**, **Oracle**, **MongoDB**, **Couchbase**, **Snowflake**, **BigQuery** (can be extended on demand).

It's a toolbox to interact with those databases but also [AML](../libs/aml), here are the main features:

- [explore](#explore): explore your databases schema and data
- [analyze](#analyze): analyze your database and make recommendations
- [gateway](#gateway): launch a Node.js server allowing [Azimutt](https://azimutt.app) to connect to your databases
- [convert](#convert): convert database schema dialects from one to another ([AML](../libs/aml), SQL, Mermaid, Markdown...)

To use it, you need [npm](https://github.com/npm/cli), you can install it (`npm install -g azimutt`) or launch it directly (`npx azimutt@latest <command> <args>`).


## CLI Commands

### Explore

This one is just a shortcut to start the [gateway](../gateway) (like the [gateway](#gateway) command) and open [Azimutt](https://azimutt.app) with your url to explore your database, easy-peasy!

```shell
npx azimutt@latest explore <db_url>
```

Options:

- `--instance <instance>`: select the Azimutt instance to open (by default it will be https://azimutt.app)


### Analyze

Connect to your database, extract the schema, statistics and queries to run some analyses and recommend improvement actions.

```shell
npx azimutt@latest analyze <db_url>
```

You can see this as a database linter. The first time it will write a config file (by default in `~/.azimutt/analyze/$db_name/conf.json`) you can adjust later.

Options:

- `--folder <folder>`: use a specific folder for configuration and report files
- `--only <rule_ids>`: limit the used rules
- `--size <number>`: how many violations are shown for each rules
- `--ignore-violations-from <folder>`: ignores all the violations already reported in this given folder
- `--email <email>`: your email, unlocks writing the report as JSON
- `--key <key>`: unlocks trend rules, as us for a key


### Gateway

Launch the [gateway](../gateway) server, it acts as a bridge between Azimutt frontend and your database (convert HTTP queries to SQL ones ^^).

```shell
npx azimutt@latest gateway
```


### Export

Export your database schema as JSON, can be imported into [Azimutt](https://azimutt.app/new?json).  
It's convenient to check what you upload to Azimutt (even if everything stay on your browser until you save and choose).

```shell
npx azimutt@latest export <db_url>
```

Sample urls:

- PostgreSQL: `postgresql://postgres:postgres@localhost:5432/azimutt_dev`
- MySQL: `mysql://user:password@my.host.com:3306/my_db`
- MariaDB: `mariadb://user:password@my.host.com:3306/my_db`
- SQL Server: `Server=host.com,1433;Database=db;User Id=user;Password=pass`
- Oracle: `oracle:thin:system/oracle@localhost:1521/FREE`
- MongoDB: `"mongodb+srv://user:password@cluster3.md7h4xp.mongodb.net"`
- Couchbase: `couchbases://cb.gfn6dh493pmfh613v.cloud.couchbase.com`
- Snowflake: `snowflake://user:password@account.snowflakecomputing.com?db=my_db`
- BigQuery: `bigquery://bigquery.googleapis.com/my-project?key=key.json`

Options:

- `--database`: restrict extraction to this database or database pattern (uses LIKE pattern with %)
- `--catalog`: restrict extraction to this catalog or catalog pattern (uses LIKE pattern with %)
- `--bucket`: restrict extraction to this bucket or bucket pattern (uses LIKE pattern with %)
- `--schema`: restrict extraction to this schema or schema pattern (uses LIKE pattern with %)
- `--entity`: restrict extraction to this entity or entity pattern (uses LIKE pattern with %)
- `--sample-size`: defines how many items are used to infer a schema (for document databases or json fields)
- `--mixed-json`: split collections given the specified json field (if you have several kind of documents in the same collection)
- `--infer-json-attributes`: if JSON fields should be fetched to infer their schema
- `--infer-polymorphic-relations`: if kind field on polymorphic relations should be fetched to know all relations
- `--infer-relations`: build relations based on column names, for example a `user_id` will have a relation if a table `users` has an `id` column
- `--ignore-errors`: do not stop export on errors, just log them
- `--log-queries`: log queries when executing them
- `--format`: default to `json` but for relational database it could also be `sql`
- `--output`: database name will be inferred from url and prefixed by the timestamp


### Convert

Convert a dialect to another, supporting [AML](https://azimutt.app/aml), SQL (PostgreSQL for now), JSON, Markdown, Mermaid...

```shell
npx azimutt@latest convert <file_path> --from <dialect> --to <dialect>
```

Options:

- `--out <file_path>`: to choose the file to write (will be constructed otherwise)


### Diff

**(Work In Progress)**

Make a schema diff between two databases.

```shell
npx azimutt@latest <db_url_reference> <db_url_validation>
```

It will produce a JSON diff, that could be converted to SQL.


## Developing

Start with `pnpm install` to install dependencies and set up the CLI, then you have:

- `pnpm run exec` launch the CLI (use `-- args` for CLI args, ex: `npm run exec -- export postgresql://postgres:postgres@localhost:5432/azimutt_dev`), or `npm run build && npm run exec`
- `pnpm run start` to launch it with live reload (same, use `-- args` to pass arguments to the CLI)
- `pnpm run test` to launch tests

Issues:

- upgrading to typescript 5.6.2 cause the error: `TypeError: Cannot read properties of undefined (reading 'sourceFile')` when running tests :/
- importing @azimutt/aml fails as it's commonjs, not es module :/

## Publish

- update `package.json` and `src/version.ts` version
- update lib versions (`pnpm -w run update` + manual) 
- test with `pnpm run dry-publish` and check `azimutt-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks`

View it on [npm](https://www.npmjs.com/package/azimutt).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add "@azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`
