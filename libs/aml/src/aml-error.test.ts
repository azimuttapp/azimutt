import {describe, expect, test} from "@jest/globals";
import {Database, ParserResult} from "@azimutt/models";
import {parseAml} from "./aml";

// make sure the parser don't fail on invalid input
describe('errors', () => {
    test('attribute relation', () => {
        expect(parseLegacyAml('posts\n  author int\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}}
        })
        expect(parseLegacyAml('posts\n  author int -\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            errors: [{name: 'NoViableAltException', message: "Expecting: one of these possible Token sequences:\n  1. [Dash]\n  2. [LowerThan]\n  3. [GreaterThan]\nbut found: '\n'", position: {offset: [20, 20], line: [2, 2], column: [15, 15]}}]
        })
        expect(parseLegacyAml('posts\n  author int ->\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", position: {offset: [21, 21], line: [2, 2], column: [16, 16]}}]
        })
        expect(parseLegacyAml('posts\n  author int -> users\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            // TODO: an error should be reported here
        })
        expect(parseLegacyAml('posts\n  author int -> users(\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            errors: [{name: 'EarlyExitException', message: "Expecting: expecting at least one iteration which starts with one of these possible Token sequences::\n  <[WhiteSpace] ,[Identifier]>\nbut found: '\n'", position: {offset: [28, 28], line: [2, 2], column: [23, 23]}}]
        })
        expect(parseLegacyAml('posts\n  author int -> users(id\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {statement: 1}}], extra: {}},
            errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> RParen <-- but found --> '\n' <--", position: {offset: [30, 30], line: [2, 2], column: [25, 25]}}]
        })
        expect(parseLegacyAml('posts\n  author int -> users(id)\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ["author"], ref: ["id"]}], extra: {statement: 1}}], extra: {}},
        })
    })
    test('attribute relation legacy', () => {
        expect(parseLegacyAml('posts\n  author int\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}}
        })
        expect(parseLegacyAml('posts\n  author int f\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}, {name: 'f', extra: {statement: 2}}], extra: {}},
            errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> NewLine <-- but found --> 'f' <--", position: {offset: [19, 19], line: [2, 2], column: [14, 14]}}]
        })
        expect(parseLegacyAml('posts\n  author int fk\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", position: {offset: [21, 21], line: [2, 2], column: [16, 16]}}],
            warnings: [{name: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", position: {offset: [19, 20], line: [2, 2], column: [14, 15]}}]
        })
        expect(parseLegacyAml('posts\n  author int fk users\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            // TODO: an error should be reported here
            warnings: [{name: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", position: {offset: [19, 20], line: [2, 2], column: [14, 15]}}]
        })
        expect(parseLegacyAml('posts\n  author int fk users.\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], extra: {}},
            errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Identifier <-- but found --> '\n' <--", position: {offset: [28, 28], line: [2, 2], column: [23, 23]}}],
            warnings: [{name: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", position: {offset: [19, 20], line: [2, 2], column: [14, 15]}}]
        })
        expect(parseLegacyAml('posts\n  author int fk users.id\n')).toEqual({
            result: {entities: [{name: 'posts', attrs: [{name: 'author', type: 'int'}], extra: {statement: 1}}], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}], extra: {statement: 1}}], extra: {}},
            warnings: [{name: 'warning', message: "\"fk\" is legacy, replace it with \"->\"", position: {offset: [19, 20], line: [2, 2], column: [14, 15]}}]
        })
    })
})

function parseLegacyAml(aml: string): ParserResult<Database> {
    // remove db extra fields not relevant
    try {
        return parseAml(aml).map(({extra: {source, parsedAt, parsingMs, formattingMs, ...extra} = {}, ...db}) => ({...db, extra}))
    } catch (e) {
        console.error(e) // print stack trace
        throw e
    }
}

/*function printJson(json: any): string {
    return JSON.stringify(json)
        .replaceAll(/"([^" ]+)":/g, '$1:')
        .replaceAll(/:"([^" ]+)"/g, ":'$1'")
        .replaceAll(/\n/g, '\\n')
        .replaceAll(/,message:'([^"]*?)',position:/g, ',message:"$1",position:')
}*/
