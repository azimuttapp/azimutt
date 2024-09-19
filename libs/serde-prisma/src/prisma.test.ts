import {describe, expect, test} from "@jest/globals";
import {Database, tokenPosition} from "@azimutt/models";
import {generate, parse} from "./prisma";

describe('prisma', () => {
    test('empty schema',  () => {
        expect(parse('').result).toEqual({extra: {source: 'Prisma parser'}})
        expect(generate({})).toEqual('Not implemented')
    })
    test('basic schema', () => {
        const parsed = parse(`
// This is your Prisma schema file from https://github.com/prisma/prisma-examples/blob/latest/typescript/remix/prisma/schema.prisma
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  title     String
  content   String?
  published Boolean  @default(false)
  viewCount Int      @default(0)
  author    User?    @relation(fields: [authorId], references: [id])
  authorId  Int?
}`)
        const expected: Database = {
            entities: [{
                name: 'User',
                attrs: [
                    {name: 'id', type: 'Int', default: 'autoincrement()'},
                    {name: 'email', type: 'String'},
                    {name: 'name', type: 'String', null: true},
                    {name: 'posts', type: 'Post[]'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['email']], unique: true}]
            }, {
                name: 'Post',
                attrs: [
                    {name: 'id', type: 'Int', default: 'autoincrement()'},
                    {name: 'createdAt', type: 'DateTime', default: 'now()'},
                    {name: 'updatedAt', type: 'DateTime'},
                    {name: 'title', type: 'String'},
                    {name: 'content', type: 'String', null: true},
                    {name: 'published', type: 'Boolean', default: 'false'},
                    {name: 'viewCount', type: 'Int', default: '0'},
                    {name: 'author', type: 'User', null: true},
                    {name: 'authorId', type: 'Int', null: true},
                ],
                pk: {attrs: [['id']]},
            }],
            relations: [{
                name: 'fk_Post_authorId_User_id',
                src: {entity: 'Post'},
                ref: {entity: 'User'},
                attrs: [{src: ['authorId'], ref: ['id']}]
            }],
            extra: {source: 'Prisma parser'},
        }
        expect(parsed.result).toEqual(expected)
    })
    test('complex schema', () => {
        const parsed = parse(`
/// User 1
/// User 2
model User {
  /// User.id 1
  /// User.id 2
  id         Int     @id @default(autoincrement()) /// User.id 3
  email      String  @unique @db.VarChar(128)
  firstName  String? @map("first_name")
  lastName   String? @map("last_name")
  role       Role    @default(USER)
  posts      Post[]
  @@map("users")
  @@schema("auth")
  @@unique(fields: [first_name, last_name], name: "uq_userName")
}
model Post {
  category String
  title    String
  banner   Photo
  author   User   @relation(fields: [authorId], references: [id])
  authorId Int
  @@id([category, title])
  @@index([title, author])
}
enum Role {
  USER
  ADMIN
}
type Photo {
  height Int
  width  Int
  url    String
}`)
        const expected: Database = {
            entities: [{
                schema: 'auth',
                name: 'users',
                attrs: [
                    {name: 'id', type: 'Int', default: 'autoincrement()', doc: 'User.id 1\nUser.id 2\nUser.id 3'},
                    {name: 'email', type: 'VarChar(128)'},
                    {name: 'first_name', type: 'String', null: true},
                    {name: 'last_name', type: 'String', null: true},
                    {name: 'role', type: 'Role', default: 'USER'},
                    {name: 'posts', type: 'Post[]'},
                ],
                pk: {attrs: [['id']]},
                indexes: [{attrs: [['email']], unique: true}, {name: 'uq_userName', attrs: [['first_name'], ['last_name']], unique: true}],
                doc: 'User 1\nUser 2'
            }, {
                name: 'Post',
                attrs: [
                    {name: 'category', type: 'String'},
                    {name: 'title', type: 'String'},
                    {name: 'banner', type: 'Photo'},
                    {name: 'author', type: 'User'},
                    {name: 'authorId', type: 'Int'},
                ],
                pk: {attrs: [['category'], ['title']]},
                indexes: [{attrs: [['title'], ['author']]}]
            }],
            relations: [{
                name: 'fk_Post_authorId_users_id',
                src: {entity: 'Post'},
                ref: {schema: 'auth', entity: 'users'},
                attrs: [{src: ['authorId'], ref: ['id']}]
            }],
            types: [
                {name: 'Role', values: ['USER', 'ADMIN']},
                {name: 'Photo', attrs: [
                    {name: 'height', type: 'Int'},
                    {name: 'width', type: 'Int'},
                    {name: 'url', type: 'String'},
                ]}
            ],
            extra: {source: 'Prisma parser'}
        }
        expect(parsed.result).toEqual(expected)
    })
    test('keep relations with @map', () => {
        const parsed = parse(`
model User {
  id    Int    @id @map("_id")
  posts Post[]
  @@schema("public")
  @@map("users")
}

model Post {
  id       Int  @id
  author   User @relation(fields: [authorId], references: [id])
  authorId Int  @map("author_id")
  @@schema("public")
  @@map("posts")
}`)
        const expected: Database = {
            entities: [{
                schema: 'public',
                name: 'users',
                attrs: [{name: '_id', type: 'Int'}, {name: 'posts', type: 'Post[]'}],
                pk: {attrs: [['id']]}
            }, {
                schema: 'public',
                name: 'posts',
                attrs: [{name: 'id', type: 'Int'}, {name: 'author', type: 'User'}, {name: 'author_id', type: 'Int'}],
                pk: {attrs: [['id']]}
            }],
            relations: [{
                name: 'fk_posts_author_id_users__id',
                src: {schema: 'public', entity: 'posts'},
                ref: {schema: 'public', entity: 'users'},
                attrs: [{src: ['author_id'], ref: ['_id']}]
            }],
            extra: {source: 'Prisma parser'}
        }
        expect(parsed.result).toEqual(expected)
    })
    test('handles errors', () => {
        expect(parse(`model User`).errors).toEqual([{name: 'PrismaParserError', kind: 'error', message: 'Expected "{", [0-9a-z_\\-], or horizontal whitespace but end of input found.', ...tokenPosition(0, 0, 0, 0, 0, 0)}])
    })
})
