CREATE TYPE auth_kind AS ENUM ('password', 'google', 'twitter', 'github');
CREATE TYPE theme AS ENUM ('light', 'dark');
CREATE TYPE cms.post_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE tracking.event_item AS ENUM ('users', 'posts', 'comments');

CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar(64) NOT NULL,
  email varchar(256) NOT NULL UNIQUE,
  auth auth_kind NOT NULL,
  settings json,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now(),
  deleted_at timestamp
);
CREATE INDEX user_name_idx ON users(name);

-- CMS tables

CREATE TABLE cms.posts (
  id int PRIMARY KEY,
  title varchar NOT NULL CHECK (length(title) > 10),
  content text NOT NULL,
  status cms.post_status NOT NULL DEFAULT 'draft',
  author int NOT NULL REFERENCES users(id),
  tags varchar[] NOT NULL,
  created_at timestamp NOT NULL DEFAULT now(),
  created_by int NOT NULL REFERENCES users(id),
  updated_at timestamp NOT NULL DEFAULT now(),
  updated_by int NOT NULL REFERENCES users(id)
);
COMMENT ON COLUMN cms.posts.content IS 'allow markdown';

CREATE TABLE cms.comments (
  id int PRIMARY KEY,
  post_id int NOT NULL REFERENCES cms.posts(id),
  content text NOT NULL,
  created_at timestamp NOT NULL DEFAULT now(),
  created_by int NOT NULL REFERENCES users(id),
  updated_at timestamp NOT NULL DEFAULT now(),
  updated_by int NOT NULL REFERENCES users(id)
);

-- Tracking tables

CREATE TABLE tracking.events (
  id uuid PRIMARY KEY,
  name varchar NOT NULL,
  payload json,
  item_kind event_item,
  item_id int, -- references: users.id (item_kind='users'), cms.posts.id (item_kind='posts') or cms.comments.id (item_kind='comments')
  created_at timestamp NOT NULL DEFAULT now()
);
