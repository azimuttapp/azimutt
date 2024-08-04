# MariaDB connector

This library allows to connect to [MariaDB](https://mariadb.com), extract its schema and more...

It lists all schemas, tables, columns, relations and types and format them in a JSON Schema.

This library is made by [Azimutt](https://azimutt.app) to allow people to explore their MariaDB database.
It's accessible through the [Desktop app](../../desktop) (soon), the [CLI](https://www.npmjs.com/package/azimutt) or even the website using the [gateway](../../gateway) server.

**Feel free to use it and even submit PR to improve it:**

- improve [MariaDB queries](./src/mariadb.ts) (look at `getSchema` function)

## Publish

- update `package.json` version
- update lib versions (`pnpm -w run update` + manual)
- test with `pnpm run dry-publish` and check `azimutt-connector-mariadb-x.y.z.tgz` content
- launch `pnpm publish --no-git-checks --access public`

View it on [npm](https://www.npmjs.com/package/@azimutt/connector-mariadb).

## Dev

If you need to develop on multiple libs at the same time (ex: want to update a connector and try it through the CLI), depend on local libs but publish & revert before commit.

- Depend on a local lib: `pnpm add <lib>`, ex: `pnpm add @azimutt/models`
- "Publish" lib locally by building it: `pnpm run build`

## Local Setup

You can use the [MariaDB Official image](https://hub.docker.com/_/mariadb):

```bash
docker run --name mariadb_sample -p 3307:3306 -e MARIADB_ROOT_PASSWORD=mariadb -e MARIADB_USER=azimutt -e MARIADB_PASSWORD=azimutt -e MARIADB_DATABASE=mariadb_sample mariadb:latest
```

Connect with host (`localhost`), port (`3307`), user (`azimutt`) and pass (`azimutt`) or using `mariadb://azimutt:azimutt@localhost:3307/mariadb_sample`, then add some tables and data:

```mariadb
CREATE TABLE users (
    id              BIGINT                  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(50)             NOT NULL,
    role            VARCHAR(10)             NOT NULL,
    email           VARCHAR(255)            NOT NULL,
    email_confirmed BOOLEAN   DEFAULT false NOT NULL,
    settings        JSON CHECK (JSON_VALID(settings)),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_lower_email_chk CHECK (email = LOWER(email)),
    CHECK (name <> email)
);
ALTER TABLE users COMMENT = 'List all users';
ALTER TABLE users MODIFY name VARCHAR(50) COMMENT 'The user name';
CREATE UNIQUE INDEX users_email_uniq ON users (email);
CREATE INDEX users_role_idx ON users (role);
ALTER TABLE users ADD plan VARCHAR(32) AS (JSON_VALUE(settings, '$.plan.name'));
CREATE INDEX users_plan_idx ON users (plan);
ALTER TABLE users ADD color VARCHAR(32) AS (JSON_VALUE(settings, '$.color'));
CREATE INDEX users_full_idx ON users (name, email, plan, color);

CREATE VIEW admins AS SELECT id, name, email FROM users WHERE role = 'admin';
CREATE VIEW guests AS SELECT id, name, email FROM users WHERE role = 'guest';


CREATE TABLE posts (
    id         BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title      VARCHAR(50) NOT NULL,
    content    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT      NOT NULL,
    CONSTRAINT posts_created_by_fk FOREIGN KEY (created_by) REFERENCES users (id)
);

CREATE TABLE post_authors (
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    CONSTRAINT post_authors_pk PRIMARY KEY (post_id, user_id),
    CONSTRAINT post_authors_post_id_fk FOREIGN KEY (post_id) REFERENCES posts (id),
    CONSTRAINT post_authors_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE post_author_details (
    detail_post_id BIGINT      NOT NULL,
    detail_user_id BIGINT      NOT NULL,
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
INSERT INTO users (name, role, email, settings) VALUES ('Loïc', 'admin', 'loic@mail.com', '{"color": "red", "plan": {"id": 1, "name": "pro"}}');
INSERT INTO users (name, role, email, settings) VALUES ('Jean', 'guest', 'jean@mail.com', null);
INSERT INTO users (name, role, email, settings) VALUES ('Luc', 'guest', 'luc@mail.com', null);
INSERT INTO posts (title, content, created_by) VALUES ('MariaDB connector', null, 1);
INSERT INTO post_authors (post_id, user_id) VALUES (1, 1);
INSERT INTO post_authors (post_id, user_id) VALUES (1, 2);
INSERT INTO post_author_details (detail_post_id, detail_user_id, role) VALUES (1, 1, 'author');
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'posts', 1, 4);
INSERT INTO ratings (user_id, item_kind, item_id, rating) VALUES (3, 'users', 1, 5);
```

Remove everything with:

```mariadb
DROP VIEW guests;
DROP VIEW admins;
DROP TABLE ratings;
DROP TABLE post_author_details;
DROP TABLE post_authors;
DROP TABLE posts;
DROP TABLE users;
```

## Cloud Setup

- Go on https://mariadb.com and click on "Start in the cloud" (top right)
- Follow the onboarding
- Create a cloud database
- In manage click on "Security access" to allow your IP (if it doesn't work, check your adblock ^^)
- Then click on "connect to get your credentials" and build an url like: `mariadb://<user>:<pass>@<host>:<port>/<db>` (db is the one you created)
- Load data in your instance, if you don't have, you can use schemas from [here](https://dataedo.com/kb/databases/mariadb/sample-databases) or [there](https://github.com/mariadb-corporation/dev-example-bookings)
