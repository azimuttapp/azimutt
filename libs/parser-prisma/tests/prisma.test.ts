import {describe, expect, test} from "@jest/globals";
import * as fs from "fs";
import {deeplyRemoveFields, formatSchema, parseSchema} from "../src/prisma";

describe('prisma', () => {
    test('parse a basic schema', async () => {
        const prismaSchema: string = `
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
}`
        const parsedSchema = await parseSchema(prismaSchema)
        const azimuttSchema = formatSchema(parsedSchema)
        expect(azimuttSchema).toEqual({
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
        })
    })
    test('parse a prisma schema', async () => {
        const parsed = await parseSchema(`
/// User 1
/// User 2
model User {
  /// User.id 1
  /// User.id 2
  id    Int     @id @default(autoincrement()) /// User.id 3
  email String  @unique
  name  String?
  role  Role    @default(USER)
  posts Post[]
}
model Post {
  id       Int  @id @default(autoincrement())
  author   User @relation(fields: [authorId], references: [id])
  authorId Int
}
enum Role {
  USER
  ADMIN
}`)
        fs.writeFileSync('tests/resources/example.prisma.json', JSON.stringify(deeplyRemoveFields(parsed, ['location']), null, 2))
        expect(formatSchema(parsed)).toEqual({
            tables: [{
                schema: '',
                table: 'User',
                columns: [
                    {name: 'id', type: 'Int', default: 'autoincrement()', comment: 'User.id 1\nUser.id 2\nUser.id 3'},
                    {name: 'email', type: 'String'},
                    {name: 'name', type: 'String', nullable: true},
                    {name: 'role', type: 'Role', default: 'USER'},
                    {name: 'posts', type: 'Post[]'},
                ],
                primaryKey: {columns: ['id']},
                uniques: [{columns: ['email']}],
                comment: 'User 1\nUser 2'
            }, {
                schema: '',
                table: 'Post',
                columns: [
                    {name: 'id', type: 'Int', default: 'autoincrement()'},
                    {name: 'author', type: 'User'},
                    {name: 'authorId', type: 'Int'},
                ],
                primaryKey: {columns: ['id']}
            }],
            relations: [{
                name: 'fk_Post_authorId_User_id',
                src: {schema: '', table: 'Post', column: 'authorId'},
                ref: {schema: '', table: 'User', column: 'id'}
            }],
            types: [{schema: '', name: 'Role', values: ['USER', 'ADMIN']}]
        })
    })
    test('handles errors', async () => {
        await expect(parseSchema(`model User`)).rejects.toEqual('Expected "{", [0-9a-z_\\-], or horizontal whitespace but end of input found.')
    })

    test.skip('debug', async () => {
        const prismaSchema = fs.readFileSync('tests/resources/schema.prisma', {encoding: 'utf8', flag: 'r'})
        // console.log('prismaSchema', prismaSchema)
        const prismaAst = await parseSchema(prismaSchema)
        fs.writeFileSync('tests/resources/schema.prisma.json', JSON.stringify(prismaAst, null, 2))
        // console.log('prismaAst', prismaAst)
        const azimuttSchema = formatSchema(prismaAst)
        fs.writeFileSync('tests/resources/schema.azimutt.json', JSON.stringify(azimuttSchema, null, 2))
        console.log('azimuttSchema', azimuttSchema)
    })
})
