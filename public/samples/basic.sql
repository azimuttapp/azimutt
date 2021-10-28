CREATE TABLE users
(
    id          int          NOT NULL,
    first_name  varchar(255) NOT NULL,
    last_name   varchar(255) NOT NULL,
    email       varchar(255),
    external_id uuid,
    CONSTRAINT users_pk PRIMARY KEY (id)
);

CREATE UNIQUE INDEX user_email_uniq ON users (email);

CREATE INDEX user_name_index ON users USING btree (first_name, last_name);

CREATE INDEX user_external_id_index ON users (external_id);

COMMENT ON TABLE users IS 'A table to store all users and in a single diagram control them, for the better or worse!';

COMMENT ON COLUMN users.id IS 'The user id which is automatically defined based on subscription order. Should never change!';

CREATE TABLE roles
(
    id          int          NOT NULL,
    slug        varchar(255) NOT NULL,
    name        varchar(255) NOT NULL,
    description text,
    created_at  timestamp    NOT NULL,
    updated_at  timestamp    NOT NULL,
    CONSTRAINT roles_pk PRIMARY KEY (id)
);

CREATE UNIQUE INDEX roles_slug_uniq ON roles (slug);

CREATE UNIQUE INDEX roles_name_uniq ON roles (name);

CREATE TABLE credentials
(
    user_id  int          NOT NULL,
    login    varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    CONSTRAINT credentials_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE UNIQUE INDEX credentials_login_uniq ON credentials (login);

CREATE TABLE role_user
(
    id         int       NOT NULL,
    role_id    int       NOT NULL,
    user_id    int       NOT NULL,
    created_at timestamp NOT NULL,
    updated_at timestamp NOT NULL,
    CONSTRAINT role_user_pk PRIMARY KEY (id),
    CONSTRAINT role_user_role_id_fk FOREIGN KEY (role_id) REFERENCES roles (id),
    CONSTRAINT role_user_user_id_fk FOREIGN KEY (user_id) REFERENCES users (id)
);
