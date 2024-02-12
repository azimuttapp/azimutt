import {describe, expect, test} from "@jest/globals";
import Ajv from "ajv";
import {Database, DatabaseSchema} from "../src";

describe('database', () => {
    const validate = new Ajv().compile(DatabaseSchema)
    test('basic db',  () => {
        // TypeScript validation (type specified explicitly)
        const db: Database = {
            tables: [{
                name: 'users',
                columns: [
                    {name: 'id', type: 'int'},
                    {name: 'name', type: 'varchar'},
                ],
                primaryKey: {columns: ['id']}
            }, {
                name: 'posts',
                columns: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar'},
                    {name: 'status', type: 'post_status', default: 'draft'},
                    {name: 'author', type: 'int'},
                ]
            }],
            relations: [
                {src: {table: 'posts'}, ref: {table: 'users'}, columns: [{src: 'author', ref: 'id'}]},
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
            tables: [{
                name: 'users',
                columns: [
                    {name: 'id', type: 'int'},
                    {name: 'first_name', type: 'varchar'},
                    {name: 'last_name', type: 'varchar'},
                    {name: 'email', type: 'varchar'},
                    {name: 'created_at', type: 'timestamp'},
                    {name: 'deleted_at', type: 'timestamp', nullable: true},
                ],
                primaryKey: {columns: ['id']},
                indexes: [
                    {columns: ['first_name', 'last_name']},
                    {columns: ['email'], name: 'uniq_users_email_active', unique: true, partial: 'deleted_at IS NULL', definition: 'users (lower(email))', comment: 'Active users can\'t have the same email', extensions: {kind: 'btree', columnTypes: {email: 'expression'}}},
                ],
                checks: [
                    {columns: ['email'], predicate: 'len(email) > 10'},
                    {columns: ['created_at', 'deleted_at'], predicate: 'deleted_at > created_at', name: 'chk_users_deletion', comment: 'Don\'t create deleted users', extensions: {deferred: true}},
                ],
                extensions: {color: 'blue', position: {x: 120, y: 42}}
            }, {
                name: 'posts',
                columns: [
                    {name: 'id', type: 'int'},
                    {name: 'title', type: 'varchar'},
                    {name: 'status', type: 'post_status', default: 'draft'},
                ],
            }, {
                name: 'user_posts',
                columns: [
                    {name: 'user_id', type: 'int'},
                    {name: 'post_id', type: 'int'},
                ],
                primaryKey: {columns: ['user_id', 'post_id'], name: 'user_posts_pk', comment: 'Composite PK', extensions: {composite: true}}
            }, {
                schema: 'social',
                name: 'tweets',
                columns: [
                    {name: 'id', type: 'int'},
                    {name: 'content', type: 'json', columns: [
                        {name: 'text', type: 'varchar'},
                        {name: 'pics', type: 'varchar[]'},
                    ], comment: 'Keep the whole tweet payload'},
                ]
            }, {
                name: 'profiles',
                columns: [
                    {name: 'id', type: 'int'},
                    {name: 'user_id', type: 'int'},
                    {name: 'bio', type: 'markdown', nullable: true},
                    {name: 'avatar', type: 'varchar', nullable: true},
                    {name: 'avatar_pos', type: 'position', nullable: true},
                ],
                indexes: [
                    {columns: ['user_id'], unique: true}
                ]
            }, {
                database: 'snowflake',
                catalog: 'analytics',
                schema: 'raw',
                name: 'events',
                columns: [
                    {name: 'id', type: 'uuid'},
                    {name: 'name', type: 'varchar'},
                    {name: 'payload', type: 'json', columns: [
                        {name: 'user_id', type: 'int'},
                        {name: 'tweet_id', type: 'int'},
                    ]},
                    {name: 'created_at', type: 'time_ns'},
                ]
            }, {
                name: 'contributions',
                kind: 'view',
                columns: [
                    {name: 'user_id', type: 'int'},
                    {name: 'item_kind', type: 'varchar', values: ['Post', 'Tweet'], extensions: {polymorphic: true}},
                    {name: 'item_id', type: 'int'},
                ],
                comment: 'View storing all kind of user contributions',
                extensions: {partition: 'HASH (item_kind)', fillfactor: 70}
            }],
            relations: [
                {src: {table: 'user_posts'}, ref: {table: 'users'}, columns: [{src: 'user_id', ref: 'id'}]},
                {src: {table: 'user_posts'}, ref: {table: 'posts'}, columns: [{src: 'post_id', ref: 'id'}]},
                {src: {table: 'contributions'}, ref: {table: 'posts'}, columns: [{src: 'item_id', ref: 'id'}], polymorphic: {column: 'item_kind', value: 'Post'}},
                {src: {table: 'contributions'}, ref: {schema: 'social', table: 'tweets'}, columns: [{src: 'item_id', ref: 'id'}], polymorphic: {column: 'item_kind', value: 'Tweet'}},
                {src: {table: 'profiles'}, ref: {table: 'users'}, columns: [{src: 'user_id', ref: 'id'}], kind: 'one-to-one'},
                {src: {schema: 'social', table: 'tweets'}, ref: {table: 'users'}, columns: [{src: 'id', ref: 'id'}], name: 'poly_tweets_users', kind: 'many-to-many', comment: 'Users mentioned in tweets', extensions: {deferred: true}},
                {database: 'snowflake', catalog: 'analytics', schema: 'raw', src: {database: 'snowflake', catalog: 'analytics', schema: 'raw', table: 'events'}, ref: {table: 'users'}, columns: [{src: 'payload.user_id', ref: 'id'}]},
                {database: 'snowflake', catalog: 'analytics', schema: 'raw', src: {database: 'snowflake', catalog: 'analytics', schema: 'raw', table: 'events'}, ref: {schema: 'social', table: 'tweets'}, columns: [{src: 'payload.tweet_id', ref: 'id'}]},
            ],
            types: [
                {name: 'markdown'},
                {name: 'post_status', values: ['draft', 'published', 'archived']},
                {name: 'position', definition: '(x int, y int)', comment: 'For complex types, ie not enums', extensions: {composite: true}},
                {database: 'snowflake', catalog: 'analytics', schema: 'raw', name: 'time_ns'}
            ],
            comment: 'This is a complex database',
            extensions: {source: 'connector-PostgreSQL', version: '0.20.0'}
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
})
