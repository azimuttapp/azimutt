import {ObjectId} from "mongodb";
import {describe, expect, test} from "@jest/globals";
import {legacyParseStatement, parseMongoStatement} from "./parser";

describe('parser', () => {
    test('basic find', () => {
        expect(parseMongoStatement('db.users.find({});')).toEqual({collection: 'users', operation: 'find', command: {}})
        expect(parseMongoStatement('db.users.find(bad);')).toEqual('Invalid command (bad), should be a valid JSON')
    })
    test('empty command', () => {
        expect(parseMongoStatement('db.users.find();')).toEqual({collection: 'users', operation: 'find', command: {}})
    })
    test('escaped collection', () => {
        expect(parseMongoStatement("db.collection('users').find({});")).toEqual({collection: 'users', operation: 'find', command: {}})
    })
    test('defined database', () => {
        expect(parseMongoStatement("db('mongo_sample').users.find({});"))
            .toEqual({database: 'mongo_sample', collection: 'users', operation: 'find', command: {}})
    })
    test('simple command', () => {
        expect(parseMongoStatement('db.users.find({"id":{"$eq":1}});')).toEqual({collection: 'users', operation: 'find', command: {id: {"$eq": 1}}})
    })
    test('with limit', () => {
        expect(parseMongoStatement('db.users.find({}).limit(10);')).toEqual({collection: 'users', operation: 'find', command: {}, limit: 10})
        expect(parseMongoStatement('db.users.find({}).limit(a);')).toEqual('Invalid limit (a), should be a number')
    })
    test('aggregate and complex command', () => {
        expect(parseMongoStatement('db.users.aggregate([{"$sortByCount":"$role"},{"$project":{"_id":0,"role":"$_id","count":"$count"}}]);'))
            .toEqual({collection: 'users', operation: 'aggregate', command: [{$sortByCount: '$role'}, {$project: {_id: 0, role: '$_id', count: '$count'}}]})
    })
    test('multi-lines', () => {
        expect(parseMongoStatement('db.users.find({\n  "id": {"$eq":1}\n});\n')).toEqual({collection: 'users', operation: 'find', command: {id: {"$eq": 1}}})
    })
    test('ObjectId', () => {
        expect(parseMongoStatement('db.users.find(ObjectId("66ae842903c5dc4e5bd14a00")).limit(1);'))
            .toEqual({collection: 'users', operation: 'find', command: new ObjectId("66ae842903c5dc4e5bd14a00"), limit: 1})
        expect(parseMongoStatement('db.users.find(Object("66ae842903c5dc4e5bd14a00")).limit(1);'))
            .toEqual('Invalid ObjectId (Object("66ae842903c5dc4e5bd14a00")), should be like: ObjectId("66ae842903c5dc4e5bd14a00")')
    })
    test('project', () => {
        expect(parseMongoStatement('db.posts.find({"status": "draft"}).project({"_id": 0, "id": 1, "title": 1});'))
            .toEqual({collection: 'posts', operation: 'find', command: {"status": "draft"}, projection: {_id: 0, id: 1, title: 1}})
        expect(parseMongoStatement('db.users.find({"id": 1}).project({name: 1});')).toEqual("Invalid projection ({name: 1})")
    })
    test('invalid', () => {
        expect(parseMongoStatement('')).toEqual(`Invalid query (), in should be in form of: 'db.$collection.$operation($command);', ex: 'db.users.find({});'`)
        expect(parseMongoStatement('abc')).toEqual(`Invalid query (abc), in should be in form of: 'db.$collection.$operation($command);', ex: 'db.users.find({});'`)
    })
    test('legacyParseStatement', () => {
        expect(parseMongoStatement('mongo_sample/users/find/{"id":{"$eq":1}}'))
            .toEqual({database: 'mongo_sample', collection: 'users', operation: 'find', command: {id: {"$eq": 1}}})
        expect(parseMongoStatement('/users/aggregate/[{"$sortByCount":"$role"},{"$project":{"_id":0,"role":"$_id","count":"$count"}}]/100'))
            .toEqual({collection: 'users', operation: 'aggregate', command: [{$sortByCount: '$role'}, {$project: {_id: 0, role: '$_id', count: '$count'}}], limit: 100})
        expect(legacyParseStatement('')).toEqual('Missing collection name (legacy mode)')
        expect(legacyParseStatement('abc')).toEqual('Missing collection name (legacy mode)')
        expect(legacyParseStatement('/test')).toEqual('Missing operation name (legacy mode)')
        expect(legacyParseStatement('/test/find')).toEqual('Missing command (legacy mode)')
        expect(legacyParseStatement('/test/find/abc')).toEqual('Invalid command (abc), it should be a valid JSON (legacy mode)')
        expect(legacyParseStatement('/test/find/{}/a')).toEqual('Invalid limit (a), it should be a number (legacy mode)')
    })
})
