import {z} from "zod";

// https://www.postgresql.org/docs/current/sql-rollback.html

export const Rollback = z.object({
    command: z.literal('ROLLBACK'),
    language: z.literal('TCL'),
    operation: z.literal('transaction'),
}).strict()
export type Rollback = z.infer<typeof Rollback>
