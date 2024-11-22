CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR
);

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR,
  content TEXT,
  author INT REFERENCES users(id)
);
