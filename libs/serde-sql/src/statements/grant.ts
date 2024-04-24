import {z} from "zod";

// https://www.postgresql.org/docs/current/sql-grant.html

export const Grant = z.object({
    command: z.literal('GRANT'),
    language: z.literal('DCL'),
    operation: z.literal('rights'),
}).strict()
export type Grant = z.infer<typeof Grant>
