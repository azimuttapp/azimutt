import * as fs from "fs";
import {describe, expect, test} from "@jest/globals";
import {Database, parseJsonDatabase} from "@azimutt/models";
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
        const sql = `DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
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
    test('full', () => {
        const db: Database = parseJsonDatabase(fs.readFileSync('../aml/resources/full.json', 'utf8')).result || {}
        const sql = fs.readFileSync('./resources/full.postgres.sql', 'utf8')
        // const parsed = parsePostgres(sql)
        // expect(parsed).toEqual({result: db})
        expect(generatePostgres(db)).toEqual(sql)
    })
})
