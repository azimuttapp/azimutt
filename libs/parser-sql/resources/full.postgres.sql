DROP TABLE IF EXISTS social_accounts;
DROP VIEW IF EXISTS guests;
DROP VIEW IF EXISTS admins;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS organizations;
DROP TABLE IF EXISTS public.legacy_slug;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS "legacy schema"."post member details";
DROP TABLE IF EXISTS post_members;
DROP TABLE IF EXISTS cms.posts;
DROP TABLE IF EXISTS users;

CREATE TYPE comment_item AS ENUM ('User', 'Post');
CREATE TYPE slug;
COMMENT ON TYPE slug IS 'anonymous type';
-- CREATE TYPE uid AS int; -- type alias not supported on PostgreSQL
CREATE TYPE cms.post_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE position AS (x int, y int);
CREATE TYPE box (INTERNALLENGTH = 16, INPUT = lower, OUTPUT = lower);

--
-- Full Schema AML
--

-- simplest entity
CREATE TABLE users (
  id int PRIMARY KEY, -- type alias 'uid'
  first_name varchar NOT NULL,
  last_name varchar NOT NULL,
  email varchar NOT NULL UNIQUE, -- check constraint but no predicate
  is_admin bool NOT NULL,
  CONSTRAINT name UNIQUE (first_name, last_name)
);

-- entity in schema
CREATE TABLE cms.posts (
  id int PRIMARY KEY,
  title varchar(100) NOT NULL UNIQUE CHECK (title <> ''),
  status post_status NOT NULL,
  content varchar,
  settings json,
  created_at timestamp with time zone NOT NULL,
  created_by int NOT NULL REFERENCES users(id)
);
CREATE INDEX posts_settingscategoryid_idx ON cms.posts((settings->'category'->>'id'));

CREATE TABLE post_members (
  post_id uuid REFERENCES cms.posts(id),
  user_id int REFERENCES users(id),
  role varchar(10) NOT NULL DEFAULT 'author' CONSTRAINT members_role_chk CHECK (role IN ('author', 'editor')),
  CONSTRAINT post_members_pk PRIMARY KEY (post_id, user_id)
);

-- special entity name
CREATE TABLE "legacy schema"."post member details" (
  post_id uuid,
  user_id int,
  index int NOT NULL,
  "added by" int REFERENCES users(id),
  PRIMARY KEY (post_id, user_id),
  FOREIGN KEY (post_id, user_id) REFERENCES post_members(post_id, user_id)
);
COMMENT ON COLUMN "legacy schema"."post member details".index IS 'keyword attribute name';
COMMENT ON COLUMN "legacy schema"."post member details"."added by" IS 'special attribute name';

-- several additional props
CREATE TABLE comments (
  id uuid CONSTRAINT comment_pk PRIMARY KEY,
  item_kind comment_item NOT NULL,
  item_id int NOT NULL, -- references: users.id (item_kind='User') or cms.posts.id (item_kind='Post')
  content unknown NOT NULL, -- no type
  created_by unknown NOT NULL REFERENCES users(id) -- attribute type should default to target column is not set
);
CREATE INDEX item ON comments(item_kind, item_id);
COMMENT ON TABLE comments IS E'a table with most options\nlooks quite complex but not intended to be used all together ^^';
COMMENT ON COLUMN comments.item_kind IS E'polymorphic column for polymorphic relation\nused with both item_kind and item_id';
COMMENT ON COLUMN comments.content IS 'doc with # escaped';

CREATE TABLE public.legacy_slug (
  old_slug slug NOT NULL,
  new_slug slug NOT NULL, -- composite check, add it to every attribute, predicate can be defined once
  cur_slug varchar, -- reference nested attribute cms.posts(settings.slug)
  CONSTRAINT slug_check CHECK (old_slug <> '' AND new_slug <> '')
);

CREATE TABLE organizations (
  id int PRIMARY KEY REFERENCES users(id),
  name varchar(50) NOT NULL,
  content box
);
COMMENT ON COLUMN organizations.id IS 'many-to-many relation';

CREATE TABLE profiles (
  id int PRIMARY KEY REFERENCES users(id)
);
COMMENT ON COLUMN profiles.id IS 'one-to-one relation';

-- CREATE VIEW admins AS <missing definition>;

CREATE VIEW guests AS
SELECT *
FROM users
WHERE is_admin = false;

CREATE TABLE social_accounts ();
COMMENT ON TABLE social_accounts IS 'entity with no attribute';
