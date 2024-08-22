# SQL Server connector

This library allows to connect to [SQL Server](https://www.microsoft.com/fr-fr/sql-server/sql-server-downloads), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their SQL Server database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [SQL Server queries](./src/sqlserver.ts) (look at `getSchema` function)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-connector-sqlserver-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-sqlserver).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`

## Local Setup

You can use the [SQL Server Official image](https://hub.docker.com/r/microsoft/mssql-server):

```bash
docker run --name mssql_sample -p 1433:1433 -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=azimutt_42 -e MSSQL_PID=Evaluation mcr.microsoft.com/mssql/server:2022-latest
```

Connect with host (`localhost`), port (`1433`), user (`sa`) and pass (`azimutt_42`) or using `sqlserver://sa:azimutt_42@localhost:1433/master` or `Server=localhost,1433;User Id=sa;Password=azimutt_42;Database=master`, then add some tables and data:

```tsql
CREATE TABLE users (
    id              BIGINT PRIMARY KEY IDENTITY (1,1),
    name            VARCHAR(50)        NOT NULL,
    role            VARCHAR(10)        NOT NULL,
    email           VARCHAR(255)       NOT NULL,
    email_confirmed BIT      DEFAULT 0 NOT NULL,
    settings        NVARCHAR(MAX) CHECK (ISJSON([settings]) = 1),
    created_at      DATETIME DEFAULT GETDATE(),
    CONSTRAINT users_lower_email_chk CHECK (email = LOWER(email)),
    CHECK (name <> email)
);
EXEC sp_addextendedproperty 'MS_Description', 'List all users', 'SCHEMA', 'dbo', 'TABLE', 'users';
EXEC sp_addextendedproperty 'MS_Description', 'The user name', 'SCHEMA', 'dbo', 'TABLE', 'users', 'COLUMN', 'name';
CREATE UNIQUE INDEX users_email_uniq ON users (email);
CREATE INDEX users_role_idx ON users (role);
ALTER TABLE users ADD vPlan AS JSON_VALUE(settings, '$.plan.name');
CREATE INDEX users_plan_idx ON users (vPlan);
ALTER TABLE users ADD vColor AS JSON_VALUE(settings, '$.color');
CREATE INDEX users_full_idx ON users (name, email, vPlan, vColor);

CREATE VIEW admins AS SELECT id, name, email FROM users WHERE role = 'admin';
EXEC sp_addextendedproperty 'MS_Description', 'Only admins', 'SCHEMA', 'dbo', 'VIEW', 'admins';

CREATE VIEW guests AS SELECT id, name, email FROM users WHERE role = 'guest';
EXEC sp_addextendedproperty 'MS_Description', 'Only guests', 'SCHEMA', 'dbo', 'VIEW', 'guests';


CREATE TABLE posts (
    id         BIGINT PRIMARY KEY IDENTITY (1,1),
    title      VARCHAR(50) NOT NULL,
    content    NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    created_by BIGINT      NOT NULL,
    CONSTRAINT posts_created_by_fk FOREIGN KEY (created_by) REFERENCES users (id)
);

CREATE TABLE post_authors (
    post_id BIGINT,
    user_id BIGINT,
    CONSTRAINT post_authors_pk PRIMARY KEY (post_id, user_id),
    CONSTRAINT post_authors_post_id_fk FOREIGN KEY (post_id) REFERENCES posts (id),
    CONSTRAINT post_authors_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE post_author_details (
    detail_post_id BIGINT,
    detail_user_id BIGINT,
    role           VARCHAR(10) NOT NULL,
    CONSTRAINT post_author_details_pk PRIMARY KEY (detail_post_id, detail_user_id),
    CONSTRAINT post_author_details_post_user_fk FOREIGN KEY (detail_post_id, detail_user_id) REFERENCES post_authors (post_id, user_id)
);

CREATE TABLE ratings (
    user_id   BIGINT      NOT NULL,
    item_kind VARCHAR(50) NOT NULL,
    item_id   BIGINT      NOT NULL,
    rating    INT         NOT NULL CHECK (0 <= rating AND rating <= 5),
    review    VARCHAR(255),
    CONSTRAINT ratings_pk PRIMARY KEY (user_id, item_kind, item_id),
    CONSTRAINT ratings_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);


-- Insert data
INSERT INTO users (name, role, email, settings) VALUES (N'Loïc', 'admin', 'loic@mail.com', N'{"color": "red", "plan": {"id": 1, "name": "pro"}}');
INSERT INTO users (name, role, email, settings) VALUES ('Jean', 'guest', 'jean@mail.com', null);
INSERT INTO users (name, role, email, settings) VALUES ('Luc', 'guest', 'luc@mail.com', null);
INSERT INTO posts (title, content, created_by) VALUES ('SQL Server connector', null, 1);
INSERT INTO post_authors (post_id, user_id) VALUES (1, 1);
INSERT INTO post_authors (post_id, user_id) VALUES (1, 2);
INSERT INTO post_author_details (detail_post_id, detail_user_id, role) VALUES (1, 1, 'author');
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'posts', 1, 4);
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'users', 1, 5);
```

Remove everything with:

```tsql
DROP VIEW guests;
DROP VIEW admins;
DROP TABLE ratings;
DROP TABLE post_author_details;
DROP TABLE post_authors;
DROP TABLE posts;
DROP TABLE users;
```

## Cloud Setup

- Go on https://www.microsoft.com/fr-fr/sql-server/sql-server-downloads and click on "Start"
- Build your database url, like: `sqlserver://<user>:<pass>@<host>:<port>;database=<db>` or `Server=<host>,<port>;Database=<db>;User Id=<user>;Password=<pass>`
- Load data in your instance, if you don't have, you can use schemas from [Prisma schema examples](https://github.com/prisma/database-schema-examples/tree/main/mssql)
