# PostgreSQL connector

This library allows to connect to [PostgreSQL](https://www.postgresql.org), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their PostgreSQL database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [PostgreSQL queries](./src/postgres.ts) (look at `getSchema` function)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-connector-postgres-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-postgres).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`

## Local Setup

You can use the [PostgreSQL Official image](https://hub.docker.com/_/postgres):

```bash
docker run --name postgres_sample -p 5433:5432 -e POSTGRES_PASSWORD=postgres postgres:latest
```

Connect with host (`localhost`), port (`5433`), user (`postgres`) and pass (`postgres`) or using `postgresql://postgres:postgres@localhost:5433/postgres`, then add some tables and data:

```postgresql
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(50)             NOT NULL,
    role            VARCHAR(10)             NOT NULL,
    email           VARCHAR(255)            NOT NULL,
    email_confirmed BOOLEAN   DEFAULT false NOT NULL,
    settings        JSONB,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_lower_email_chk CHECK (email = LOWER(email)),
    CHECK (name <> email)
);
COMMENT ON TABLE users IS 'List all users';
COMMENT ON COLUMN users.name IS 'The user name';
CREATE UNIQUE INDEX users_email_uniq ON users (email);
CREATE INDEX users_role_idx ON users (role);
CREATE INDEX users_plan_idx ON users ((settings -> 'plan' ->> 'name'));
CREATE INDEX users_full_idx ON users (name, email, (settings -> 'plan' ->> 'name'), (settings ->> 'color'));

CREATE VIEW admins AS SELECT id, name, email FROM users WHERE role = 'admin';
COMMENT ON VIEW admins IS 'Only admins';

CREATE MATERIALIZED VIEW guests AS SELECT id, name, email FROM users WHERE role = 'guest';
COMMENT ON MATERIALIZED VIEW guests IS 'Only guests';


CREATE TABLE posts (
    id         BIGSERIAL PRIMARY KEY,
    title      VARCHAR(50) NOT NULL,
    content    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT         NOT NULL,
    CONSTRAINT posts_created_by_fk FOREIGN KEY (created_by) REFERENCES users (id)
);

CREATE TABLE post_authors (
    post_id INT,
    user_id INT,
    CONSTRAINT post_authors_pk PRIMARY KEY (post_id, user_id),
    CONSTRAINT post_authors_post_id_fk FOREIGN KEY (post_id) REFERENCES posts (id),
    CONSTRAINT post_authors_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE post_author_details (
    detail_post_id INT,
    detail_user_id INT,
    role           VARCHAR(10) NOT NULL,
    CONSTRAINT post_author_details_pk PRIMARY KEY (detail_post_id, detail_user_id),
    CONSTRAINT post_author_details_post_user_fk FOREIGN KEY (detail_post_id, detail_user_id) REFERENCES post_authors (post_id, user_id)
);

CREATE TABLE ratings (
    user_id   INT         NOT NULL,
    item_kind VARCHAR(50) NOT NULL,
    item_id   INT         NOT NULL,
    rating    INT         NOT NULL CHECK ( 0 <= rating AND rating <= 5 ),
    review    VARCHAR(255),
    CONSTRAINT ratings_pk PRIMARY KEY (user_id, item_kind, item_id),
    CONSTRAINT ratings_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);


-- Insert data
INSERT INTO users (name, role, email, settings) VALUES ('Loïc', 'admin', 'loic@mail.com', '{"color": "red", "plan": {"id": 1, "name": "pro"}}');
INSERT INTO users (name, role, email, settings) VALUES ('Jean', 'guest', 'jean@mail.com', null);
INSERT INTO users (name, role, email, settings) VALUES ('Luc', 'guest', 'luc@mail.com', null);
INSERT INTO posts (title, content, created_by) VALUES ('PostgreSQL connector', null, 1);
INSERT INTO post_authors (post_id, user_id) VALUES (1, 1);
INSERT INTO post_authors (post_id, user_id) VALUES (1, 2);
INSERT INTO post_author_details (detail_post_id, detail_user_id, role) VALUES (1, 1, 'author');
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'posts', 1, 4);
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'users', 1, 5);
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'users', 3, 5);
```

Remove everything with:

```postgresql
DROP MATERIALIZED VIEW guests;
DROP VIEW admins;
DROP TABLE ratings;
DROP TABLE post_author_details;
DROP TABLE post_authors;
DROP TABLE posts;
DROP TABLE users;
```
