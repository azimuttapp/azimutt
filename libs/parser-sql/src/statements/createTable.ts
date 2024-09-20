import {z} from "zod";

// https://www.postgresql.org/docs/current/sql-createtable.html

export const CreateTable = z.object({
    command: z.literal('CREATE TABLE'),
    language: z.literal('DDL'),
    operation: z.literal('schema'),
}).strict()
export type CreateTable = z.infer<typeof CreateTable>
