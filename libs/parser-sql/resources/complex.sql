DROP VIEW IF EXISTS admins;
DROP TABLE IF EXISTS post_member_details;
DROP TABLE IF EXISTS post_members;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TYPE user_role AS ENUM ('admin', 'guest');
COMMENT ON TYPE user_role IS 'user roles';

CREATE TABLE users (
  id uuid PRIMARY KEY,
  name varchar NOT NULL UNIQUE CHECK (name <> ''),
  role user_role NOT NULL DEFAULT 'guest',
  settings jsonb,
  CONSTRAINT users_admin_name_chk CHECK (role = 'admin' AND name LIKE 'a_%')
);
CREATE INDEX users_address_index ON users(settings->'address'->'country', settings->'address'->'city', settings->'address'->'street');

-- Create posts
CREATE TABLE posts (
  id uuid PRIMARY KEY,
  title varchar NOT NULL, -- defining doc
  content text NOT NULL,
  created_by uuid NOT NULL REFERENCES users(id)
);
COMMENT ON TABLE posts IS 'All posts';
COMMENT ON COLUMN posts.title IS 'Post title';

CREATE TABLE comments (
  id uuid PRIMARY KEY,
  content text NOT NULL,
  item_kind varchar NOT NULL,
  item_id uuid NOT NULL -- references: users.id (item_kind='User') or posts.id (item_kind='Post')
);

CREATE TABLE post_members (
  post_id uuid,
  user_id int,
  role varchar(10) NOT NULL,
  CONSTRAINT post_members_pk PRIMARY KEY (post_id, user_id)
);

CREATE TABLE post_member_details (
  post_id uuid,
  user_id int,
  added_by int NOT NULL REFERENCES users(id),
  PRIMARY KEY (post_id, user_id),
  FOREIGN KEY (post_id, user_id) REFERENCES post_members(post_id, user_id)
);

CREATE VIEW admins AS
SELECT * FROM users WHERE role = 'admin';
