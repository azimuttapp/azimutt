import {describe, expect, test} from "@jest/globals";
// import * as fs from "fs";
// import {deeplyRemoveFields} from "@azimutt/utils";
import {AzimuttSchema} from "@azimutt/database-types";
import {formatSchema, parseSchema} from "../src/prisma";

// https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference
describe('prisma', () => {
    test('parse a basic schema', async () => {
        const ast = await parseSchema(`
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
        const azimuttSchema: AzimuttSchema = {
            tables: [
                {
                    schema: "",
                    table: "User",
                    columns: [
                        {name: "id", type: "Int", default: "autoincrement()"},
                        {name: "email", type: "String"},
                        {name: "name", type: "String", nullable: true},
                        {name: "posts", type: "Post[]"}
                    ],
                    primaryKey: {columns: ["id"]},
                    uniques: [{columns: ["email"]}]
                },
                {
                    schema: "",
                    table: "Post",
                    columns: [
                        {name: "id", type: "Int", default: "autoincrement()"},
                        {name: "createdAt", type: "DateTime", default: "now()"},
                        {name: "updatedAt", type: "DateTime"},
                        {name: "title", type: "String"},
                        {name: "content", type: "String", nullable: true},
                        {name: "published", type: "Boolean", default: "false"},
                        {name: "viewCount", type: "Int", default: "0"},
                        {name: "author", type: "User", nullable: true},
                        {name: "authorId", type: "Int", nullable: true}
                    ],
                    primaryKey: {columns: ["id"]}
                }
            ],
            relations: [
                {
                    name: "fk_Post_authorId_User_id",
                    src: {schema: "", table: "Post", column: "authorId"},
                    ref: {schema: "", table: "User", column: "id"}
                }
            ],
            types: []
        }
        // fs.writeFileSync('tests/ast.prisma.json', JSON.stringify(deeplyRemoveFields(ast, ['location']), null, 2))
        expect(formatSchema(ast)).toEqual(azimuttSchema)
    })
    test('parse a complex schema', async () => {
        const ast = await parseSchema(`
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
        const azimuttSchema: AzimuttSchema = {
            tables: [{
                schema: 'auth',
                table: 'users',
                columns: [
                    {name: 'id', type: 'Int', default: 'autoincrement()', comment: 'User.id 1\nUser.id 2\nUser.id 3'},
                    {name: 'email', type: 'VarChar(128)'},
                    {name: 'first_name', type: 'String', nullable: true},
                    {name: 'last_name', type: 'String', nullable: true},
                    {name: 'role', type: 'Role', default: 'USER'},
                    {name: 'posts', type: 'Post[]'},
                ],
                primaryKey: {columns: ['id']},
                uniques: [{columns: ['email']}, {name: 'uq_userName', columns: ['first_name', 'last_name']}],
                comment: 'User 1\nUser 2'
            }, {
                schema: '',
                table: 'Post',
                columns: [
                    {name: 'category', type: 'String'},
                    {name: 'title', type: 'String'},
                    {name: 'banner', type: 'Photo'},
                    {name: 'author', type: 'User'},
                    {name: 'authorId', type: 'Int'},
                ],
                primaryKey: {columns: ['category', 'title']},
                indexes: [{columns: ['title', 'author']}]
            }],
            relations: [{
                name: 'fk_Post_authorId_User_id',
                src: {schema: '', table: 'Post', column: 'authorId'},
                ref: {schema: '', table: 'User', column: 'id'}
            }],
            types: [
                {schema: '', name: 'Role', values: ['USER', 'ADMIN']},
                {schema: '', name: 'Photo', definition: '{height: Int, width: Int, url: String}'}
            ]
        }
        // fs.writeFileSync('tests/ast.prisma.json', JSON.stringify(deeplyRemoveFields(ast, ['location']), null, 2))
        expect(formatSchema(ast)).toEqual(azimuttSchema)
    })
    test('keep relations with @map', async () => {
        const ast = await parseSchema(`
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
        const azimuttSchema: AzimuttSchema = {
            tables: [{
                schema: 'public',
                table: 'users',
                columns: [{name: '_id', type: 'Int'}, {name: 'posts', type: 'Post[]'}],
                primaryKey: {columns: ['id']}
            }, {
                schema: 'public',
                table: 'posts',
                columns: [{name: 'id', type: 'Int'}, {name: 'author', type: 'User'}, {name: 'author_id', type: 'Int'}],
                primaryKey: {columns: ['id']}
            }],
            relations: [{
                name: 'fk_posts_author_id_users__id',
                src: {schema: 'public', table: 'posts', column: 'author_id'},
                ref: {schema: 'public', table: 'users', column: '_id'}
            }],
            types: []
        }
        // fs.writeFileSync('tests/ast.prisma.json', JSON.stringify(deeplyRemoveFields(ast, ['location']), null, 2))
        expect(formatSchema(ast)).toEqual(azimuttSchema)
    })
    test('handles errors', async () => {
        await expect(parseSchema(`model User`)).rejects.toEqual('Expected "{", [0-9a-z_\\-], or horizontal whitespace but end of input found.')
    })
})
