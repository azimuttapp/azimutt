import {describe, expect, test} from "@jest/globals";
import {Database} from "@azimutt/models";
import {generatePostgres} from "./postgresGenerator";

describe('postgresGenerator', () => {
    test('empty', () => {
        expect(generatePostgres({})).toEqual('')
    })
    test('basic', () => {
        const db: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                ],
                pk: {attrs: [['id']]}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'uuid'},
                    {name: 'title', type: 'varchar'},
                    {name: 'content', type: 'text'},
                    {name: 'author', type: 'int'},
                ],
                pk: {attrs: [['id']]}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
            ],
        }
        const sql = `CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar NOT NULL
);

CREATE TABLE posts (
  id uuid PRIMARY KEY,
  title varchar NOT NULL,
  content text NOT NULL,
  author int NOT NULL REFERENCES users(id)
);
`
        expect(generatePostgres(db)).toEqual(sql)
    })
    test('more complex', () => {
        const db: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                    {name: 'role', type: 'user_role', default: 'guest'},
                    {name: 'settings', type: 'jsonb', null: true, attrs: [{name: 'address', type: 'object', attrs: [{name: 'street', type: 'string'}, {name: 'city', type: 'string'}, {name: 'country', type: 'string'}]}]},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['name']], unique: true}, {name: 'users_address_index', attrs: [['settings', 'address', 'country'], ['settings', 'address', 'city'], ['settings', 'address', 'street']]}],
                checks: [{attrs: [['name']], predicate: "name <> ''"}, {name: 'users_admin_name_chk', attrs: [['role'], ['name']], predicate: "role = 'admin' AND name LIKE 'a_%'"}]
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'uuid'},
                    {name: 'title', type: 'varchar', doc: 'Post title', extra: {comment: 'defining doc'}},
                    {name: 'content', type: 'text'},
                    {name: 'created_by', type: 'int'},
                ],
                pk: {attrs: [['id']]},
                doc: 'All posts'
            }, {
                name: 'post_members',
                attrs: [
                    {name: 'post_id', type: 'uuid'},
                    {name: 'user_id', type: 'int'},
                    {name: 'role', type: 'varchar(10)'},
                ],
                pk: {name: 'post_members_pk', attrs: [['post_id'], ['user_id']]}
            }, {
                name: 'post_member_details',
                attrs: [
                    {name: 'post_id', type: 'uuid'},
                    {name: 'user_id', type: 'int'},
                    {name: 'added_by', type: 'int'},
                ],
                pk: {attrs: [['post_id'], ['user_id']]}
            }],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]},
                {src: {entity: 'post_member_details'}, ref: {entity: 'users'}, attrs: [{src: ['added_by'], ref: ['id']}]},
                {src: {entity: 'post_member_details'}, ref: {entity: 'post_members'}, attrs: [{src: ['post_id'], ref: ['post_id']}, {src: ['user_id'], ref: ['user_id']}]},
            ],
            types: [
                {name: 'user_role', values: ['admin', 'guest'], doc: 'user roles'}
            ]
        }
        const sql = `CREATE TYPE user_role AS ENUM ('admin', 'guest');
COMMENT ON TYPE user_role IS 'user roles';

CREATE TABLE users (
  id int PRIMARY KEY,
  name varchar NOT NULL UNIQUE CHECK (name <> ''),
  role user_role NOT NULL DEFAULT 'guest',
  settings jsonb,
  CONSTRAINT users_admin_name_chk CHECK (role = 'admin' AND name LIKE 'a_%')
);
CREATE INDEX users_address_index ON users(settings->'address'->'country', settings->'address'->'city', settings->'address'->'street');

CREATE TABLE posts (
  id uuid PRIMARY KEY,
  title varchar NOT NULL,
  content text NOT NULL,
  created_by int NOT NULL REFERENCES users(id)
);
COMMENT ON TABLE posts IS 'All posts';
COMMENT ON COLUMN posts.title IS 'Post title';

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
`
        expect(generatePostgres(db)).toEqual(sql)
    })
})
