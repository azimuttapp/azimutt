import {describe, expect, test} from "vitest"
import {Value} from '@sinclair/typebox/value'
import {LegacyDatabase} from "@azimutt/models";
import {sAzimuttSchema} from "./schemas";

describe('schemas', () => {
    test('valid db', () => {
        const ldb: LegacyDatabase = {
            tables: [{
                schema: 'public',
                table: 'users',
                columns: [{name: 'id', type: 'uuid'}],
                primaryKey: {name: 'users_pk', columns: ['id']},
            }, {
                schema: 'public',
                table: 'posts',
                view: true,
                definition: 'SELECT * ...',
                columns: [
                    {name: 'id', type: 'uuid'},
                    {name: 'title', type: 'varchar'},
                    {name: 'status', type: 'post_status', values: ['draft', 'published'], stats: {nulls: 0, bytesAvg: 7, cardinality: 2, commonValues: [{value: 'published', freq: 12}], histogram: ['draft', 'published']}},
                    {name: 'content', type: 'text', nullable: true, default: 'null', comment: 'markdown text'},
                    {name: 'owner', type: 'uuid'},
                    {name: 'details', type: 'json', columns: [
                        {name: 'tags', type: 'varchar[]'},
                    ]},
                ],
                primaryKey: {name: 'users_pk', columns: ['id']},
                uniques: [{name: 'posts_title_uniq', columns: ['title'], definition: ''}],
                indexes: [{name: 'posts_status_idx', columns: ['status'], definition: 'btree'}],
                checks: [{name: 'posts_title_len', columns: ['title'], predicate: 'len(title) > 10'}],
                comment: 'get all posts',
                stats: {rows: 12, size: 1254, sizeIdx: 124, scanSeq: 45, scanSeqLast: '2024-04-23T16:04:16.052Z', scanIdx: 45, scanIdxLast: '2024-04-22T15:04:16.051Z', analyzeLast: '2024-04-21T14:04:16.050Z', vacuumLast: '2024-04-20T13:04:16.049Z'}
            }],
            relations: [{name: 'posts_owner_fk', src: {table: 'public.posts', column: 'owner'}, ref: {table: 'public.users', column: 'id'}}],
            types: [
                {schema: 'public', name: 'post_status', values: ['draft', 'published']},
                {schema: 'public', name: 'position', definition: '{x: int, y: int}'},
                {schema: 'public', name: 'empty', values: null},
            ],
        }
        expect(Array.from(Value.Errors(sAzimuttSchema, ldb))).toEqual([])
    })
})
