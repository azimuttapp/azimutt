import {describe, expect, test} from "@jest/globals";
import {removeFieldsDeep} from "@azimutt/utils";
import {TokenPosition} from "@azimutt/models";
import {
    AmlAst,
    AttributeToken,
    collectTokenPositions,
    EntityToken,
    findTokenAt,
    IdentifierAst,
    isInside,
    SchemaToken
} from "./amlAst";
import {parseAmlAst} from "./amlParser";

const aml = `# AML
type user_role (admin, guest)

users as u {color: blue} # line 4
  id bigint pk {autoIncrement}
  name varchar index=users_name_idx
  email varchar unique=users_email_uniq
  role user_role

type cms.post_status (draft, published, archived)

cms.posts # line 12
  id uuid pk
  status post_status
  title varchar check(\`length(title) > 10\`)=posts_title_chk
  content text | allow markdown
  tags "varchar[]"
  created_at timestamp=\`now()\`
  created_by -> users(id)

cms.comments # line 21
  id uuid pk
  post_id int -> cms.posts(id)
  content text

lake.ax.raw.events # line 26
  id uuid pk
  name varchar
  item_kind event_item(users, posts, comments) nullable
  item_id int nullable
  payload json nullable
    user_id int -> users(id)
    post_id uuid

rel lake.ax.raw.events(item_id) -item_kind=users> users(id) # line 35
rel lake.ax.raw.events(item_id) -item_kind=posts> cms.posts(id)
rel lake.ax.raw.events(item_id) -item_kind=comments> cms.comments(id)
rel lake.ax.raw.events(payload.post_id) -> cms.posts(id)

lake.ax.raw.comments # line 40
  id uuid pk
  content text
`
const ast: AmlAst = parseAmlAst(aml, {strict: false}).result || {statements: []}

describe('amlAst', () => {
    describe('findTokenAt', () => {
        test('not found', () => {
            expect(findTokenAt(ast, {line: 0, column: 0})).toEqual(undefined) // before start
            expect(findTokenAt(ast, {line: 50, column: 50})).toEqual(undefined) // after end
            expect(findTokenAt(ast, {line: 4, column: 50})).toEqual(undefined) // after line end
        })
        test('found', () => {
            // schemas
            expect(cleanToken(findTokenAt(ast, {line: 12, column: 2}))).toEqual(cleanToken(schema('cms', 12, 1)))
            // entities
            expect(cleanToken(findTokenAt(ast, {line: 4, column: 1}))).toEqual(cleanToken(entity('users', 4, 1))) // on definition
            expect(cleanToken(findTokenAt(ast, {line: 12, column: 6}))).toEqual(cleanToken(entity('posts', 12, 5, [1, 'cms']))) // on definition with schema
            expect(cleanToken(findTokenAt(ast, {line: 23, column: 23}))).toEqual(cleanToken(entity('posts', 23, 22, [18, 'cms']))) // on attribute relation
            expect(cleanToken(findTokenAt(ast, {line: 35, column: 52}))).toEqual(cleanToken(entity('users', 35, 51))) // on standalone relation
            expect(cleanToken(findTokenAt(ast, {line: 40, column: 15}))).toEqual(cleanToken(entity('comments', 40, 13, [9, 'raw'], [6, 'ax'], [1, 'lake']))) // on definition with all scopes
            // attributes
            expect(cleanToken(findTokenAt(ast, {line: 5, column: 3}))).toEqual(cleanToken(attribute([['id', 5, 3]], 'users', 4, 1))) // on definition
            expect(cleanToken(findTokenAt(ast, {line: 32, column: 8}))).toEqual(cleanToken(attribute([['payload', 31, 3], ['user_id', 32, 5]], 'events', 26, 13, [9, 'raw'], [6, 'ax'], [1, 'lake']))) // on nested definition
            expect(cleanToken(findTokenAt(ast, {line: 38, column: 27}))).toEqual(cleanToken(attribute([['payload', 38, 24]], 'events', 38, 17, [13, 'raw'], [10, 'ax'], [5, 'lake']))) // on relation attribute
            expect(cleanToken(findTokenAt(ast, {line: 38, column: 35}))).toEqual(cleanToken(attribute([['payload', 38, 24], ['post_id', 38, 32]], 'events', 38, 17, [13, 'raw'], [10, 'ax'], [5, 'lake']))) // on relation attribute
        })
    })
    test('collectTokenPositions', () => {
        // entities
        expect(collectTokenPositions(ast, entity('users', 4, 1)).map(cleanPos)).toEqual([ // simple entity
            cleanPos(pos(4, 1, 5)),
            cleanPos(pos(19, 17, 5)),
            cleanPos(pos(32, 20, 5)),
            cleanPos(pos(35, 51, 5)),
        ])
        expect(collectTokenPositions(ast, entity('comments', 37, 13, [9, 'raw'], [6, 'ax'], [1, 'lake'])).map(cleanPos)).toEqual([ // entity in a specific scope
            cleanPos(pos(40, 13, 8)),
        ])
    })
    test('isInside', () => {
        expect(isInside({line: 3, column: 1}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(true) // strictly between lines
        expect(isInside({line: 3, column: 5}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(true) // strictly between lines with end of line
        expect(isInside({line: 1, column: 1}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(false) // before line
        expect(isInside({line: 5, column: 1}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(false) // after line
        expect(isInside({line: 2, column: 1}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(false) // first line before
        expect(isInside({line: 2, column: 5}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(true) // first line after
        expect(isInside({line: 4, column: 1}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(true) // last line before
        expect(isInside({line: 4, column: 5}, {start: {line: 2, column: 3}, end: {line: 4, column: 3}})).toEqual(false) // last line after
    })
})

function schema(name: string, line: number, column: number, catalog?: [number, string], database?: [number, string]): SchemaToken {
    return {kind: 'Schema', position: pos(line, column, name.length), schema: id(name, line, column), catalog: idOpt(line, catalog), database: idOpt(line, database)}
}
function entity(name: string, line: number, column: number, schema?: [number, string], catalog?: [number, string], database?: [number, string]): EntityToken {
    return {kind: 'Entity', position: pos(line, column, name.length), entity: id(name, line, column), schema: idOpt(line, schema), catalog: idOpt(line, catalog), database: idOpt(line, database)}
}
function attribute(path: [string, number, number][], name: string, line: number, column: number, schema?: [number, string], catalog?: [number, string], database?: [number, string]): AttributeToken {
    return {kind: 'Attribute', position: pos(line, column, name.length), path: path.map(([n, l, c]) => id(n, l, c)), entity: id(name, line, column), schema: idOpt(line, schema), catalog: idOpt(line, catalog), database: idOpt(line, database)}
}
function idOpt(line: number, value?: [number, string]): IdentifierAst | undefined {
    return value ? id(value[1], line, value[0]) : undefined
}
function id(value: string, line: number, column: number): IdentifierAst {
    return {kind: 'Identifier', value, token: pos(line, column, value.length)}
}
function pos(line: number, column: number, length: number): TokenPosition {
    return {offset: {start: 0, end: 0}, position: {start: {line, column}, end: {line, column: column + length - 1}}}
}
function cleanToken(token: any): any {
    if (token) {
        const {position, ...rest} = token
        return removeFieldsDeep(rest, ['offset'])
    } else {
        return undefined
    }
}
function cleanPos(pos: any): any {
    if (pos) {
        return removeFieldsDeep(pos, ['offset'])
    } else {
        return undefined
    }
}
