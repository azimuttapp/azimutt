import * as fs from "fs";
import Ajv from "ajv";
import {describe, expect, test} from "@jest/globals";
import {Database, DatabaseSchema} from "./index";

describe('database', () => {
    const validate = new Ajv().compile(DatabaseSchema)
    test('basic db', () => {
        // TypeScript validation (type specified explicitly)
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
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar'},
                    {name: 'status', type: 'post_status', default: 'draft'},
                    {name: 'author', type: 'int'},
                ]
            }],
            relations: [
                {src: {entity: 'posts', attrs: [['author']]}, ref: {entity: 'users', attrs: [['id']]}},
            ],
            types: [
                {name: 'post_status', values: ['draft', 'published', 'archived']},
            ],
        }
        // zod validation
        const res: Database = Database.parse(db)
        expect(res).toEqual(db)
        // JSON Schema validation
        validate(db)
        expect(validate.errors).toEqual(null)
    })
    test('complex db', () => {
        // TypeScript validation (type specified explicitly)
        const db: Database = {
            entities: [{
                name: 'users',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'first_name', type: 'varchar'},
                    {name: 'last_name', type: 'varchar'},
                    {name: 'email', type: 'varchar'},
                    {name: 'created_at', type: 'timestamp'},
                    {name: 'deleted_at', type: 'timestamp', null: true},
                ],
                pk: {attrs: [['id']]},
                indexes: [
                    {attrs: [['first_name'], ['last_name']]},
                    {attrs: [['email']], name: 'uniq_users_email_active', unique: true, partial: 'deleted_at IS NULL', definition: 'users (lower(email))', doc: 'Active users can\'t have the same email', extra: {kind: 'btree', attributeTypes: {email: 'expression'}}},
                ],
                checks: [
                    {attrs: [['email']], predicate: 'len(email) > 10'},
                    {attrs: [['created_at'], ['deleted_at']], predicate: 'deleted_at > created_at', name: 'chk_users_deletion', doc: 'Don\'t create deleted users', extra: {deferred: true}},
                ],
                extra: {color: 'blue', position: {x: 120, y: 42}}
            }, {
                name: 'posts',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar'},
                    {name: 'status', type: 'post_status', default: 'draft'},
                ],
            }, {
                name: 'user_posts',
                attrs: [
                    {name: 'user_id', type: 'int'},
                    {name: 'post_id', type: 'int'},
                ],
                pk: {attrs: [['user_id'], ['post_id']], name: 'user_posts_pk', doc: 'Composite PK', extra: {composite: true}}
            }, {
                schema: 'social',
                name: 'tweets',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'content', type: 'json', attrs: [
                        {name: 'text', type: 'varchar'},
                        {name: 'pics', type: 'varchar[]'},
                    ], doc: 'Keep the whole tweet payload'},
                ]
            }, {
                name: 'profiles',
                attrs: [
                    {name: 'id', type: 'int'},
                    {name: 'user_id', type: 'int'},
                    {name: 'bio', type: 'markdown', null: true},
                    {name: 'avatar', type: 'varchar', null: true},
                    {name: 'avatar_pos', type: 'position', null: true},
                ],
                indexes: [
                    {attrs: [['user_id']], unique: true}
                ]
            }, {
                database: 'snowflake',
                catalog: 'analytics',
                schema: 'raw',
                name: 'events',
                attrs: [
                    {name: 'id', type: 'uuid'},
                    {name: 'name', type: 'varchar'},
                    {name: 'payload', type: 'json', attrs: [
                        {name: 'user_id', type: 'int'},
                        {name: 'tweet_id', type: 'int'},
                    ]},
                    {name: 'created_at', type: 'time_ns'},
                ]
            }, {
                name: 'contributions',
                kind: 'view',
                attrs: [
                    {name: 'user_id', type: 'int'},
                    {name: 'item_kind', type: 'varchar', stats: {distinctValues: ['Post', 'Tweet']}, extra: {polymorphic: true}},
                    {name: 'item_id', type: 'int'},
                ],
                doc: 'View storing all kind of user contributions',
                extra: {partition: 'HASH (item_kind)', fillfactor: 70}
            }],
            relations: [
                {src: {entity: 'user_posts', attrs: [['user_id']]}, ref: {entity: 'users', attrs: [['id']]}},
                {src: {entity: 'user_posts', attrs: [['post_id']]}, ref: {entity: 'posts', attrs: [['id']]}},
                {src: {entity: 'contributions', attrs: [['item_id']]}, ref: {entity: 'posts', attrs: [['id']]}, polymorphic: {attribute: ['item_kind'], value: 'Post'}},
                {src: {entity: 'contributions', attrs: [['item_id']]}, ref: {schema: 'social', entity: 'tweets', attrs: [['id']]}, polymorphic: {attribute: ['item_kind'], value: 'Tweet'}},
                {src: {entity: 'profiles', attrs: [['user_id']], cardinality: '1'}, ref: {entity: 'users', attrs: [['id']], cardinality: '1'}},
                {src: {schema: 'social', entity: 'tweets', attrs: [['id']], cardinality: 'n'}, ref: {entity: 'users', attrs: [['id']], cardinality: 'n'}, name: 'poly_tweets_users', doc: 'Users mentioned in tweets', extra: {deferred: true}},
                {src: {database: 'snowflake', catalog: 'analytics', schema: 'raw', entity: 'events', attrs: [['payload', 'user_id']]}, ref: {entity: 'users', attrs: [['id']]}},
                {src: {database: 'snowflake', catalog: 'analytics', schema: 'raw', entity: 'events', attrs: [['payload', 'tweet_id']]}, ref: {schema: 'social', entity: 'tweets', attrs: [['id']]}},
            ],
            types: [
                {name: 'markdown'},
                {name: 'post_status', values: ['draft', 'published', 'archived'], definition: 'ENUM (\'draft\', \'published\', \'archived\')'},
                {name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}], definition: '(x int, y int)', doc: 'For complex types, ie not enums', extra: {composite: true}},
                {database: 'snowflake', catalog: 'analytics', schema: 'raw', name: 'time_ns'}
            ],
            doc: 'This is a complex database',
            extra: {source: 'connector-PostgreSQL', version: '0.20.0'}
        }
        // zod validation
        const res: Database = Database.parse(db)
        expect(res).toEqual(db)
        // JSON Schema validation
        validate(db)
        expect(validate.errors).toEqual(null)
    })
    test('empty db', () => {
        // TypeScript validation (type specified explicitly)
        const db: Database = {}
        // zod validation
        const res: Database = Database.parse(db)
        expect(res).toEqual(db)
        // JSON Schema validation
        validate(db)
        expect(validate.errors).toEqual(null)
    })
    test('aml_schema.json not out of sync', () => {
        // make sure the exposed AML schema stays aligned with the current one
        const json = JSON.parse(fs.readFileSync('../../backend/priv/static/aml_schema.json', 'utf8'))
        // console.log(JSON.stringify(DatabaseSchema)) // useful to sync to the aml_schema.json ^^
        expect(json).toEqual(DatabaseSchema)
    })
})
