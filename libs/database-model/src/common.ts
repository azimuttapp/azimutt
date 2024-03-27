import {z} from "zod";

export const Uuid = z.string().uuid()
export type Uuid = z.infer<typeof Uuid>
export const Markdown = z.string()
export type Markdown = z.infer<typeof Markdown>
export const Millis = z.number() // milli-seconds
export type Millis = z.infer<typeof Millis>
export const SqlScript = z.string() // a whole SQL script with several queries inside
export type SqlScript = z.infer<typeof SqlScript>
export const SqlStatement = z.string() // a single and complete SQL statement
export type SqlStatement = z.infer<typeof SqlStatement>
export const SqlFragment = z.string() // a part of SQL, can be used to build a bigger query
export type SqlFragment = z.infer<typeof SqlFragment>
