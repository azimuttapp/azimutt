--
-- A file with several statements more or less complex to check the parser is works fine.
-- They don't make sense for a particular db ^^
--

/*
 * first query
 * Author: Loïc
 */
select id /* primary key */, name
from users -- table
where role = 'admin';

DROP TABLE IF EXISTS users, public.posts CASCADE;

CREATE TABLE users (
    id int PRIMARY KEY,
    first_name varchar NOT NULL,
    last_name varchar NOT NULL,
    CONSTRAINT name_uniq UNIQUE (first_name, last_name),
    email varchar UNIQUE CHECK ( email LIKE '%@%' ),
    role varchar DEFAULT 'guest'
);

CREATE TABLE public.posts (
    id int PRIMARY KEY,
    author int CONSTRAINT posts_author_fk REFERENCES users(id)
);
