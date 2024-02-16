import {z} from "zod";

// https://www.postgresql.org/docs/current/sql-update.html

export const Update = z.object({
    command: z.literal('UPDATE'),
    language: z.literal('DML'),
    operation: z.literal('write'),
}).strict()
export type Update = z.infer<typeof Update>
